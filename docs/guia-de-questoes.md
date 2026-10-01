# Guia de produção de questões

Quem escreve questões para o PasseiDireito (pessoa ou agente) segue este guia. Leia antes o [CLAUDE.md](../CLAUDE.md).

## O que está em jogo

As questões são para uma prova real: Procurador do Município de Curitiba, Edital 6/2026, banca FAFIPA, prova objetiva em 13/12/2026. **Uma questão com gabarito errado ensina errado.** Prefira escrever menos questões certas a mais questões duvidosas.

## Regras que não se negociam

1. **Data de corte: 21/09/2026.** Lei, súmula e tese valem na redação vigente nessa data. Nada posterior.
2. **Só escreva sobre texto que você leu na fonte oficial nesta sessão.** Nunca de memória.
   - **Primeiro, a base de lei do repositório:** `corpus/federal/<id>.json` (Planalto) e `corpus/curitiba/<id>.json` (Legisladoc). Cada arquivo tem `artigos`, e cada artigo tem `texto` (a redação vigente em 21/09/2026, já sem o riscado e sem o que norma posterior ao edital acrescentou), `notas`, `videStf` e `revogado`. A lista do que existe está em `corpus/normas.json` e `corpus/normas_curitiba.json`. Ler daí é mais rápido e mais seguro do que baixar de novo: as armadilhas do HTML do Planalto já foram tratadas.
   - Artigo com `videStf` não vazio: não use como gabarito sem ler a decisão. Artigo com `conferir: true`: não use.
   - Leis federais: `https://www.planalto.gov.br/ccivil_03/...`. O WebFetch costuma dar ECONNRESET no Planalto; use `curl -s -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/153"` e extraia o texto (a página é cp1252 ou utf-8; o texto quebra linha no meio do artigo — junte os espaços antes de procurar "Art. 72.").
   - STF (teses de repercussão geral, súmulas): portal.stf.jus.br. STJ (repetitivos, súmulas): stj.jus.br / scon.stj.jus.br. Conferir a tese em fonte oficial ou tribunal (TJ, TRF) que a transcreva.
   - Curitiba e Paraná: leismunicipais.com.br (Curitiba), www.cmc.pr.gov.br, www.legislacao.pr.gov.br, www.tce.pr.gov.br. **Se não conseguir ler o texto oficial da norma municipal, não escreva a questão:** registre o item como pendente no seu relatório.
3. **Dispositivo com "Vide ADI", "Vide ADC" ou "Vide ADPF" no Planalto** foi mexido pelo STF. Não use como gabarito sem ler a decisão. Na dúvida, escolha outro dispositivo.
4. **Nunca misture lei municipal ou estadual de outro ente** (Araucária, Foz, outros estados). Curitiba e Paraná, sim.
5. **Não copie** comentários de cursinhos nem questões de sites pagos. As questões são inéditas; você pode se inspirar no estilo da banca.

## Estilo FAFIPA

A FAFIPA cobra **letra de lei**. Enunciados típicos:
- "Com base no art. X da Lei nº Y, assinale a alternativa correta."
- "Assinale a alternativa INCORRETA" (use com moderação, e escreva INCORRETA/NÃO em maiúsculas).
- Afirmativas I, II, III e IV, com alternativas de combinação ("Somente I e III estão corretas").
- Caso concreto curto seguido de "à luz do art. X / da tese do Tema Y".

Alternativas erradas boas trocam **um** detalhe verificável: prazo, competência, quórum, "sempre/nunca", sujeito, efeito ex tunc/ex nunc. Nada de alternativa absurda que ninguém marcaria.

Se existir [docs/estilo-fafipa.md](estilo-fafipa.md), leia: é a análise de provas reais da banca.

## Formato do arquivo

- Formato: [tools/questao.schema.json](../tools/questao.schema.json). Exemplos completos: `app/assets/questoes/adm/adm-07.json` e `adm-15.json`.
- Um arquivo por item do Anexo II: `app/assets/questoes/<materia>/<materia>-NN.json`, com `NN` = número do item (dois dígitos) e `unidade.itemEdital` = o mesmo número.
- IDs de questão: `<materia>-0001`, `<materia>-0002`... em sequência, **nunca reutilizados**.
- `origem`: `{"tipo": "inedita"}`.
- `fontes`: cada norma ou precedente usado, com a **data** (da lei, da súmula ou do julgamento da tese). Nada depois de 2026-09-21.

## Padrão de explicação

Cada uma das 5 alternativas tem explicação própria, e o validador reprova explicação com menos de 60 caracteres.
- **Correta:** cite o dispositivo exato (artigo, parágrafo, inciso) e diga o que ele estabelece; se ajudar, uma frase sobre a razão da regra.
- **Erradas:** diga **qual detalhe** está errado e qual é o certo, com o dispositivo. Aponte a pegadinha ("o número 180 aparece no § 1º, e é uma pegadinha comum").
- **Dica:** orienta sem entregar. Nunca cite a letra da resposta (o validador reprova "alternativa B").

## Gabarito

Distribua as respostas entre A, B, C, D e E. O validador avisa se uma letra passar de 35% numa matéria com 20 ou mais questões.

## Antes de entregar

```bash
python tools/validar_questoes.py app/assets/questoes/
```

O banco inteiro tem que passar. Não faça commit: quem revisa e commita é a sessão principal.
