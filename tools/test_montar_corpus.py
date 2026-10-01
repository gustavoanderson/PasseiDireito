#!/usr/bin/env python3
"""Testes da trava da data de corte do montador da base de lei."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from montar_corpus import aplicar_corte  # noqa: E402

POSTERIORES = {"Lei 15517/2026"}


def artigo(*linhas):
    return {"texto": "\n".join(linhas), "notas": []}


class TestCorte(unittest.TestCase):
    def test_artigo_sem_norma_posterior_fica_intacto(self):
        a = artigo("Art. 155 - Subtrair coisa alheia móvel: (Redação dada pela Lei nº 9.426, de 1996)")
        self.assertEqual(aplicar_corte(a, POSTERIORES), "intacto")

    def test_paragrafo_incluido_depois_sai_e_o_artigo_fica(self):
        a = artigo(
            "Art. 155 - Subtrair, para si ou para outrem, coisa alheia móvel:",
            "Pena - reclusão, de um a quatro anos, e multa.",
            "§ 8º Se a subtração for de cabo de energia... (Incluído pela Lei nº 15.517, de 2026)",
        )
        self.assertEqual(aplicar_corte(a, POSTERIORES), "aparado")
        self.assertIn("Subtrair", a["texto"])
        self.assertNotIn("§ 8º", a["texto"])

    def test_artigo_criado_depois_sai_inteiro(self):
        a = artigo("Art. 155-A. Artigo novo. (Incluído pela Lei nº 15.517, de 2026)", "Parágrafo único. Detalhe.")
        self.assertEqual(aplicar_corte(a, POSTERIORES), "removido")

    def test_redacao_trocada_depois_pede_correcao(self):
        a = artigo("Art. 157 - Subtrair com violência: (Redação dada pela Lei nº 15.517, de 2026)")
        self.assertEqual(aplicar_corte(a, POSTERIORES), "alterado")


if __name__ == "__main__":
    unittest.main(verbosity=1)
