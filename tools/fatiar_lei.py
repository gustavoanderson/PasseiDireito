#!/usr/bin/env python3
"""
Corta uma lei do Planalto em artigos, para a base de consulta da IA.

Regras que existem por causa de defeitos reais:
- O Planalto mostra a redação ANTIGA riscada (<strike>) ao lado da nova. Sem
  descartar o riscado, o art. 23 da Lei 8.429/1992 saía duas vezes, com o prazo
  antigo e o novo, e a IA leria os dois como vigentes.
- Uma lei que altera outra transcreve artigos da outra entre aspas ("Art. 337-E
  ..."). Esses não são artigos desta lei: só conta "Art." no início do parágrafo,
  sem aspas antes.
- "Vide ADI/ADC/ADPF" marca dispositivo mexido pelo STF. A IA precisa saber.

Uso como biblioteca: fatiar(html) -> lista de artigos.
"""

import html as html_lib
import re

# Planalto risca com <strike>; o Legisladoc de Curitiba, com <s>. "<s\b" não pega <span>/<strong>.
_RISCADO = re.compile(r"(?is)<(strike|s|del)\b[^>]*>.*?</\1\s*>")
_SCRIPT = re.compile(r"(?is)<(script|style)\b.*?</\1>")
_QUEBRA = re.compile(r"(?i)<br\s*/?>|</p>|</h\d>|</div>|</tr>")
_TAG = re.compile(r"<[^>]+>")

# Início de artigo: "Art. 23.", "Art. 5º", "Art. 23-A.", "Art. 1o", "Art. 208-J.",
# e "Art. 8º-A", em que a letra vem DEPOIS do ordinal.
# O sufixo de letra vem COLADO ("8º-A", "23-A"); com espaço antes do traço é o
# separador da CLT ("Art. 1º - Esta Consolidação"), que antes virava "1-E".
_ARTIGO = re.compile(r"^Art\.\s*(\d+(?:\.\d+)?(?: \d+(?=\s*\.))?)(?:º|°|o)?(-[A-Z]{1,3}\b)?\s*\.?\s*[-–]?\s*")
_TITULO_SECAO = re.compile(r"^(TÍTULO|CAPÍTULO|Seção|SEÇÃO|Subseção|LIVRO|PARTE)\b")
_ADCT = re.compile(r"^ATO DAS DISPOSIÇÕES (CONSTITUCIONAIS )?TRANSITÓRIAS")
_NOTA = re.compile(
    r"\(((?:Redação dada|Incluíd[oa]|Acrescid[oa]|Revogad[oa]|Vide|Renumerad[oa]|Regulamento|Vigência|Promulga|Produção de efeito|Declarad[oa])[^()]*(?:\([^()]*\)[^()]*)*)\)"
)
_VIDE_STF = re.compile(r"\b(ADI|ADIN|ADC|ADPF|ADO)\s*n?º?\s*([\d.]+)", re.IGNORECASE)
# Assinatura: "Brasília, 5 de outubro..." (federal) e "PALÁCIO 29 DE MARÇO, ..." (Curitiba).
_FIM = re.compile(r"^((Brasília|Rio de Janeiro),\s+\d|PAL[ÁA]CIO 29 DE MAR[ÇC]O)", re.IGNORECASE)


def decodificar(conteudo: bytes) -> str:
    try:
        return conteudo.decode("utf-8")
    except UnicodeDecodeError:
        return conteudo.decode("cp1252")


def paragrafos(html: str) -> list[str]:
    texto = _SCRIPT.sub("", html)
    texto = _RISCADO.sub("", texto)
    # O HTML do Planalto quebra linha no meio do parágrafo. Essas quebras não
    # significam nada: junta tudo antes de separar pelos parágrafos de verdade.
    texto = re.sub(r"\s+", " ", texto)
    texto = _QUEBRA.sub("\n", texto)
    texto = html_lib.unescape(_TAG.sub("", texto))
    linhas = [re.sub(r"\s+", " ", linha).strip() for linha in texto.split("\n")]
    return [linha for linha in linhas if linha]


def fatiar(html: str, comecar_em: str | None = None) -> list[dict]:
    """[comecar_em]: regex do parágrafo onde a norma de verdade começa. Existe
    para a CLT, que é um ANEXO depois da assinatura do Decreto-Lei 5.452/1943."""
    artigos: list[dict] = []
    atual = None
    local = ""
    prefixo = ""
    assinado = False
    esperando = comecar_em is not None
    for p in paragrafos(html):
        if esperando:
            esperando = not re.search(comecar_em, p)
            continue
        # Depois da assinatura vêm anexos e mensagens de veto, que não são
        # artigos da norma. A exceção é a CF: o ADCT vem depois da assinatura.
        m_adct = _ADCT.search(p)
        if m_adct:
            # CF: "ADCT"; Lei Orgânica de Curitiba: "ADT" (sem "Constitucionais").
            sigla = "ADCT" if m_adct.group(1) else "ADT"
            prefixo, local, assinado = f"{sigla}-", sigla, False
            continue
        if _FIM.match(p):
            assinado = True
        if assinado:
            continue
        if _TITULO_SECAO.match(p):
            local = p
            continue
        m = _ARTIGO.match(p)
        if m:
            letra = (m.group(2) or "").replace(" ", "")
            # "Art. 5 7." acontece quando a formatação parte o número (LGPD, art. 57).
            numero = m.group(1).replace(" ", "")
            atual = {"id": prefixo + numero + letra, "local": local, "paragrafos": [p]}
            artigos.append(atual)
        elif atual is not None:
            atual["paragrafos"].append(p)

    for a in artigos:
        a["texto"] = "\n".join(a.pop("paragrafos"))

    # O Planalto deixa SEM risco a redação de Medida Provisória que caducou,
    # marcada "Vigência encerrada". Havendo outra versão do mesmo artigo, a da
    # MP caducada sai. Duplicado que sobrar é marcado para conferência humana.
    contagem: dict[str, int] = {}
    for a in artigos:
        contagem[a["id"]] = contagem.get(a["id"], 0) + 1
    artigos = [
        a for a in artigos
        if not (contagem[a["id"]] > 1 and "Vigência encerrada" in a["texto"])
    ]
    # O Planalto nem sempre risca a redação antiga: às vezes deixa as versões
    # lado a lado, da mais antiga para a vigente. Fica a ÚLTIMA; as anteriores
    # são contadas em "versoesDescartadas" para conferência por amostragem.
    # Prova de que é a vigente: a nota "Redação dada"/"Incluído". Conferido em
    # 29/09/2026: sem ela, a "última" pode ser a antiga (Lei 8.212, art. 21).
    # Então fica a última COM essa nota; se nenhuma versão tiver, fica a última
    # e o artigo é marcado "conferir" para revisão humana.
    tem_nota_nova = lambda a: bool(re.search(r"Redação dada|Incluíd|Acrescid", a["texto"]))  # noqa: E731
    versoes: dict[str, list[dict]] = {}
    for a in artigos:
        versoes.setdefault(a["id"], []).append(a)
    escolhida: dict[str, dict] = {}
    for id_, vs in versoes.items():
        com_nota = [v for v in vs if tem_nota_nova(v)]
        escolhida[id_] = (com_nota or vs)[-1]
    artigos = [a for a in artigos if escolhida[a["id"]] is a]

    for a in artigos:
        texto = a["texto"]
        n_versoes = len(versoes[a["id"]])
        a["versoesDescartadas"] = n_versoes - 1
        # Versões de texto idêntico (a página repete o artigo) não geram dúvida.
        textos_distintos = {re.sub(r"\s+", " ", v["texto"]) for v in versoes[a["id"]]}
        a["conferir"] = len(textos_distintos) > 1 and not tem_nota_nova(a)
        a["duplicado"] = False
        notas = [n.strip() for n in _NOTA.findall(texto)]
        a["texto"] = texto
        a["notas"] = notas
        a["videStf"] = sorted({f"{t.upper().replace('ADIN', 'ADI')} {n.rstrip('.')}" for t, n in _VIDE_STF.findall(" ".join(notas))})
        cabeca = _NOTA.sub("", texto.split("\n")[0])
        a["revogado"] = bool(re.search(r"(?i)^Art\.[^.]*\.?\s*\(?\s*revogad", cabeca)) or bool(
            re.match(r"(?i)^Art\.\s*[\d\-A-Z.]+\s*(?:º|°|o)?\s*\.?\s*[-–]?\s*$", cabeca.strip())
            and any(n.lower().startswith("revogad") for n in notas)
        )
    return artigos
