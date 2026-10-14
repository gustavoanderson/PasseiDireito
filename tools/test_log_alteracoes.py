#!/usr/bin/env python3
"""Testes do log de alterações (app/assets/analises/log_alteracoes.json).

É o histórico, dentro do app, do que mudou no banco por causa do edital —
pedido da Flávia pra saber o que saiu e quando. A garantia mais importante
aqui é o BATIMENTO contra o banco de verdade: toda questão listada como
removida não pode mais existir, e toda questão listada como criada tem que
existir. Sem isso, o log vira só um texto solto, sem garantia de estar certo.
"""

import json
import unittest
from datetime import date
from pathlib import Path

RAIZ = Path(__file__).parent.parent
ANALISES = RAIZ / "app" / "assets" / "analises"
QUESTOES = RAIZ / "app" / "assets" / "questoes"

TIPOS_VALIDOS = {"edital", "remocao", "ajuste", "criacao"}


def ids_do_banco() -> set[str]:
    ids = set()
    for arquivo in QUESTOES.glob("*/*.json"):
        dados = json.loads(arquivo.read_text(encoding="utf-8"))
        ids.update(q["id"] for q in dados["questoes"])
    return ids


class TestLogDeAlteracoes(unittest.TestCase):
    def setUp(self):
        self.dados = json.loads((ANALISES / "log_alteracoes.json").read_text(encoding="utf-8"))
        self.ids_reais = ids_do_banco()

    def test_tem_pelo_menos_um_evento(self):
        self.assertGreater(len(self.dados["eventos"]), 0)

    def test_eventos_vem_em_ordem_cronologica(self):
        datas = [date.fromisoformat(e["data"]) for e in self.dados["eventos"]]
        self.assertEqual(datas, sorted(datas), "eventos fora de ordem cronológica")

    def test_tipo_de_cada_evento_e_valido(self):
        for e in self.dados["eventos"]:
            self.assertIn(e["tipo"], TIPOS_VALIDOS, e["titulo"])

    def test_questao_removida_nao_pode_mais_existir_no_banco(self):
        for e in self.dados["eventos"]:
            for qid in e.get("questoesRemovidas", []):
                self.assertNotIn(qid, self.ids_reais, f"{e['titulo']}: {qid} diz que saiu, mas ainda está no banco")

    def test_questao_criada_tem_que_existir_no_banco(self):
        for e in self.dados["eventos"]:
            for qid in e.get("questoesCriadas", []):
                self.assertIn(qid, self.ids_reais, f"{e['titulo']}: {qid} diz que foi criada, mas não está no banco")


if __name__ == "__main__":
    unittest.main()
