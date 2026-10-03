# Status do PasseiDireito

Atualizado em 03/10/2026. Leia junto com o [CLAUDE.md](../CLAUDE.md).

## Onde estamos

**Prioridade:** MVP da prova objetiva (13/12/2026). Discursiva com IA e a segunda leitura ficam para depois da prova, por decisão do Gustavo.

**Repositório público desde 02/10/2026:** https://github.com/gustavoanderson/PasseiDireito (decisão do Gustavo — ver pergunta/resposta no chat de 02/10).

**Duas formas de acesso, sempre atualizadas:**
- **Navegador (web):** https://gustavoanderson.github.io/PasseiDireito/ — hospedado no GitHub Pages, a partir da branch órfã `gh-pages` (só o `build/web`, não o código-fonte). Pra publicar uma versão nova: `cd app && MSYS_NO_PATHCONV=1 flutter build web --release --base-href /PasseiDireito/` (no Git Bash do Windows, o `MSYS_NO_PATHCONV=1` evita que `/PasseiDireito/` seja lido como caminho de arquivo), depois copiar `app/build/web/*` pra um worktree da branch `gh-pages` (primeira vez: `git worktree add --detach /tmp/gh-pages-wt` + `git checkout --orphan gh-pages`; nas seguintes: `git worktree add --detach /tmp/gh-pages-wt gh-pages`, apagar o conteúdo antigo, copiar por cima, commitar). **Pegadinha:** o worktree fica em HEAD destacado, então `git push` sozinho não sabe pra onde mandar — use `git push origin HEAD:gh-pages`. O Pages já está habilitado, não precisa reconfigurar.
- **Android (APK), versão atual v0.5:** https://github.com/gustavoanderson/PasseiDireito/releases/download/v0.5/PasseiDireito-v0.5.apk. A cada nova versão, criar uma Release nova (`gh release create vX.Y caminho/do.apk --title ... --notes ...`) e atualizar este link aqui e no CLAUDE.md.

**O app (v0.5, commitado e buildado em 03/10/2026):**
- Trilhas por matéria, simulado cronometrado, caderno de erros, desempenho, flag "MUDANÇA NA LEI", login Firebase, modo claro/escuro.
- **Novo em 03/10:** contador regressivo pra prova objetiva na tela inicial ("Faltam N dias... · 13/12/2026"; pedido do Gustavo). `diasAte()` e `TelaInicio.hoje` em `app/lib/tela_inicio.dart`.
- **Logo corrigida em 03/10, em duas rodadas** (pedidos do Gustavo), em `app/lib/logo.dart`: (1) o martelo batia com o meio da cabeça, não com a ponta — recalculado o giro pra a face direita (a ponta) cair no centro da fagulha; a fagulha tinha uma camada vermelho-terracota — trocada por âmbar. (2) o martelo ainda batia na diagonal (38°) — agora gira 90°, batendo reto numa superfície horizontal; acrescentadas três linhas de movimento acima da cabeça; e a fagulha perdeu de vez a cor — as três camadas da estrela ficaram brancas, só com contorno. Ícones do Android e da web regerados a cada rodada (`flutter test tool/gerar_icones_test.dart --update-goldens`).
- APK em `D:\repositorio\PasseiDireito-v0.5.apk` (50 MB), com **445 questões**. Ainda não foi testado em celular de verdade.
- Suíte inteira verde: validador do banco, 5 suítes de testes Python, `flutter analyze` e `flutter test` (78 testes).
- Em 02/10: 4 commits (correção do extrator federal, correção da base de Curitiba, +150 questões, documentação). Em 03/10: repositório publicado, versão web publicada, contador regressivo, logo corrigida (v0.2 → v0.5).

| Matéria | Questões | Peso no edital | Questões/peso |
|---|---|---|---|
| Administrativo | 96 | 22 | 4,4 |
| Constitucional | 71 | 19 | 3,7 |
| Tributário | 89 | 19 | 4,7 |
| Processo Civil | 80 | 19 | 4,2 |
| Urbanístico/Ambiental | 36 | 7 | 5,1 |
| Trabalho | 22 | 5 | 4,4 |
| Previdenciário | 17 | 3 | 5,7 |
| Penal | 17 | 3 | 5,7 |
| Empresarial | 17 | 3 | 5,7 |

Proporção equilibrada entre matérias (3,7 a 5,7 questões por ponto de peso). Decisão de 02/10: parar de expandir volume por ora (já passou de 300, a meta original) — próxima vez, Constitucional e Processo Civil são as que têm menor razão questões/peso.

**Pendências abertas, para a próxima sessão:**
- **Matinhos:** checar fundacaofafipa.org.br/informacoes/4197 (prazo 07/10/2026 às 23h59 para o caderno).
- Duas lacunas de ferramenta na base de Curitiba (Lei 1.656/1958 arts. 102-269; Decreto 868/2024 Anexo) — sem questão exposta hoje, mas não escrever questão nova nesses trechos.
- Duas pendências jurídicas sem fonte firme (lei-15042-2017 art. 5º; lei-7671-1991 art. 2º "f").
- Artigos federais "conferir" (sem nota de redação em nenhuma versão): l14133 arts. 37 e 54; l13709 art. 62; l8213 art. 60; l13869 arts. 3, 9, 13, 15, 16, 20, 30, 32, 38, 43; l13465 art. 16.
- APK nunca testado num celular real.

## O que aconteceu em 01/10/2026

1. **Leva de volume (agentes).**
   - **Tributário: +40 (trib-0050 a 0089).** Inclui o Código Tributário de Curitiba, transação, LRF, precatórios e ITBI.
   - **Processo Civil: +35 (pc-0046 a 0080).** Sete delas sobre a Lei 15.484/2026, todas com alerta.
   - **Administrativo: +30.** O agente foi interrompido pelo limite de uso no meio do trabalho, mas o que ele gravou passa no validador.
   - **Constitucional: 0.** O agente parou antes de gravar.
2. **Prova da PGM Matinhos (FAFIPA, 27/09/2026).**
   - Já baixado: o gabarito preliminar de Procurador (código 8715). Página do concurso: fundacaofafipa.org.br/informacoes/4197.
   - **O caderno não é público.** Só sai na "área do candidato", até **07/10/2026 às 23h59**. Perguntei ao Gustavo se a Flávia ou algum conhecido fez a prova. **Aguardando resposta.**
3. **Descoberta grave: o texto compilado do Legisladoc pode estar desatualizado.**
   - A LC 108/2017 (ITBI) aparecia sem as LCs 134/2022 e 148/2025. A LC 40/2001 (Código Tributário) aparecia sem a LC 134/2022.
   - Criado o `corpus/correcoes_curitiba.json`, aplicado pelo `montar_corpus_curitiba.py` (função `aplicar_correcoes`, com teste em `tools/test_montar_corpus_curitiba.py`).
   - **LC 108/2017: corrigida.** Ela foi acrescentada ao corpus.
   - **LC 40/2001 e as demais: falta a auditoria.**
4. **Novo defeito do extrator federal — corrigido e auditado em 02/10/2026.**
   - O Planalto deixa sem risco a redação antiga de um inciso ou parágrafo. No CPC, o art. 988 tem dois incisos III, dois IV e dois § 5º. Corrigido com `_sem_dispositivo_repetido` em `tools/fatiar_lei.py`.
   - **A própria correção tinha um bug:** o regex do rótulo confundia "I-A" (inciso com letra colada) com "I" puro por causa de retrocesso (*backtracking*), e isso apagou o "I - o Supremo Tribunal Federal" do art. 92 da CF. Corrigido com dois ramos separados no regex (ver `tools/fatiar_lei.py`).
   - **Corpus federal reconstruído e auditado.** `python tools/montar_corpus.py` rodou sem problemas. Script de auditoria comparou os 62 arquivos contra o commit anterior: **113 artigos mudaram, 0 suspeitos** (toda linha removida tinha rótulo duplicado de verdade no texto antigo). Testes: `tools/test_fatiar_lei.py` (26 casos, incluindo os dois novos: art. 988 e art. 92).
   - Ficaram para **conferir manualmente** (duas versões do mesmo rótulo, nenhuma com nota de redação): l14133 arts. 37 e 54; l13709 art. 62; l8213 art. 60; l13869 arts. 3, 9, 13, 15, 16, 20, 30, 32, 38, 43; l13465 art. 16.

## Próximos passos (em ordem)

0. **Matinhos, pedido do Gustavo em 01/10 (prazo 07/10/2026 às 23h59).** Checado em 02/10, de manhã: ainda só o gabarito preliminar. Nada novo. Verificar de novo ao retomar.

1. ~~Teste do extrator e reconstrução do corpus federal.~~ **Feito em 02/10** (ver acima).
2. **Auditoria de Curitiba — concluída a 1ª leva, continuando (`a34d92637e5d6df55`).**
   - **LC 40/2001 (Código Tributário): achado grave.** O IPTU inteiro (arts. 35 a 43, a base de cálculo, as alíquotas E as regras de "imóvel não edificado") foi reescrito duas vezes (LC 136/2022 e LC 149/2025) e o compilado do Legisladoc trazia a redação de 2001/2014. Corrigido em `correcoes_curitiba.json` (21 artigos). Também corrigidos: art. 22 (notificação/DEC), art. 26 (multas, agora LC 146/2025), art. 80 (parcelamento do IPTU).
   - **Lei Orgânica (lom): 11 artigos divergentes** (ELO 24/2024 e 25/2025, como já suspeitávamos). Corrigido.
   - **Achado novo, ainda pendente:** a Lei 1.656/1958 (Estatuto dos Funcionários) só está compilada até o art. 101 — os arts. 102 a 269 só existem na redação ORIGINAL de 1958, sem nenhuma atualização. É um buraco de ferramenta (o Legisladoc não fecha o bloco "Alterado" direito para esta lei), não corrigido ainda. **Checado: as duas questões do banco que citam essa lei (adm-0083, adm-0084) só usam artigos até o 101, então não estão expostas.** Não escrever questões com artigos 102-269 dessa lei até isso ser resolvido.
   - Conferidas sem divergência: lc-141-2023, dec-2305-2023, dec-2306-2023, lc-101-2017, lei-10235-2001.
   - **Auditoria concluída em 02/10/2026.** As 23 normas "Alterado" restantes foram conferidas. 11 tinham divergência e foram corrigidas: lc-133-2021 (RPPS — faltava a segregação de massa inteira da LC 147/2025), lei-16466-2024, lei-16538-2025, dec-1106-2024, dec-701-2023, dec-1206-2023, dec-380-2023, lei-15072-2017, lei-7671-1991, lei-11095-2004, lei-9806-2000. Total: **14 normas de Curitiba corrigidas** desde ontem.
   - **Nenhuma questão do banco precisou de correção** por causa dessas 11 — conferido por varredura. As questões de Previdenciário que usam a LC 133/2021 (prev-0009 a 0014) já tinham sido escritas direto da fonte oficial, batendo com a correção.
   - **Dois buracos de ferramenta, não de dado, registrados e não corrigidos** (baixo risco, nenhuma questão os usa hoje): Lei 1.656/1958 arts. 102-269 (só a parte "Alterado" do Legisladoc é capturada, falta o resto) e Decreto 868/2024 arts. 34/43 (ficam num Anexo/Regimento Interno que o HTML baixado não traz).
   - **Duas pendências jurídicas sem fonte firme para resolver agora:** lei-15042-2017 art. 5º (pode estar revogado por condição da LC 147/2025, sem data de implantação confirmada) e lei-7671-1991 art. 2º, "f" (possível duplicidade obsoleta).
3. ~~Revisar as questões de IPTU afetadas.~~ **Feito em 02/10, conferido.** trib-0054 (fontes corrigidas, gabarito não mudou), trib-0055 (reescrita quase inteira — art. 42 virou incisos I-V), trib-0056 (afirmativa II reescrita — hotéis/hospitais agora têm redução de 40%, não mais "alíquota de residencial") e trib-0060 (só a fonte). Validador: 435 questões, 0 erros. Conferi trib-0055 e trib-0056 à mão contra o corpus: batem.
4. ~~Constitucional: +35.~~ **Feito em 02/10.** Banco foi de 36 para 71 questões (const-0037 a 0071). INCORRETA subiu para 51%. Nenhuma questão nova usa artigo de Curitiba que a auditoria tenha corrigido (todas conferidas contra `lom.json` antes de usar).
5. ~~Administrativo: completar a leva.~~ **+10 em 02/10** (adm-0095 a 0104, nos itens que tinham só 3 questões). Banco: 445 questões, validador verde. Conferi adm-0097 e adm-0102 à mão: batem com o corpus.
6. **Matinhos.** Se o caderno chegar até 07/10, adaptar as questões com `origem: {"tipo":"adaptada","prova":"FAFIPA 2026, PGM Matinhos/PR"}`.
   - Tirar as questões de lei municipal de Matinhos.
   - Usar o gabarito definitivo e excluir as anuladas.
7. ~~Commit e APK.~~ **Feito em 02/10, à tarde.** Suíte inteira verde (validador, 5 suítes de testes Python, `flutter analyze` e `flutter test` — 73 testes). 4 commits (extrator, Curitiba, banco de questões, documentação). APK em `D:\repositorio\PasseiDireito-v0.2.apk` (52 MB), com 445 questões.

## Dúvidas jurídicas registradas pelos agentes (para a revisão)

- **trib-0060 e trib-0065:**
  - A LC 40/2001 dá 30 dias para impugnar, com redução de multa de 50% ou 25%.
  - Pelo CTN com a LC 236/2026, são 20 dias úteis e reduções de 50% ou 40%.
  - Os Municípios têm 2 anos para se adaptar. A questão seguiu a lei municipal.
- **trib-0083:** a obrigação de pequeno valor de Curitiba (R$ 5.181,00, Lei 10.235/2001) fica abaixo do piso do art. 100, § 4º, da CF. A questão não cobra o valor.
- **pc-0052, pc-0058, pc-0074 e pc-0076:** conclusões sistemáticas ou por aplicação subsidiária. Detalhes no relatório do agente de Processo Civil.

## Limites de uso

O limite de sessão derrubou os agentes três vezes. Daqui em diante: no máximo 2 ou 3 agentes ao mesmo tempo, e cada um grava item a item.
