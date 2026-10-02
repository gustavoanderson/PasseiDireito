#!/usr/bin/env python3
"""Testes das correções da base de Curitiba (texto "Alterado" desatualizado)."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from montar_corpus_curitiba import aplicar_correcoes  # noqa: E402


def artigo(id_, texto):
    return {"id": id_, "texto": texto, "notas": [], "revogado": False, "conferir": False}


class TestCorrecoes(unittest.TestCase):
    def setUp(self):
        # Retrato da LC 108/2017 como o Legisladoc a mostrava em 01/10/2026.
        self.artigos = [
            artigo("11", "Art. 11. ... prazo não inferior a 5 (cinco) anos ..."),
            artigo("12", "Art. 12. O imposto deverá ser pago ..."),
            artigo("13", "Art. 13. O imposto não pago no vencimento ..."),
        ]
        self.correcoes = {
            "11": {"texto": "Art. 11. ... prazo não inferior a 10 (dez) anos ...", "motivo": "LC 148/2025.", "fonte": "LC 148/2025"},
            "11-A": {"texto": "Art. 11-A. Para as unidades autônomas ...", "novo": True, "depoisDe": "11", "motivo": "LC 148/2025.", "fonte": "LC 148/2025"},
            "13": {"texto": "Art. 13. (Revogado)", "revogado": True, "motivo": "LC 134/2022.", "fonte": "LC 134/2022"},
        }

    def test_redacao_nova_substitui_a_velha(self):
        aplicar_correcoes(self.artigos, self.correcoes)
        self.assertIn("10 (dez) anos", self.artigos[0]["texto"])
        self.assertIn("reconstruída", self.artigos[0]["notas"][0])

    def test_artigo_acrescentado_entra_na_posicao_certa(self):
        aplicar_correcoes(self.artigos, self.correcoes)
        self.assertEqual([a["id"] for a in self.artigos], ["11", "11-A", "12", "13"])

    def test_artigo_revogado_fica_marcado(self):
        aplicar_correcoes(self.artigos, self.correcoes)
        self.assertTrue(self.artigos[-1]["revogado"])

    def test_correcao_de_artigo_que_nao_existe_e_avisada(self):
        feitos = aplicar_correcoes(self.artigos, {"99": {"texto": "x", "motivo": "m", "fonte": "f"}})
        self.assertIn("conferir", feitos[0])


if __name__ == "__main__":
    unittest.main()
