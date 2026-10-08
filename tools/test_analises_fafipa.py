#!/usr/bin/env python3
"""Testes dos arquivos de análise da banca (app/assets/analises/*.json).

São os dados por trás do "Raio-X da banca": histórico de anulações e
gabaritos alterados (fafipa_historico.json) e temas mais cobrados por
matéria, com a lacuna em relação ao edital de Curitiba (fafipa_temas.json).

A garantia mais importante aqui não é de schema, é de COMPLETUDE: todo item
do Anexo II (cada unidade real do banco) tem que aparecer em exatamente uma
das três listas de fafipa_temas.json (com registro, sem registro na amostra,
ou excluído por ser lei municipal) — nunca em zero, nunca em duas.
"""

import glob
import json
import sys
import unittest
from pathlib import Path

RAIZ = Path(__file__).parent.parent
ANALISES = RAIZ / "app" / "assets" / "analises"
QUESTOES = RAIZ / "app" / "assets" / "questoes"


def itens_reais_do_banco() -> dict[str, set[int]]:
    """Para cada matéria com arquivo de análise, os itemEdital que existem de verdade."""
    itens: dict[str, set[int]] = {}
    for pasta in sorted((QUESTOES).iterdir()):
        if not pasta.is_dir():
            continue
        materia = pasta.name
        ids = set()
        for arquivo in pasta.glob("*.json"):
            unidade = json.loads(arquivo.read_text(encoding="utf-8"))["unidade"]
            ids.add(unidade["itemEdital"])
        itens[materia] = ids
    return itens


class TestFafipaHistorico(unittest.TestCase):
    def setUp(self):
        self.dados = json.loads((ANALISES / "fafipa_historico.json").read_text(encoding="utf-8"))

    def test_tem_pelo_menos_uma_prova(self):
        self.assertGreater(len(self.dados["provas"]), 0)

    def test_todo_motivo_citado_existe_na_lista_de_motivos(self):
        codigos_validos = {m["codigo"] for m in self.dados["motivos"]}
        for prova in self.dados["provas"]:
            for anulada in prova["anuladas"]:
                motivo = anulada.get("motivo")
                if motivo is not None:
                    self.assertIn(motivo, codigos_validos, f"{prova['concurso']} questão {anulada['numero']}")
            for alterado in prova["gabaritoAlterado"]:
                motivo = alterado.get("motivo")
                if motivo is not None:
                    self.assertIn(motivo, codigos_validos, f"{prova['concurso']} questão {alterado['numero']}")

    def test_contagem_de_anuladas_bate_com_o_resumo(self):
        # Só as provas com gabarito definitivo entram na contagem (a de
        # Matinhos e a de Jaguariaíva só têm preliminar: gabaritoDefinitivoPublicado=false).
        definitivas = [p for p in self.dados["provas"] if p["gabaritoDefinitivoPublicado"]]
        self.assertEqual(len(definitivas), self.dados["resumo"]["provasComGabaritoDefinitivo"])
        self.assertEqual(sum(len(p["anuladas"]) for p in definitivas), self.dados["resumo"]["anuladas"])
        self.assertEqual(sum(p["questoes"] for p in definitivas), self.dados["resumo"]["questoesNessasProvas"])
        self.assertEqual(sum(len(p["gabaritoAlterado"]) for p in definitivas), self.dados["resumo"]["gabaritosAlterados"])

    def test_cada_prova_tem_fonte(self):
        for prova in self.dados["provas"]:
            self.assertTrue(prova["fonte"].startswith("http"), prova["concurso"])


class TestFafipaTemas(unittest.TestCase):
    def setUp(self):
        self.dados = json.loads((ANALISES / "fafipa_temas.json").read_text(encoding="utf-8"))
        self.itens_reais = itens_reais_do_banco()

    def test_toda_materia_do_banco_tem_entrada(self):
        for materia in self.itens_reais:
            self.assertIn(materia, self.dados["materias"], f"falta a matéria {materia}")

    def test_todo_item_aparece_em_exatamente_uma_lista(self):
        for materia, itens in self.itens_reais.items():
            info = self.dados["materias"][materia]
            com_registro = set(info.get("itensComRegistro", []))
            sem_registro = set(info.get("itensSemRegistroNaAmostra", []))
            municipais = set(info.get("itensMunicipaisExcluidos", []))

            sobreposicao = (com_registro & sem_registro) | (com_registro & municipais) | (sem_registro & municipais)
            self.assertEqual(sobreposicao, set(), f"{materia}: item em mais de uma lista: {sobreposicao}")

            uniao = com_registro | sem_registro | municipais
            faltando = itens - uniao
            sobrando = uniao - itens
            self.assertEqual(faltando, set(), f"{materia}: item do banco sem classificação: {faltando}")
            self.assertEqual(sobrando, set(), f"{materia}: item classificado que não existe no banco: {sobrando}")


if __name__ == "__main__":
    unittest.main()
