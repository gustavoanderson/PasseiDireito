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
<p><s> <strong>Art. 70</strong> Texto revogado riscado ao estilo do Legisladoc.</s> <span>(Revogado pela Lei Complementar nº 133/2021)</span></p>
<p><span>Art. 71.</span> <strong>Vigente</strong> depois do riscado.</p>
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
<p>Art. 988. Caberá reclamação da parte interessada ou do Ministério Público para:</p>
<p>I - preservar a competência do tribunal;</p>
<p>III - garantir a observância de decisão do Supremo Tribunal Federal em controle concentrado de constitucionalidade;</p>
<p>III – garantir a observância de enunciado de súmula vinculante e de decisão do Supremo Tribunal Federal em controle concentrado de constitucionalidade; (Redação dada pela Lei nº 15.484, de 2026)</p>
<p>IV - garantir a observância de precedente proferido em julgamento de casos repetitivos ou em incidente de assunção de competência;</p>
<p>IV – garantir a observância de acórdão proferido em julgamento de recurso especial sob o regime de relevância; (Incluído pela Lei nº 15.484, de 2026)</p>
<p>§ 5º É inadmissível a reclamação proposta após o trânsito em julgado da decisão.</p>
<p>§ 5º Será liminarmente indeferida a reclamação: (Redação dada pela Lei nº 15.484, de 2026)</p>
<p>I – proposta após o trânsito em julgado da decisão reclamada;</p>
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

    def test_norma_que_comeca_depois_da_assinatura(self):
        html = (
            "<p>Art. 1º Fica aprovada a Consolidação que a este acompanha.</p>"
            "<p>Rio de Janeiro, 1 de maio de 1943.</p>"
            "<p>CONSOLIDAÇÃO DAS LEIS DO TRABALHO</p>"
            "<p>Art. 1º - Esta Consolidação estatui as normas do trabalho.</p>"
            "<p>Art. 2º - Considera-se empregador a empresa.</p>"
        )
        artigos = {a["id"]: a for a in fatiar(html, comecar_em=r"^CONSOLIDAÇÃO DAS LEIS DO TRABALHO$")}
        self.assertEqual(sorted(artigos), ["1", "2"])
        self.assertIn("estatui as normas", artigos["1"]["texto"])

    def test_disposicoes_transitorias_da_lei_organica(self):
        artigos = {a["id"]: a for a in fatiar(
            "<p>Art. 7º Todo Poder emana do povo.</p><p>ATO DAS DISPOSIÇÕES TRANSITÓRIAS</p>"
            "<p>Art. 7º Os serviços públicos delegados continuarão regidos pelos atos de concessão.</p>"
        )}
        self.assertIn("Todo Poder", artigos["7"]["texto"])
        self.assertIn("serviços públicos", artigos["ADT-7"]["texto"])
        self.assertFalse(artigos["7"]["conferir"])

    def test_riscado_do_legisladoc_com_tag_s_e_descartado(self):
        self.assertNotIn("70", self.por_id)
        self.assertIn("Vigente", self.por_id["71"]["texto"])

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

    def test_inciso_repetido_sem_risco_fica_so_a_versao_com_nota(self):
        # CPC, art. 988, em 01/10/2026: o Planalto não riscou a redação
        # antiga do III, do IV e do § 5º antes de mostrar a nova (Lei
        # 15.484/2026). Sem isto, os dois textos entravam como se ambos
        # valessem, e a IA liA leria regra revogada como vigente.
        texto = self.por_id["988"]["texto"]
        self.assertEqual(texto.count("III"), 1)
        self.assertIn("súmula vinculante", texto)
        self.assertNotIn("casos repetitivos", texto)  # IV antigo, substituído
        self.assertIn("regime de relevância", texto)  # IV novo
        self.assertEqual(texto.count("§ 5º"), 1)
        self.assertIn("liminarmente indeferida", texto)
        self.assertFalse(self.por_id["988"]["conferir"])

    def test_inciso_com_letra_colada_nao_se_confunde_com_o_numero_puro(self):
        # CF, art. 92: "I - o Supremo Tribunal Federal;" e "I-A o Conselho
        # Nacional de Justiça;" são incisos DIFERENTES, não duas versões do
        # mesmo "I". Achado reconstruindo o corpus federal em 02/10/2026: o
        # "I" puro sumiu, fundido com o "I-A" por causa de um retrocesso do
        # regex do rótulo.
        html = (
            "<p>Art. 92. São órgãos do Poder Judiciário:</p>"
            "<p>I - o Supremo Tribunal Federal;</p>"
            "<p>I-A o Conselho Nacional de Justiça; (Incluído pela Emenda Constitucional nº 45, de 2004)</p>"
            "<p>II - o Superior Tribunal de Justiça;</p>"
        )
        texto = fatiar(html)[0]["texto"]
        self.assertIn("I - o Supremo Tribunal Federal;", texto)
        self.assertIn("I-A o Conselho Nacional de Justiça", texto)

    def test_inciso_repetido_sem_nenhuma_nota_marca_para_conferir(self):
        html = (
            "<p>Art. 50. Texto do caput.</p>"
            "<p>I - versão A do inciso;</p>"
            "<p>I - versão B do inciso, sem nota nenhuma;</p>"
        )
        artigos = fatiar(html)
        self.assertTrue(artigos[0]["conferir"])
        self.assertEqual(artigos[0]["texto"].count("I -"), 1)


if __name__ == "__main__":
    unittest.main(verbosity=1)
