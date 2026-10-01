#!/usr/bin/env python3
"""
Monta a base de consulta da IA: baixa cada norma de corpus/normas.json, corta
por artigo (tools/fatiar_lei.py) e grava corpus/federal/<id>.json.

Trava da data de corte: a norma é baixada HOJE e pode trazer alteração
posterior a 21/09/2026. Toda nota que cite norma de 2026 é conferida contra
corpus/normas_2026.json (norma -> data de publicação). Norma de 2026 que não
esteja lá, ou publicada depois do corte, aparece no relatório e reprova.

Uso:
    python tools/montar_corpus.py            # todas
    python tools/montar_corpus.py ctn l8429  # só estas
"""

import datetime
import json
import re
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from fatiar_lei import _NOTA, decodificar, fatiar  # noqa: E402

RAIZ = Path(__file__).parent.parent / "corpus"
DATA_DE_CORTE = "2026-09-21"
NAVEGADOR = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/153 Safari/537.36"

# "Lei Complementar nº 236, de 2026", "Emenda Constitucional nº 139, de 2026", "Lei nº 15.484, de 2026"
_NORMA_2026 = re.compile(
    r"(Lei Complementar|Lcp|Emenda Constitucional|Lei|Medida Provisória|Decreto)\s*n?º?\s*([\d.]+)\s*,?\s*de\s*2026"
)


def baixar(url: str) -> bytes:
    # O WebFetch e o urllib levam ECONNRESET do Planalto; o curl com cabeçalho de navegador passa.
    return subprocess.run(
        ["curl", "-sfL", "--retry", "2", "-A", NAVEGADOR, url],
        capture_output=True, check=True, timeout=180,
    ).stdout


def normas_de_2026(artigos: list[dict]) -> set[str]:
    achadas = set()
    for a in artigos:
        for nota in a["notas"]:
            for tipo, numero in _NORMA_2026.findall(re.sub(r"\s+", " ", nota)):
                tipo = "Lei Complementar" if tipo == "Lcp" else tipo
                achadas.add(f"{tipo} {numero.replace('.', '')}/2026")
    return achadas


def aplicar_corte(artigo: dict, posteriores: set[str]) -> str:
    """Tira do artigo o que norma POSTERIOR ao edital fez. Devolve:
    "intacto"   - nada a fazer;
    "aparado"   - só linhas INCLUÍDAS depois saíram (ex.: um § novo no art. 155 do CP);
    "removido"  - o próprio caput é novo: o artigo inteiro não existia em 21/09/2026;
    "alterado"  - alguma linha teve a REDAÇÃO trocada: precisa de correcoes.json.

    Lição de 01/10/2026: a primeira versão tirava o artigo inteiro quando a
    norma posterior só incluíra um parágrafo, e o furto (art. 155 do CP) e o
    roubo (art. 157) sumiram da base."""
    def cita_posterior(linha: str) -> bool:
        return bool(normas_de_2026([{"notas": _NOTA.findall(linha)}]) & posteriores)

    linhas = artigo["texto"].split("\n")
    if not any(cita_posterior(l) for l in linhas):
        return "intacto"
    if any(cita_posterior(l) and not re.search(r"(?i)\(Inclu[íi]d[oa]", l) for l in linhas):
        return "alterado"
    if cita_posterior(linhas[0]):
        return "removido"
    artigo["texto"] = "\n".join(l for l in linhas if not cita_posterior(l))
    artigo["notas"] = [nota.strip() for nota in _NOTA.findall(artigo["texto"])]
    return "aparado"


def main(ids: list[str]) -> int:
    lista = json.loads((RAIZ / "normas.json").read_text(encoding="utf-8"))["normas"]
    datas_2026 = json.loads((RAIZ / "normas_2026.json").read_text(encoding="utf-8"))
    correcoes = json.loads((RAIZ / "correcoes.json").read_text(encoding="utf-8"))
    if ids:
        lista = [n for n in lista if n["id"] in ids]

    saida = RAIZ / "federal"
    saida.mkdir(exist_ok=True)
    problemas = []
    avisos = []
    for n in lista:
        try:
            artigos = fatiar(decodificar(baixar(n["url"])), comecar_em=n.get("comecarEm"))
        except subprocess.CalledProcessError as e:
            problemas.append(f"{n['id']}: falha ao baixar ({e.returncode})")
            continue
        if len(artigos) < 3:
            problemas.append(f"{n['id']}: só {len(artigos)} artigo(s) — a página mudou ou a URL está errada")
            continue

        for norma in sorted(normas_de_2026(artigos)):
            if datas_2026.get(norma) is None:
                problemas.append(f"{n['id']}: cita {norma}, sem data em normas_2026.json — confira se é anterior a {DATA_DE_CORTE}")

        # Norma posterior ao corte não vale para a prova. Artigo que ela
        # INCLUIU sai da base; artigo que ela ALTEROU reprova, porque a redação
        # válida em 21/09/2026 está no texto riscado e precisa ser restaurada.
        posteriores = {k for k, v in datas_2026.items() if not k.startswith("_") and v > DATA_DE_CORTE}
        mantidos = []
        for a in artigos:
            citadas = normas_de_2026([a]) & posteriores
            efeito = aplicar_corte(a, posteriores)
            if efeito == "intacto":
                mantidos.append(a)
            elif efeito == "aparado":
                print(f"  {n['id']}: art. {a['id']} sem o trecho incluído por {', '.join(sorted(citadas))}, posterior ao corte")
                mantidos.append(a)
            elif efeito == "removido":
                print(f"  {n['id']}: art. {a['id']} fora da base (criado por {', '.join(sorted(citadas))}, posterior ao corte)")
            elif a["id"] in correcoes.get(n["id"], {}):
                c = correcoes[n["id"]][a["id"]]
                a.update(texto=c["texto"], notas=[f"Redação de 21/09/2026 restaurada: {c['motivo']}"], videStf=[])
                print(f"  {n['id']}: art. {a['id']} restaurado na redação de 21/09/2026 ({c['fonte']})")
                mantidos.append(a)
            else:
                problemas.append(f"{n['id']}: art. {a['id']} alterado por {', '.join(sorted(citadas))}, POSTERIOR ao corte — restaurar a redação de 21/09/2026 em corpus/correcoes.json")
                mantidos.append(a)
        artigos = mantidos

        conferir = [a["id"] for a in artigos if a["conferir"]]
        if conferir:
            avisos.append(f"{n['id']}: versões sem nota de redação, conferir no Planalto: arts. {', '.join(conferir)}")

        doc = {
            "id": n["id"],
            "titulo": n["titulo"],
            "url": n["url"],
            "baixadoEm": datetime.date.today().isoformat(),
            "artigos": artigos,
        }
        (saida / f"{n['id']}.json").write_text(json.dumps(doc, ensure_ascii=False, indent=1), encoding="utf-8")
        stf = sum(1 for a in artigos if a["videStf"])
        print(f"  {n['id']:9} {len(artigos):5} artigos  {stf:3} com Vide STF  ({n['titulo']})")

    for p in avisos:
        print(f"  [CONFERIR] {p}")
    for p in problemas:
        print(f"  [PROBLEMA] {p}")
    print(f"\n{len(lista)} norma(s), {len(problemas)} problema(s).")
    return 1 if problemas else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
