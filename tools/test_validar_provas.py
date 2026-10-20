#!/usr/bin/env python3
"""
Testes do validador de provas reais anteriores (tools/validar_provas.py).

Uso:
    python tools/test_validar_provas.py
"""

import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from validar_provas import validar  # noqa: E402

BASE = {
    "versaoFormato": 1,
    "prova": {
        "id": "teste-2020",
        "concurso": "Teste",
        "banca": "FAFIPA",
        "ano": 2020,
        "cargo": "Procurador",
        "dataAplicacao": "2020-01-01",
        "gabaritoDefinitivoPublicado": True,
        "fonte": "https://exemplo.org/teste",
    },
    "questoes": [
        {
            "numeroOriginal": 1,
            "id": "teste-2020-001",
            "materia": "adm",
            "tema": "Teste de validação",
            "enunciado": "Esta é uma questão de teste com enunciado longo o suficiente.",
            "alternativas": {"A": "Texto A", "B": "Texto B", "C": "Texto C", "D": "Texto D", "E": "Texto E"},
            "correta": "A",
            "dica": "Uma dica qualquer, sem entregar a resposta certa.",
            "explicacao": {
                "A": "Correta porque o texto da lei diz exatamente isso, conforme o artigo citado na fonte.",
                "B": "Errada porque contraria o texto da lei no ponto específico mencionado nesta alternativa.",
                "C": "Errada porque contraria o texto da lei no ponto específico mencionado nesta alternativa.",
                "D": "Errada porque contraria o texto da lei no ponto específico mencionado nesta alternativa.",
                "E": "Errada porque contraria o texto da lei no ponto específico mencionado nesta alternativa.",
            },
            "fontes": [{"tipo": "lei", "referencia": "Lei de teste, art. 1", "data": "2019-01-01"}],
        }
    ],
}


class TestValidadorDeProvas(unittest.TestCase):
    def setUp(self):
        self.pasta = tempfile.TemporaryDirectory()
        self.raiz = Path(self.pasta.name)

    def tearDown(self):
        self.pasta.cleanup()

    def gravar(self, dados, nome="teste-2020.json"):
        destino = self.raiz / nome
        destino.write_text(json.dumps(dados, ensure_ascii=False), encoding="utf-8")

    def rodar(self):
        relatorio, _, _ = validar([self.raiz])
        return relatorio

    def questao(self, dados):
        return dados["questoes"][0]

    def assertReprova(self, trecho):
        relatorio = self.rodar()
        self.assertTrue(
            any(trecho in e for e in relatorio.erros),
            f"esperava um erro contendo '{trecho}', veio: {relatorio.erros}",
        )

    def test_exemplo_valido_passa(self):
        self.gravar(copy.deepcopy(BASE))
        relatorio, total_questoes, total_provas = validar([self.raiz])
        self.assertEqual(relatorio.erros, [])
        self.assertEqual(total_questoes, 1)
        self.assertEqual(total_provas, 1)

    def test_arquivo_com_nome_diferente_do_id_da_prova_reprova(self):
        self.gravar(copy.deepcopy(BASE), nome="outro-nome.json")
        self.assertReprova("deve se chamar 'teste-2020.json'")

    def test_id_de_questao_que_nao_comeca_com_id_da_prova_reprova(self):
        dados = copy.deepcopy(BASE)
        self.questao(dados)["id"] = "outra-prova-001"
        self.gravar(dados)
        self.assertReprova("id nao comeca com 'teste-2020-'")

    def test_numero_original_repetido_reprova(self):
        dados = copy.deepcopy(BASE)
        segunda = copy.deepcopy(self.questao(dados))
        segunda["id"] = "teste-2020-002"
        segunda["enunciado"] = "Outra questão, com enunciado diferente da primeira."
        segunda["numeroOriginal"] = 1
        dados["questoes"].append(segunda)
        self.gravar(dados)
        self.assertReprova("numeroOriginal 1 repetido")

    def test_fora_de_ordem_crescente_reprova(self):
        dados = copy.deepcopy(BASE)
        segunda = copy.deepcopy(self.questao(dados))
        segunda["id"] = "teste-2020-002"
        segunda["enunciado"] = "Outra questão, com enunciado diferente da primeira."
        segunda["numeroOriginal"] = 5
        dados["questoes"].insert(0, segunda)  # a de número 5 vem antes da de número 1
        self.gravar(dados)
        self.assertReprova("nao estao em ordem crescente")

    def test_explicacao_curta_reprova(self):
        dados = copy.deepcopy(BASE)
        self.questao(dados)["explicacao"]["C"] = "Errada."
        self.gravar(dados)
        self.assertReprova("explicacao da C (uma errada)")

    def test_dica_que_entrega_a_resposta_reprova(self):
        dados = copy.deepcopy(BASE)
        self.questao(dados)["dica"] = "Pense bem: a alternativa A é a mais completa."
        self.gravar(dados)
        self.assertReprova("entrega a resposta")

    def test_fonte_posterior_a_aplicacao_da_prova_reprova(self):
        dados = copy.deepcopy(BASE)
        self.questao(dados)["fontes"][0]["data"] = "2021-06-01"
        self.gravar(dados)
        self.assertReprova("depois da aplicacao da prova (2020-01-01)")

    def test_duas_alternativas_iguais_reprova(self):
        dados = copy.deepcopy(BASE)
        self.questao(dados)["alternativas"]["B"] = self.questao(dados)["alternativas"]["A"]
        self.gravar(dados)
        self.assertReprova("duas alternativas com o mesmo texto")

    def test_questao_duplicada_entre_arquivos_reprova(self):
        self.gravar(copy.deepcopy(BASE), nome="teste-2020.json")
        outra = copy.deepcopy(BASE)
        outra["prova"]["id"] = "teste-2021"
        outra["questoes"][0]["id"] = "teste-2021-001"
        self.gravar(outra, nome="teste-2021.json")
        self.assertReprova("questao identica a")

    def test_id_da_prova_diferente_do_nome_do_arquivo_no_schema_reprova(self):
        dados = copy.deepcopy(BASE)
        dados["prova"]["id"] = "id-diferente"
        self.gravar(dados)
        self.assertReprova("deve se chamar 'id-diferente.json'")


if __name__ == "__main__":
    unittest.main()
