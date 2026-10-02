#!/usr/bin/env python3
"""
Monta a parte de Curitiba da base de lei: para cada norma de
corpus/normas_curitiba.json, busca no Legisladoc, baixa o texto vigente,
corta por artigo e grava corpus/curitiba/<id>.json.

Trava da data de corte: ato publicado depois de 21/09/2026 não entra.
Revogados entram marcados (a banca pode perguntar justamente a revogação).

Uso:
    python tools/montar_corpus_curitiba.py            # todas
    python tools/montar_corpus_curitiba.py lc-40-2001 # só estas
"""

import datetime
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from fatiar_lei import fatiar  # noqa: E402
from legisladoc import baixar_ato, buscar, corpo_vigente  # noqa: E402

RAIZ = Path(__file__).parent.parent / "corpus"
DATA_DE_CORTE = datetime.date(2026, 9, 21)


def data_br(texto: str) -> datetime.date | None:
    try:
        d, m, a = (int(x) for x in texto.split("/"))
        return datetime.date(a, m, d)
    except ValueError:
        return None


def aplicar_correcoes(artigos: list[dict], correcoes: dict) -> list[str]:
    """Põe a redação de 21/09/2026 onde o texto "Alterado" do Legisladoc ficou
    para trás. Lição de 01/10/2026: a LC 108/2017 (ITBI) aparecia sem as
    mudanças das LCs 134/2022 e 148/2025, com os arts. 13 e 14 revogados ainda
    "vigentes", e questões foram escritas sobre o texto velho. Devolve o que
    foi feito, para o relatório."""
    feitos = []
    por_id = {a["id"]: a for a in artigos}
    for id_, c in correcoes.items():
        a = por_id.get(id_)
        if a is None:
            if not c.get("novo"):
                feitos.append(f"art. {id_}: correção sem artigo correspondente — conferir")
                continue
            a = {"id": id_, "local": "", "versoesDescartadas": 0, "conferir": False, "duplicado": False, "videStf": []}
            depois = next((i for i, x in enumerate(artigos) if x["id"] == c.get("depoisDe")), len(artigos) - 1)
            artigos.insert(depois + 1, a)
            por_id[id_] = a
        a["texto"] = c["texto"]
        a["notas"] = [f"Redação de 21/09/2026 reconstruída: {c['motivo']} Fonte: {c['fonte']}"]
        a["revogado"] = bool(c.get("revogado"))
        a["conferir"] = False
        feitos.append(f"art. {id_}: {c['motivo']}")
    return feitos


def main(ids: list[str]) -> int:
    from playwright.sync_api import sync_playwright

    lista = json.loads((RAIZ / "normas_curitiba.json").read_text(encoding="utf-8"))["normas"]
    correcoes = json.loads((RAIZ / "correcoes_curitiba.json").read_text(encoding="utf-8"))
    if ids:
        lista = [n for n in lista if n["id"] in ids]
    saida = RAIZ / "curitiba"
    saida.mkdir(exist_ok=True)
    problemas = []

    with sync_playwright() as p:
        navegador = p.chromium.launch(channel="chrome", headless=True)
        page = navegador.new_page()
        for n in lista:
            if n.get("ignorar"):
                print(f"  {n['id']:16} fora da base: {n['ignorar']}")
                (saida / f"{n['id']}.json").unlink(missing_ok=True)
                continue
            try:
                achados = buscar(page, n["tipo"], n["numero"], n["ano"])
            except Exception as e:  # rede, página fora do ar
                problemas.append(f"{n['id']}: busca falhou ({e.__class__.__name__})")
                continue
            if not achados:
                problemas.append(f"{n['id']}: a busca não achou o ato — conferir à mão")
                continue
            # Mais de um resultado = o mesmo ato republicado (a republicação
            # corrige a original: o Decreto 1.292/2026 saiu com "implificados"
            # em 12/08 e foi republicado em 14/08). Fica a mais recente.
            ato = max(achados, key=lambda a: data_br(a["publicacao"]) or datetime.date.min)
            if len(achados) > 1:
                outras = ", ".join(a["publicacao"] for a in achados if a is not ato)
                print(f"  {n['id']}: {len(achados)} publicações; usada a de {ato['publicacao']} (outras: {outras})")
            publicado = data_br(ato["publicacao"])
            if publicado and publicado > DATA_DE_CORTE:
                problemas.append(f"{n['id']}: publicado em {ato['publicacao']}, depois do edital — fora da base")
                continue

            artigos = fatiar(corpo_vigente(baixar_ato(ato["id"])))
            if len(artigos) < 1:
                problemas.append(f"{n['id']}: nenhum artigo extraído do ato {ato['id']}")
                continue
            for feito in aplicar_correcoes(artigos, correcoes.get(n["id"], {})):
                print(f"  {n['id']}: {feito}")
            conferir = [a["id"] for a in artigos if a["conferir"]]
            if conferir:
                problemas.append(f"{n['id']}: versões sem nota de redação, conferir: arts. {', '.join(conferir)}")

            doc = {
                "id": n["id"],
                "titulo": n["titulo"],
                "legisladocId": ato["id"],
                "url": f"https://legisladocexterno.curitiba.pr.gov.br/VisualizarHTML.aspx?id={ato['id']}",
                "situacao": ato["situacao"],
                "publicacao": ato["publicacao"],
                "ementa": ato["sumula"],
                "baixadoEm": datetime.date.today().isoformat(),
                "artigos": artigos,
            }
            (saida / f"{n['id']}.json").write_text(json.dumps(doc, ensure_ascii=False, indent=1), encoding="utf-8")
            print(f"  {n['id']:16} {len(artigos):4} artigos  {ato['situacao'] or '?':9} pub. {ato['publicacao']}  ({n['titulo']})")
            print(f"  {'':16} ementa: {ato['sumula'][:150]}")
        navegador.close()

    for p_ in problemas:
        print(f"  [PROBLEMA] {p_}")
    print(f"\n{len(lista)} norma(s), {len(problemas)} problema(s).")
    return 1 if problemas else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
