#!/usr/bin/env python3
"""
Validador das provas reais anteriores (app/assets/provas/).

Cada arquivo reproduz uma prova real ja aplicada pela FAFIPA, na ordem e
numeracao originais, para a Flavia poder refaze-la exatamente como caiu ou
montar um simulado personalizado misturando provas (pedido dela, 20/10/2026).
Por isso tem regras diferentes do banco de trilha (tools/validar_questoes.py):
aqui NAO ha limite de itemEdital, e a data de corte de cada questao e a data
de APLICACAO daquela prova, nao a publicacao do edital atual (21/09/2026) --
cada prova e um retrato de uma epoca.

Uso:
    python tools/validar_provas.py app/assets/provas/
    python tools/validar_provas.py app/assets/provas/matinhos-2026.json

Saida:
    codigo 0 -> provas aprovadas
    codigo 1 -> provas reprovadas, com a lista de defeitos
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

ARQUIVO_ESQUEMA = Path(__file__).parent / "prova.schema.json"

MINIMO_EXPLICACAO = 60
DICA_ENTREGA = re.compile(r"\b(alternativa|letra|op[çc][ãa]o|item)\s+[A-E]\b", re.IGNORECASE)
LIMITE_MESMA_LETRA = 0.35
MINIMO_PARA_MEDIR_LETRAS = 20


class Relatorio:
    def __init__(self):
        self.erros = []
        self.avisos = []

    def erro(self, onde, mensagem):
        self.erros.append(f"  [ERRO]   {onde}: {mensagem}")

    def aviso(self, onde, mensagem):
        self.avisos.append(f"  [AVISO]  {onde}: {mensagem}")


def normalizar(texto):
    return re.sub(r"\s+", " ", texto).strip().lower()


def validar_arquivo(caminho, dados, esquema, relatorio, ids_vistos, enunciados_vistos):
    nome = caminho.name

    erros_esquema = sorted(Draft7Validator(esquema).iter_errors(dados), key=lambda e: list(e.path))
    for e in erros_esquema:
        onde = "/".join(str(p) for p in e.path) or "(raiz)"
        relatorio.erro(f"{nome} {onde}", e.message)
    if erros_esquema:
        return None

    prova = dados["prova"]
    if caminho.stem != prova["id"]:
        relatorio.erro(nome, f"o arquivo deve se chamar '{prova['id']}.json'")

    data_de_corte = prova["dataAplicacao"]
    numeros_vistos = set()
    letras = Counter()

    for q in dados["questoes"]:
        onde = f"{nome} {q['id']}"

        if not q["id"].startswith(prova["id"] + "-"):
            relatorio.erro(onde, f"id nao comeca com '{prova['id']}-'")
        if q["id"] in ids_vistos:
            relatorio.erro(onde, f"id repetido (ja usado em {ids_vistos[q['id']]})")
        ids_vistos[q["id"]] = nome

        if q["numeroOriginal"] in numeros_vistos:
            relatorio.erro(onde, f"numeroOriginal {q['numeroOriginal']} repetido nesta prova")
        numeros_vistos.add(q["numeroOriginal"])

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
            if fonte["data"] > data_de_corte:
                relatorio.erro(onde, f"fonte '{fonte['referencia']}' e de {fonte['data']}, depois da aplicacao da prova ({data_de_corte})")

        letras[q["correta"]] += 1

    # Numeracao original deve vir em ordem crescente no arquivo, para a tela
    # exibir a prova na sequencia que a aluna viu no papel.
    ordem = [q["numeroOriginal"] for q in dados["questoes"]]
    if ordem != sorted(ordem):
        relatorio.erro(nome, "as questoes nao estao em ordem crescente de numeroOriginal")

    return letras


def validar(caminhos):
    esquema = json.loads(ARQUIVO_ESQUEMA.read_text(encoding="utf-8"))
    relatorio = Relatorio()
    ids_vistos, enunciados_vistos, provas_vistas = {}, {}, {}
    letras_totais = Counter()

    arquivos = []
    for c in caminhos:
        c = Path(c)
        if c.is_dir():
            arquivos.extend(sorted(c.rglob("*.json")))
        elif c.exists():
            arquivos.append(c)
        # Pasta ainda nao criada (nenhuma prova real digitalizada ainda): conta
        # como zero arquivos, nao como erro de caminho invalido.

    if not arquivos:
        relatorio.erro("(provas)", "nenhum arquivo .json encontrado")

    for arquivo in arquivos:
        try:
            dados = json.loads(arquivo.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            relatorio.erro(arquivo.name, f"JSON invalido: {e}")
            continue
        letras = validar_arquivo(arquivo, dados, esquema, relatorio, ids_vistos, enunciados_vistos)
        if letras:
            provas_vistas[arquivo.name] = sum(letras.values())
            letras_totais.update(letras)

    if letras_totais:
        total = sum(letras_totais.values())
        if total >= MINIMO_PARA_MEDIR_LETRAS:
            letra, n = letras_totais.most_common(1)[0]
            if n / total > LIMITE_MESMA_LETRA:
                relatorio.aviso("(todas as provas)", f"{n} de {total} questoes tem gabarito {letra}; o gabarito ficou previsivel")

    return relatorio, len(ids_vistos), len(provas_vistas)


def main(argv):
    if len(argv) < 2:
        print(__doc__)
        return 1
    relatorio, total_questoes, total_provas = validar(argv[1:])
    for linha in relatorio.erros + relatorio.avisos:
        print(linha)
    if relatorio.erros:
        print(f"\nProvas REPROVADAS: {len(relatorio.erros)} erro(s), {len(relatorio.avisos)} aviso(s).")
        return 1
    print(f"Provas aprovadas: {total_provas} prova(s), {total_questoes} questao(oes), {len(relatorio.avisos)} aviso(s).")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
