#!/usr/bin/env python3
"""
Testes do validador. Cada defeito que ele promete barrar tem um teste que o
provoca de proposito numa copia da questao-exemplo.

Uso:
    python tools/test_validar_questoes.py
"""

import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from validar_questoes import validar  # noqa: E402

EXEMPLO = Path(__file__).parent.parent / "app" / "assets" / "questoes" / "adm" / "adm-04.json"


class TestValidador(unittest.TestCase):

    def setUp(self):
        self.base = json.loads(EXEMPLO.read_text(encoding="utf-8"))
        self.pasta = tempfile.TemporaryDirectory()
        self.raiz = Path(self.pasta.name)

    def tearDown(self):
        self.pasta.cleanup()

    def gravar(self, dados, materia="adm", nome="adm-04.json"):
        destino = self.raiz / materia / nome
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.write_text(json.dumps(dados, ensure_ascii=False), encoding="utf-8")

    def rodar(self):
        relatorio, _ = validar([self.raiz])
        return relatorio

    def questao(self, dados):
        return dados["questoes"][0]

    def assertReprova(self, trecho):
        relatorio = self.rodar()
        self.assertTrue(
            any(trecho in e for e in relatorio.erros),
            f"esperava um erro contendo '{trecho}', veio: {relatorio.erros}",
        )

    # --- o caminho feliz ---

    def test_exemplo_real_do_repositorio_passa(self):
        relatorio, total = validar([EXEMPLO.parent.parent])
        self.assertEqual(relatorio.erros, [])
        self.assertGreaterEqual(total, 1)

    # --- o criterio de sucesso do passo 1 ---

    def test_sem_explicacao_de_uma_errada_reprova(self):
        dados = copy.deepcopy(self.base)
        del self.questao(dados)["explicacao"]["D"]
        self.gravar(dados)
        self.assertReprova("'D' is a required property")

    def test_explicacao_de_uma_linha_reprova(self):
        dados = copy.deepcopy(self.base)
        self.questao(dados)["explicacao"]["C"] = "Errada."
        self.gravar(dados)
        self.assertReprova("explicacao da C (uma errada)")

    # --- formato de prova da FAFIPA ---

    def test_quatro_alternativas_reprova(self):
        dados = copy.deepcopy(self.base)
        del self.questao(dados)["alternativas"]["E"]
        self.gravar(dados)
        self.assertReprova("'E' is a required property")

    def test_sexta_alternativa_reprova(self):
        dados = copy.deepcopy(self.base)
        self.questao(dados)["alternativas"]["F"] = "Uma sexta alternativa."
        self.gravar(dados)
        self.assertReprova("Additional properties are not allowed")

    def test_alternativas_repetidas_reprova(self):
        dados = copy.deepcopy(self.base)
        q = self.questao(dados)
        q["alternativas"]["E"] = q["alternativas"]["A"]
        self.gravar(dados)
        self.assertReprova("duas alternativas com o mesmo texto")

    # --- dica e fontes ---

    def test_dica_que_entrega_a_letra_reprova(self):
        dados = copy.deepcopy(self.base)
        self.questao(dados)["dica"] = "Releia com atenção a alternativa B antes de responder."
        self.gravar(dados)
        self.assertReprova("entrega a resposta")

    def test_sem_fonte_reprova(self):
        dados = copy.deepcopy(self.base)
        self.questao(dados)["fontes"] = []
        self.gravar(dados)
        self.assertReprova("should be non-empty")

    def test_fonte_depois_da_data_de_corte_reprova(self):
        dados = copy.deepcopy(self.base)
        self.questao(dados)["fontes"].append(
            {"tipo": "repetitivo", "referencia": "Tema hipotético do STJ", "data": "2026-10-01"}
        )
        self.gravar(dados)
        self.assertReprova("depois da data de corte")

    def test_fonte_no_dia_do_edital_passa(self):
        dados = copy.deepcopy(self.base)
        self.questao(dados)["fontes"].append(
            {"tipo": "repetitivo", "referencia": "Tema hipotético do STJ", "data": "2026-09-21"}
        )
        self.gravar(dados)
        self.assertEqual(self.rodar().erros, [])

    def test_adaptada_sem_prova_de_origem_reprova(self):
        dados = copy.deepcopy(self.base)
        self.questao(dados)["origem"] = {"tipo": "adaptada"}
        self.gravar(dados)
        self.assertReprova("de qual prova veio")

    def test_alerta_que_cita_a_data_do_edital_passa(self):
        dados = copy.deepcopy(self.base)
        self.questao(dados)["alerta"] = "Mudança recente na lei. Responda pela norma em vigor em 21/09/2026, data do edital."
        self.gravar(dados)
        self.assertEqual(self.rodar().erros, [])

    def test_alerta_sem_a_data_do_edital_reprova(self):
        dados = copy.deepcopy(self.base)
        self.questao(dados)["alerta"] = "Mudança recente na lei: confira a redação nova antes de responder."
        self.gravar(dados)
        self.assertReprova("citar a data do edital")

    # --- organizacao do banco ---

    def test_id_repetido_em_outro_arquivo_reprova(self):
        self.gravar(self.base)
        outra = copy.deepcopy(self.base)
        outra["unidade"]["id"] = "adm-05"
        self.questao(outra)["enunciado"] += " (outra redação)"
        self.gravar(outra, nome="adm-05.json")
        self.assertReprova("id repetido")

    def test_materia_na_pasta_errada_reprova(self):
        self.gravar(self.base, materia="const")
        self.assertReprova("declara a materia 'adm'")

    def test_item_que_nao_existe_no_edital_reprova(self):
        dados = copy.deepcopy(self.base)
        dados["unidade"]["itemEdital"] = 18
        self.gravar(dados)
        self.assertReprova("itemEdital 18 nao existe")

    def test_gabarito_previsivel_gera_aviso(self):
        dados = copy.deepcopy(self.base)
        modelo = self.questao(dados)
        dados["questoes"] = []
        for i in range(20):
            q = copy.deepcopy(modelo)
            q["id"] = f"adm-{i + 1:04d}"
            q["enunciado"] = f"{modelo['enunciado']} Variação {i + 1}."
            dados["questoes"].append(q)
        self.gravar(dados)
        relatorio = self.rodar()
        self.assertEqual(relatorio.erros, [])
        self.assertTrue(any("gabarito ficou previsivel" in a for a in relatorio.avisos))


if __name__ == "__main__":
    unittest.main(verbosity=2)
