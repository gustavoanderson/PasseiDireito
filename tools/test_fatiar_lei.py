#!/usr/bin/env python3
"""Testes do extrator de artigos. Cada caso vem de um defeito que a lei real tem."""

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from fatiar_lei import fatiar  # noqa: E402

HTML = """
<html><head><style>p{color:red}</style></head><body>
<p>CAPÍTULO VII<br>Da Prescrição</p>
<p><strike><a name="art23"></a>Art. 23. As ações podem ser propostas:</strike></p>
<p><strike>I - até cinco anos após o término do mandato;</strike></p>
<p>Art. 23. A ação prescreve em 8 (oito) anos, contados a partir da ocorrência do fato. (Redação dada pela Lei nº 14.230, de 2021)</p>
<p>§ 1º A instauração de inquérito civil suspende o prazo por, no máximo, 180 dias. (Incluído pela Lei nº 14.230, de 2021)</p>
<p>§ 5º Interrompida a prescrição, o prazo recomeça pela metade. (Incluído pela Lei nº 14.230, de 2021) (Vide ADI 7236) (Vide ADI 7156)</p>
<p>Art. 23-A. É dever do poder público oferecer capacitação. (Incluído pela Lei nº 14.230, de 2021)</p>
<p>Art. 24. (Revogado pela Lei nº 14.230, de 2021)</p>
<p>Art. 178. O Código Penal passa a vigorar acrescido do seguinte artigo:</p>
<p>“Art. 337-E. Admitir, possibilitar ou dar causa à contratação direta fora das hipóteses previstas em lei:</p>
<p>Pena - reclusão, de 4 (quatro) a 8 (oito) anos, e multa.”</p>
<p>Art. 8º O sucessor responde até o limite da herança.</p>
<p>Art. 8º-A A responsabilidade sucessória aplica-se também à fusão. (Incluído pela Lei nº 14.230, de 2021)</p>
<p>Art. 9º Podem promover a desapropriação, mediante autorização: (Redação dada pela Medida Provisória nº 1.065, de 2021) Vigência encerrada</p>
<p>Art. 9º Poderão promover a desapropriação mediante autorização expressa: (Redação dada pela Lei nº 14.620, de 2023)</p>
<p>Art. 153. O escrivão deverá obedecer à ordem cronológica.</p>
<p>Art. 153. O escrivão atenderá, preferencialmente, à ordem cronológica. (Redação dada pela Lei nº 13.256, de 2016)</p>
<p>Art. <font>5</font> <font>7</font>. (VETADO).</p>
<p>Art. 21. A alíquota dos segurados contribuinte individual e facultativo será de vinte por cento. (Redação dada pela Lei nº 9.876, de 1999)</p>
<p>Art. 21. A alíquota dos segurados empresários e trabalhador autônomo é de vinte por cento.</p>
<p>Art. 62. Texto repetido pela página.</p>
<p>Art. 62. Texto repetido pela página.</p>
<p>Art. 30. Texto A sem nota.</p>
<p>Art. 30. Texto B sem nota.</p>
<p><a name="art5"></a>Art. 5º Todos são iguais
perante a lei.</p>
<p><font>Art.
6º São direitos sociais a educação e a saúde.</font></p>
<p>Brasília, 5 de outubro de 1988.</p>
<p>ATO DAS DISPOSIÇÕES CONSTITUCIONAIS TRANSITÓRIAS</p>
<p>Art. 1º O Presidente da República prestará o compromisso.</p>
<p>Brasília, 2 de junho de 1992; 171º da Independência.</p>
<p>Art. 99. Isto é assinatura, não artigo.</p>
</body></html>
"""


class TestFatiar(unittest.TestCase):
    def setUp(self):
        self.artigos = fatiar(HTML)
        self.por_id = {a["id"]: a for a in self.artigos}

    def test_redacao_riscada_e_descartada(self):
        art23 = self.por_id["23"]
        self.assertIn("8 (oito) anos", art23["texto"])
        self.assertNotIn("cinco anos após o término", art23["texto"])
        self.assertEqual([a["id"] for a in self.artigos].count("23"), 1)

    def test_paragrafos_ficam_no_artigo(self):
        self.assertIn("§ 1º A instauração", self.por_id["23"]["texto"])

    def test_vide_adi_e_marcado(self):
        self.assertEqual(self.por_id["23"]["videStf"], ["ADI 7156", "ADI 7236"])
        self.assertEqual(self.por_id["23-A"]["videStf"], [])

    def test_notas_de_redacao(self):
        self.assertIn("Redação dada pela Lei nº 14.230, de 2021", self.por_id["23"]["notas"])

    def test_artigo_com_letra(self):
        self.assertIn("23-A", self.por_id)

    def test_revogado(self):
        self.assertTrue(self.por_id["24"]["revogado"])
        self.assertFalse(self.por_id["23"]["revogado"])

    def test_artigo_citado_entre_aspas_nao_vira_artigo_desta_lei(self):
        self.assertNotIn("337-E", self.por_id)
        self.assertIn("337-E", self.por_id["178"]["texto"])

    def test_adct_recebe_prefixo_proprio(self):
        self.assertIn("5", self.por_id)
        self.assertIn("ADCT-1", self.por_id)
        self.assertEqual(self.por_id["ADCT-1"]["local"], "ADCT")

    def test_quebra_de_linha_do_html_nao_parte_o_artigo(self):
        self.assertIn("6", self.por_id)
        self.assertEqual(self.por_id["5"]["texto"], "Art. 5º Todos são iguais perante a lei.")

    def test_letra_depois_do_ordinal(self):
        self.assertIn("8-A", self.por_id)
        self.assertEqual([a["id"] for a in self.artigos].count("8"), 1)

    def test_redacao_de_mp_caducada_sai(self):
        self.assertEqual([a["id"] for a in self.artigos].count("9"), 1)
        self.assertIn("Poderão promover", self.por_id["9"]["texto"])
        self.assertFalse(self.por_id["9"]["duplicado"])

    def test_versao_antiga_sem_risco_fica_a_ultima(self):
        self.assertIn("preferencialmente", self.por_id["153"]["texto"])
        self.assertEqual(self.por_id["153"]["versoesDescartadas"], 1)
        self.assertEqual([a["id"] for a in self.artigos].count("153"), 1)

    def test_fica_a_versao_com_nota_de_redacao_mesmo_que_nao_seja_a_ultima(self):
        self.assertIn("contribuinte individual", self.por_id["21"]["texto"])
        self.assertFalse(self.por_id["21"]["conferir"])

    def test_sem_nota_em_nenhuma_versao_marca_para_conferir(self):
        self.assertTrue(self.por_id["30"]["conferir"])
        self.assertFalse(self.por_id["23-A"]["conferir"])

    def test_versoes_identicas_nao_precisam_de_conferencia(self):
        self.assertFalse(self.por_id["62"]["conferir"])
        self.assertEqual(self.por_id["62"]["versoesDescartadas"], 1)

    def test_numero_partido_pela_formatacao(self):
        self.assertIn("57", self.por_id)

    def test_para_na_assinatura(self):
        self.assertNotIn("99", self.por_id)

    def test_local_guarda_o_capitulo(self):
        self.assertEqual(self.por_id["23"]["local"], "CAPÍTULO VII")


if __name__ == "__main__":
    unittest.main(verbosity=1)
