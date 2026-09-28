#!/usr/bin/env python3
"""
Validador do banco de questoes do PasseiDireito.

Roda ANTES de qualquer questao entrar no app. Se ele reprovar, o build para.

Uso:
    python tools/validar_questoes.py app/assets/questoes/
    python tools/validar_questoes.py app/assets/questoes/adm/adm-04.json

Saida:
    codigo 0  -> banco aprovado
    codigo 1  -> banco reprovado, com a lista de defeitos
"""

import json
import re
import sys
from collections import Counter
from pathlib import Path

try:
    from jsonschema import Draft7Validator
except ImportError:
    sys.exit("Falta a biblioteca jsonschema. Instale com: pip install jsonschema")

ARQUIVO_ESQUEMA = Path(__file__).parent / "questao.schema.json"

# Tudo o que a prova pode cobrar e o que existia ate a publicacao do edital.
DATA_DE_CORTE = "2026-09-21"

# Quantos itens cada materia tem no Anexo II do Edital 6/2026. Em Urbanistico
# e Ambiental o edital pula do item 7 para o 9; o 14 continua sendo o ultimo.
ITENS_DO_EDITAL = {
    "adm": 17, "const": 12, "trib": 16, "pc": 15, "civ": 8,
    "urb": 14, "trab": 11, "prev": 7, "pen": 2, "emp": 5,
}

# Explicacao curta demais nao ensina nada. "Errada." nao e explicacao.
MINIMO_EXPLICACAO = 60

# Dica que diz "a alternativa B" entrega a resposta.
DICA_ENTREGA = re.compile(r"\b(alternativa|letra|op[çc][ãa]o|item)\s+[A-E]\b", re.IGNORECASE)

# Acima disso, a letra certa fica previsivel e a aluna aprende o banco, nao o Direito.
LIMITE_MESMA_LETRA = 0.35
MINIMO_PARA_MEDIR_LETRAS = 20


class Relatorio:
    """Acumula erros e avisos em vez de parar no primeiro.

    Parar no primeiro obrigaria a rodar o validador dezenas de vezes.
    Ver tudo de uma vez e o que torna a correcao viavel.
    """

    def __init__(self):
        self.erros = []
        self.avisos = []

    def erro(self, onde, mensagem):
        self.erros.append(f"  [ERRO]   {onde}: {mensagem}")

    def aviso(self, onde, mensagem):
        self.avisos.append(f"  [AVISO]  {onde}: {mensagem}")


def normalizar(texto):
    return re.sub(r"\s+", " ", texto).strip().lower()


def validar_arquivo(caminho, dados, esquema, relatorio, ids_vistos, enunciados_vistos, letras_por_materia):
    nome = caminho.name

    erros_esquema = sorted(Draft7Validator(esquema).iter_errors(dados), key=lambda e: list(e.path))
    for e in erros_esquema:
        onde = "/".join(str(p) for p in e.path) or "(raiz)"
        relatorio.erro(f"{nome} {onde}", e.message)
    if erros_esquema:
        # Com o formato quebrado, as regras abaixo dariam erros em cascata sem sentido.
        return

    materia = dados["materia"]
    unidade = dados["unidade"]

    if caminho.parent.name != materia:
        relatorio.erro(nome, f"esta na pasta '{caminho.parent.name}', mas declara a materia '{materia}'")
    if not unidade["id"].startswith(materia + "-"):
        relatorio.erro(nome, f"unidade '{unidade['id']}' nao comeca com '{materia}-'")
    if caminho.stem != unidade["id"]:
        relatorio.erro(nome, f"o arquivo deve se chamar '{unidade['id']}.json'")
    if unidade["itemEdital"] > ITENS_DO_EDITAL[materia]:
        relatorio.erro(nome, f"itemEdital {unidade['itemEdital']} nao existe: '{materia}' tem {ITENS_DO_EDITAL[materia]} itens no Anexo II")

    for q in dados["questoes"]:
        onde = f"{nome} {q['id']}"

        if not q["id"].startswith(materia + "-"):
            relatorio.erro(onde, f"id nao comeca com '{materia}-'")
        if q["id"] in ids_vistos:
            relatorio.erro(onde, f"id repetido (ja usado em {ids_vistos[q['id']]})")
        ids_vistos[q["id"]] = nome

        chave = normalizar(q["enunciado"]) + "|" + "|".join(normalizar(q["alternativas"][l]) for l in "ABCDE")
        if chave in enunciados_vistos:
            relatorio.erro(onde, f"questao identica a {enunciados_vistos[chave]}")
        enunciados_vistos[chave] = q["id"]

        textos = [normalizar(q["alternativas"][l]) for l in "ABCDE"]
        repetidas = [t for t, n in Counter(textos).items() if n > 1]
        if repetidas:
            relatorio.erro(onde, "duas alternativas com o mesmo texto")

        for letra in "ABCDE":
            explicacao = q["explicacao"][letra].strip()
            if len(explicacao) < MINIMO_EXPLICACAO:
                papel = "a correta" if letra == q["correta"] else "uma errada"
                relatorio.erro(onde, f"explicacao da {letra} ({papel}) tem {len(explicacao)} caracteres; minimo {MINIMO_EXPLICACAO}")

        if DICA_ENTREGA.search(q["dica"]):
            relatorio.erro(onde, "a dica cita uma letra de alternativa e entrega a resposta")

        for fonte in q["fontes"]:
            if fonte["data"] > DATA_DE_CORTE:
                relatorio.erro(onde, f"fonte '{fonte['referencia']}' e de {fonte['data']}, depois da data de corte {DATA_DE_CORTE}")

        if q["origem"]["tipo"] == "adaptada" and "prova" not in q["origem"]:
            relatorio.erro(onde, "questao adaptada precisa dizer de qual prova veio")

        letras_por_materia.setdefault(materia, Counter())[q["correta"]] += 1


def validar(caminhos):
    esquema = json.loads(ARQUIVO_ESQUEMA.read_text(encoding="utf-8"))
    relatorio = Relatorio()
    ids_vistos, enunciados_vistos, letras_por_materia = {}, {}, {}

    arquivos = []
    for c in caminhos:
        c = Path(c)
        arquivos.extend(sorted(c.rglob("*.json")) if c.is_dir() else [c])

    if not arquivos:
        relatorio.erro("(banco)", "nenhum arquivo .json encontrado")

    for arquivo in arquivos:
        try:
            dados = json.loads(arquivo.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            relatorio.erro(arquivo.name, f"JSON invalido: {e}")
            continue
        validar_arquivo(arquivo, dados, esquema, relatorio, ids_vistos, enunciados_vistos, letras_por_materia)

    for materia, letras in letras_por_materia.items():
        total = sum(letras.values())
        if total < MINIMO_PARA_MEDIR_LETRAS:
            continue
        letra, n = letras.most_common(1)[0]
        if n / total > LIMITE_MESMA_LETRA:
            relatorio.aviso(materia, f"{n} de {total} questoes tem gabarito {letra}; o gabarito ficou previsivel")

    return relatorio, len(ids_vistos)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 1
    relatorio, total = validar(argv[1:])
    for linha in relatorio.erros + relatorio.avisos:
        print(linha)
    if relatorio.erros:
        print(f"\nBanco REPROVADO: {len(relatorio.erros)} erro(s), {len(relatorio.avisos)} aviso(s).")
        return 1
    print(f"Banco aprovado: {total} questao(oes), {len(relatorio.avisos)} aviso(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
