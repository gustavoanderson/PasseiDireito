#!/usr/bin/env python3
"""
Busca e extração de normas de Curitiba no Legisladoc, o sistema oficial da
Prefeitura (legisladocexterno.curitiba.pr.gov.br).

Por que um navegador: a busca do Legisladoc é um formulário ASP.NET cujo
resultado só aparece depois de JavaScript; POST direto (síncrono ou AJAX)
devolve a página sem resultados. O Playwright pilota o Chrome já instalado
(channel="chrome"), sem baixar outro navegador. Só é usado para montar a base,
nunca pelo app.

A página de um ato traz DOIS textos: primeiro o "Alterado" (com as mudanças
incorporadas, o vigente) e depois o "Original". Ler os dois duplicava artigos.
"""

import html as html_lib
import re
import urllib.request

BASE = "https://legisladocexterno.curitiba.pr.gov.br"
NAVEGADOR = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/153 Safari/537.36"

# Valores do campo "Tipo Ato" do formulário.
TIPOS = {"lei": "6", "lei-complementar": "3", "decreto": "1", "lei-organica": "107", "emenda-lei-organica": "33"}


def buscar(page, tipo: str, numero: int, ano: int | None) -> list[dict]:
    """Devolve os atos encontrados: id, situação, data de publicação e súmula."""
    page.goto(f"{BASE}/AtosConsultaExterna.aspx", wait_until="networkidle")
    page.select_option("#ctl00_cphMasterPrincipal_ddlTipoAto", TIPOS[tipo])
    page.fill("#ctl00_cphMasterPrincipal_txtNrAto", str(numero))
    if ano:
        page.fill("#ctl00_cphMasterPrincipal_txtAno", str(ano))
    page.click("#ctl00_cphMasterPrincipal_lnbPesquisar")
    page.wait_for_load_state("networkidle")
    page.wait_for_timeout(2500)
    return ler_resultados(page.content())


def ler_resultados(html: str) -> list[dict]:
    atos = []
    for linha in re.findall(r"(?is)<tr[^>]*>(.*?)</tr>", html):
        m = re.search(r"linkToView\((?:&quot;|\"|')?(\d+)", linha)
        if not m:
            continue
        celulas = [re.sub(r"\s+", " ", html_lib.unescape(re.sub(r"<[^>]+>", " ", c))).strip()
                   for c in re.findall(r"(?is)<td[^>]*>(.*?)</td>", linha)]
        data = next((d for c in celulas for d in re.findall(r"\d{2}/\d{2}/\d{4}", c)), "")
        situacao = next((c for c in celulas if c in {"Em Vigor", "Alterado", "Revogado", "Revogada", "Suspenso"}), "")
        sumula = max(celulas, key=len) if celulas else ""
        atos.append({"id": m.group(1), "situacao": situacao, "publicacao": data, "sumula": sumula})
    return atos


def baixar_ato(id_: str) -> str:
    req = urllib.request.Request(f"{BASE}/VisualizarHTML.aspx?id={id_}", headers={"User-Agent": NAVEGADOR})
    return urllib.request.urlopen(req, timeout=90).read().decode("utf-8", "replace")


def corpo_vigente(html: str) -> str:
    """Só o bloco "Alterado" (vigente); sem ele, o único bloco de texto."""
    ini = html.find('id="ctlAlteradoLogo1"')
    fim = html.find('id="ctlOriginalLogo1"')
    if ini != -1:
        return html[ini:fim if fim > ini else len(html)]
    ini = html.find('id="ctlOriginalLogo1"')
    return html[ini:] if ini != -1 else html
