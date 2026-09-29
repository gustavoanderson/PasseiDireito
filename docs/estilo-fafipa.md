# Estilo FAFIPA: como a banca formula questões objetivas para cargos jurídicos

Levantamento feito em 28/09/2026 a partir de provas reais da Fundação FAFIPA, para orientar a produção de questões do PasseiDireito (Procurador do Município de Curitiba, Edital Normativo nº 6/2026).

## 0. Limitações (leia antes)

- **Não consegui nenhum caderno de questões de 2024–2026.** A FAFIPA não publica o caderno na página pública do concurso. O caderno fica só na "Área do Candidato", que exige login, por prazo curto. Exemplos:
  - Araucária, Edital 013/2025, art. 4º: "Os Cadernos de Questões ficarão disponíveis para download na 'Área do Candidato', do dia 27/01/2025 até às 23h59min do dia 05/02/2025".
  - Curitiba, Edital 6/2026, item 12.1: o caderno fica disponível por 10 dias corridos.

  O link chamado "Divulgação do gabarito preliminar, caderno de questões e prazo para recurso" leva sempre ao edital de divulgação, nunca ao caderno. Conferi isso em cerca de 40 concursos.
- Os agregadores públicos também não deram acesso:
  - QConcursos: HTTP 403.
  - Gran Questões: Cloudflare e login.
  - Gabarite: o download redireciona para cadastro.
  - Fonte Concursos: a página não tem o arquivo.
  - PCI Concursos, JC Concursos e Ética Concursos: o acervo de provas da FAFIPA para cargos jurídicos para em 2016–2021.
- **Por isso, a análise de estilo usa 9 cadernos reais de 2016–2021** (cargos de procurador, advogado e assessor jurídico), baixados da Ética Concursos.
- Para 2024–2026, usei os **documentos oficiais da FAFIPA**: gabaritos definitivos e pareceres de recursos deferidos. Eles servem para contar anulações e ver os motivos, mas não mostram o texto das questões.
- **Ponto a favor da representatividade:** a prova de Procurador de Foz do Iguaçu **2026** (80 questões) tem os mesmos 8 blocos de matéria da prova de Foz do Iguaçu **2019**, cujo caderno analisei. As colunas DA, DC, DPC, DTF, LEG, DTPT, DCEC e DAU aparecem no Edital 20.001/2026. Isso sugere que o modelo de prova se manteve.
- As contagens de formato foram feitas por script com heurísticas sobre o texto extraído e depois revisadas por amostragem. Trate os números como **aproximados**.

Os arquivos (PDF e .txt) estão no scratchpad da sessão, em `...\scratchpad\fafipa\`:
- `old\`: cadernos e gabaritos de 2016–2021;
- `recent\`: gabaritos e pareceres de 2024–2026;
- raiz: Araucária 2025 e o Edital de Curitiba.

---

## 1. Provas analisadas

### 1.1 Cadernos completos (texto das questões analisado)

| # | Concurso | Ano | Cargo | Nº questões (jurídicas analisadas) | Alternativas | Anuladas (cargo) | Fonte |
|---|---|---|---|---|---|---|---|
| 1 | Câmara de Cambará-PR | 2016 | Procurador Jurídico | 60 (60) | A–D | 0 (gabarito definitivo) | https://eticaconcursos.com.br/provas/fafipa-2016-camara-de-cambara-pr-procurador-juridico |
| 2 | Fundação Araucária-PR | 2017 | Advogado | 50 (50) | A–D | 0 | https://eticaconcursos.com.br/provas/fafipa-2017-fundacao-araucaria-pr-advogado |
| 3 | Pref. Bandeirantes-PR | 2017 | Advogado | 30 (21) | A–D | 0 | https://eticaconcursos.com.br/provas/fafipa-2017-prefeitura-de-bandeirantes-pr-advogado |
| 4 | Câmara de Campina Grande do Sul-PR | 2018 | Advogado | 30 (15) | A–D | 2 (Q14 informática; Q30 específica) | https://eticaconcursos.com.br/provas/fafipa-2018-camara-de-campina-grande-do-sul-pr-advogado |
| 5 | CREA-PR | 2019 | Agente Profissional – Advogado | 50 (35) | A–E | não verificável (só obtive o gabarito preliminar) | https://eticaconcursos.com.br/provas/fafipa-2019-crea-pr-agente-profissional-advogado |
| 6 | **Pref. Foz do Iguaçu-PR** | 2019 | **Procurador do Município Júnior** | **80 (80)** | A–E | 2 (Q42, Q76), pelo gabarito definitivo (Anexo II do Edital 002/08/18/2019) | https://eticaconcursos.com.br/provas/fafipa-2019-prefeitura-de-foz-do-iguacu-pr-procurador-do-municipio-junior |
| 7 | IPREV Nova Esperança-PR | 2019 | Advogado | 40 (20) | A–E | 0 | https://eticaconcursos.com.br/provas/fafipa-2019-prefeitura-de-nova-esperanca-pr-advogado |
| 8 | Câmara de Novo Horizonte do Sul-MS | 2021 | Assessor Jurídico | 50 (30)* | A–E | 0 | https://eticaconcursos.com.br/provas/fafipa-2021-camara-de-novo-horizonte-do-sul-ms-assessor-juridico |
| 9 | Pref. Brasilândia-MS | 2021 | Advogado | 30 (15) | A–D | 0 | https://eticaconcursos.com.br/provas/fafipa-2021-prefeitura-de-brasilandia-ms-advogado |

\* As questões 41–50 de Novo Horizonte (redação oficial) ficaram fora da contagem jurídica.

**Total analisado: 326 questões jurídicas.** A prova de Foz 2019 é a mais próxima do cargo de Curitiba: procurador municipal, 80 questões e 5 horas de prova. Ela foi lida integralmente.

### 1.2 Provas de 2024–2026: só gabarito definitivo e pareceres (caderno NÃO obtido)

| Concurso | Ano | Cargo | Nº questões | Anuladas | Gabarito alterado | Gabarito definitivo (fonte oficial) |
|---|---|---|---|---|---|---|
| Pref. Araucária-PR (Ed. 300/2024) | 2025 | Procurador do Município | 80 | **5** (Q5, 6, 11, 12, 65) | – | https://anexos.cdn.selecao.net.br/uploads/281/concursos/4027/anexos/0850bc7e-238a-48a2-8850-330be6fcc73f.pdf |
| FOZPREV (Foz do Iguaçu) | 2025 | Procurador Jurídico | 40 | 2 (Q28, 31) | Q24 → C | https://anexos.cdn.selecao.net.br/uploads/281/concursos/4026/anexos/3fe9033e-60d6-440a-a11c-017ce8a454e5.pdf |
| Câmara de Guarapuava-PR | 2025 | Advogado | 40 | 1 (Q32) | – | https://anexos.cdn.selecao.net.br/uploads/281/concursos/4038/anexos/d1e00324-5801-4762-984c-ca66a8be8ee5.pdf |
| Pref. São Mateus do Sul-PR | 2025 | Advogado | 40 | 1 (Q17, conhecimentos comuns) | – | https://anexos.cdn.selecao.net.br/uploads/281/concursos/4042/anexos/7660752a-dc77-4fb6-899c-c042a3ecb212.pdf |
| São João PREV (IPSJBV-SP) | 2025 | Procurador | 40 | **3** (Q3, 8, 10) | – | https://anexos.cdn.selecao.net.br/uploads/281/concursos/4060/anexos/b19b6534-e6c6-4600-aafe-9bc0b6df665e.pdf |
| Câmara de Candói-PR | 2025 | Advogado | 40 | 1 (Q36) | – | https://anexos.cdn.selecao.net.br/uploads/281/concursos/4062/anexos/7cc8251e-1d15-4774-bfdb-26c3c64302a7.pdf |
| Fundação Araucária-PR | 2025 | Procurador | 50 | 1 (Q49) | Q12 → C | https://anexos.cdn.selecao.net.br/uploads/281/concursos/4067/anexos/c09aa19f-f201-4b9c-8e1b-f6fc4e850b3f.pdf |
| Câmara de Pinhais-PR | 2025 | Advogado | 50 | 1 (Q44) | – | https://anexos.cdn.selecao.net.br/uploads/281/concursos/4082/anexos/5abe95d2-b1a6-48c2-8869-d530d3e219b4.pdf |
| Câmara de Campo Mourão-PR | 2025 | Procurador Jurídico | 40 | 0 | – | https://anexos.cdn.selecao.net.br/uploads/281/concursos/4092/anexos/99457b88-0192-4991-81c0-d042ef7c6f45.pdf |
| Câmara de Paiçandu-PR | 2024 | Advogado | 30 | 0 | – | https://anexos.cdn.selecao.net.br/uploads/281/concursos/4010/anexos/76bd2e56-28fa-47b2-9bf8-e36444823095.pdf |
| Pref. Rio Branco do Sul-PR | 2026 | Procurador | 50 | 1 (Q37) | – | https://anexos.cdn.selecao.net.br/uploads/281/concursos/4142/anexos/68d65349-5145-4715-a854-e4d11902d6b3.pdf |
| **Pref. Foz do Iguaçu-PR** | 2026 | **Procurador do Município Júnior** | 80 | 2 (Q28, 34) | – | https://anexos-r2.selecao.net.br/uploads/281/concursos/4170/anexos/3c2d26a6-1170-4f3b-a28d-e128a327dbf7.pdf |
| Câmara de Cianorte-PR | 2026 | Advogado | 40 | 0 | Q9 → A | https://anexos-r2.selecao.net.br/uploads/281/concursos/4172/anexos/bbaf4ed3-59b9-47cc-bbe3-8133de9335b7.pdf |
| Câmara de Jaguariaíva-PR | 2026 | Advogado | 50 | só o gabarito preliminar foi publicado | – | https://anexos-r2.selecao.net.br/uploads/281/concursos/4192/anexos/cb5af062-03aa-4c71-9e66-f91cdfe6fa63.pdf |
| Pref. Matinhos-PR (PGM) | 2026 | Procurador Municipal | **100** | gabarito preliminar publicado em 28/09/2026 | – | https://anexos-r2.selecao.net.br/uploads/281/concursos/4197/anexos/e7fe936b-a20d-43f8-ae61-117fef6e0a47.pdf |

**Resumo das anulações (13 provas com gabarito definitivo, 620 questões):** 18 anuladas (cerca de 2,9%) e 3 gabaritos alterados. Nas provas grandes de procurador a taxa é maior: Araucária 2025 teve 5/80 (6,3%) e São João PREV 2025 teve 3/40 (7,5%).

**Concursos pedidos que não consegui:** não obtive o caderno de nenhuma prova de 2024–2026. Isso inclui Foz 2026, Rio Branco do Sul 2026, Fundação Araucária 2025, Matinhos 2026 e Araucária 2025. O motivo está na seção 0.

---

## 2. Formatos de enunciado e frequência (326 questões jurídicas, 2016–2021)

| Formato | Frequência aproximada | Observação |
|---|---|---|
| **Alternativa única ("assinale a alternativa CORRETA/INCORRETA")** | **cerca de 86%** | É o formato dominante. |
| Afirmativas I, II, III… com combinações ("Apenas I e III estão corretas", "Todas…", "Nenhuma…") | cerca de 10% no geral; **cerca de 25% em Foz 2019 (procurador)** | Na prova de procurador, é o segundo formato mais usado. |
| Verdadeiro/Falso com sequência ("( ) … Assinale a sequência CORRETA: V, F, V…") | cerca de 2,5% | Aparece sobretudo em legislação municipal e tributária (Foz Q53, Q59, Q65; Cambará Q41, Q47, Q53). |
| Correlação/associação ("I. Formal – II. Material…", "Anulação; Encampação e Caducidade") | cerca de 1% | Novo Horizonte 2021, Q16, Q31, Q40 e Q42. |
| Caso concreto curto (personagens: Antônio, Tibúrcio, Rosa e Laura, "BBB e JJJ", Tício) | cerca de 4–6% | Quase sempre com resposta de letra de lei ou súmula (ex.: MS sem efeitos patrimoniais pretéritos). |
| Pergunta direta com resposta curta ("Qual é o prazo…?", "NÃO pode propor ADI:") | cerca de 14% | Frequente em prazos, quóruns e rol de legitimados. |

**Polaridade do comando:** CORRETA em cerca de 40%; INCORRETA, EXCETO ou NÃO em **cerca de 46%**; direta (sem polaridade) em cerca de 14%. A polaridade vem sempre em **CAIXA ALTA** (CORRETA, INCORRETA, EXCETO, NÃO), e as provas pedem o INCORRETO com frequência um pouco maior.

**Fórmulas de enunciado recorrentes (texto literal):**
- "Com relação a …, assinale a alternativa CORRETA."
- "Sobre …, é INCORRETO afirmar que:"
- "De acordo com o artigo X da Lei Y, …" / "Segundo a literalidade do caput do artigo 69 da Lei 13.019/2014 …" / "conforme estritamente disposto nos artigos 155 a 158 da CLT"
- "Analise as assertivas e assinale a alternativa CORRETA." / "Considerando as proposições acima, assinale a alternativa CORRETA:"
- "todas as alternativas abaixo …, EXCETO:"
- Preâmbulo expositivo antes do comando: uma citação doutrinária ou a transcrição de um artigo, seguida de "Sobre o tema, assinale…". Isso aparece em 5 das 15 questões de Processo Civil de Foz 2019.

**Número de alternativas:** 4 (A–D) até 2018 e em algumas provas menores de 2021. A partir de 2019, nas provas maiores, são 5 (A–E). O Edital de Curitiba 6/2026 (item 11.22) fixa **100 questões com 5 alternativas**, 5 horas de prova e aprovação com 60/100 pontos.

---

## 3. Letra de lei x jurisprudência x doutrina

- **Letra de lei domina.** Cerca de 52% dos enunciados citam expressamente o diploma, o artigo ou a expressão "nos termos de/de acordo com". Nas demais questões, as alternativas também são quase sempre paráfrases de dispositivos legais. Estimativa: **70–80% das questões se resolvem por letra de lei ou da Constituição.** Vários enunciados exigem literalidade: "considerando a literalidade da lei", "segundo o contido literalmente no art. 3º", "conforme estritamente disposto".
- **Jurisprudência:** cerca de 10% das questões mencionam STF, STJ, súmula ou "entendimento jurisprudencial" (31/326). Em Foz 2019 (procurador) essa fatia sobe para cerca de 18% (14/80). A jurisprudência cobrada é **consolidada/sumulada**, e não precedentes recentes. Exemplos:
  - MS e efeitos patrimoniais pretéritos (Súmulas 269/271);
  - "casa" para fins de inviolabilidade de domicílio;
  - HC contra impeachment;
  - corte de serviço essencial (STJ);
  - cláusulas pétreas implícitas.
- **Doutrina:** cerca de 12% (40/326), em dois usos:
  1. **Classificações clássicas**: José Afonso da Silva (eficácia das normas), classificação das Constituições (Loewenstein, "granítica", "silenciosa"), gerações de direitos, métodos de interpretação (Hesse, Müller, Häberle, Smend, Viehweg) e bens de uso especial.
  2. **Citação decorativa no preâmbulo** (Humberto Theodoro Jr., Leonardo Greco, Marinoni/Arenhart/Mitidiero), seguida de pergunta sobre a lei. A banca chega a avisar: "levando em conta o que está estabelecido no CPC/2015 (e não eventuais interpretações doutrinárias)" (Foz 2019, Q22).
- **Legislação local pesa muito.** Em Foz 2019, 15/80 questões (19%) eram só de Lei Orgânica, Código Tributário Municipal e Estatuto dos Servidores de Foz, além de ITBI e ISS pelo CTM em Tributário. O Edital de Curitiba repete o padrão no conteúdo programático: cobra a Lei Orgânica de Curitiba (Lei 5.700/1977), a Lei Municipal 11.001/2004 e a Constituição do Paraná. **Recomendação:** tratar a legislação municipal de Curitiba como matéria de peso, cobrada em V/F e em "Analise as assertivas".

---

## 4. Temas mais cobrados por matéria

Baseado nos 9 cadernos. Entre parênteses, as provas em que o tema apareceu.

**Direito Administrativo**
- Princípios do art. 37 (LIMPE), inclusive a troca de um princípio por outro (Foz 2019, FA 2017, Cambará 2016).
- **PPP (Lei 11.079/2004)**: valor mínimo, prazo de 5 a 35 anos e garantias. Apareceu em 3 provas diferentes (Cambará Q16–17, FA Q12, Foz Q5).
- Licitações: modalidades, prazos, dispensa x inexigibilidade (8.666 e pregão nas provas antigas; hoje a referência seria a Lei 14.133/2021).
- Atos administrativos: anulação, revogação, convalidação, motivos determinantes, atributos e espécies.
- Responsabilidade civil do Estado (art. 37, §6º; teorias do risco).
- Improbidade: tipos e prescrição (texto antigo da LIA nas provas pré-2021).
- Administração indireta (autarquias, agências reguladoras, regime de direito público).
- Concessões (encampação, caducidade, intervenção).
- Servidores: estabilidade, acumulação e teto (art. 37), estatuto municipal (PAD, sindicância, prescrição).
- Processo administrativo (Lei 9.784/99), poder de polícia, bens públicos e DL 201/67 (2 provas).

**Direito Constitucional**
- Controle de constitucionalidade: ADI, legitimados, cautelar, modulação por 2/3, reserva de plenário, intervenção de terceiros.
- Remédios constitucionais: MS (Lei 12.016), HD, HC, MI (Lei 13.300).
- Poder constituinte e reforma: quórum de 3/5, dois turnos, limites circunstanciais, cláusulas pétreas.
- Eficácia das normas (José Afonso da Silva) e classificação das Constituições.
- Direitos fundamentais: gerações, domicílio, art. 5º.
- Organização dos Poderes: competências privativas de Câmara, Senado e CN; medida provisória (vedações); processo legislativo.
- **Município na CF**: art. 29 (lei orgânica: dois turnos, interstício de 10 dias, 2/3), número de vereadores, intervenção do art. 35.
- Hermenêutica constitucional (métodos).

**Direito Processual Civil** (o bloco mais longo: 15/80 em Foz 2019 e 2026)
- **Tutelas provisórias** (em praticamente todas as provas): requisitos, caução, estabilização, prazos de aditamento de 15 e 30 dias, tutela de evidência.
- Competência: absoluta x relativa, foros especiais, conexão e continência.
- Recursos: cabimento de agravo x apelação, efeito suspensivo, desistência, preparo da Fazenda.
- **Fazenda Pública em juízo**: prazo em dobro, cadastro eletrônico, honorários, embargos em 30 dias, remessa necessária.
- Reconvenção, audiência de conciliação (multa de 2%), saneamento, AIJ, provas, petição inicial e improcedência liminar, litisconsórcio, intervenção de terceiros, IDPJ, IRDR e execução.

**Direito Tributário**
- Conceito e espécies de tributo (art. 3º do CTN) e competência tributária.
- Crédito tributário: extinção x exclusão x suspensão.
- Responsabilidade tributária, denúncia espontânea (multas punitivas x moratórias), imunidades.
- Impostos municipais: **ISS, ITBI e IPTU**, inclusive pelo Código Tributário Municipal.
- Execução fiscal (LEF), MS e ação declaratória em matéria tributária, processo administrativo fiscal (prazo de impugnação em caso concreto).

**Direito Financeiro**
- Princípios orçamentários: exclusividade e suas exceções, anualidade, universalidade, unidade, não vinculação.
- PPA, LDO e LOA: iniciativa, vigência e conteúdo.
- LRF: limite de despesa com pessoal do Município (60%), operações de crédito, receita e despesa.
- Emendas impositivas (1,2% da RCL, metade para a saúde), cobradas via Lei Orgânica.

**Legislação municipal**
- Lei Orgânica: competências da Câmara e do Prefeito, processo legislativo, emenda à LO, transição de mandato, sessões extraordinárias.
- Código Tributário Municipal: cadastro, IPTU, ISS e taxas.
- Estatuto dos Servidores: penalidades, prescrição, PAD e sindicância.

**Demais matérias vistas em prova de procurador**
- Civil: LINDB, pessoas jurídicas, negócio jurídico, obrigações, prescrição e usucapião.
- Trabalho e Processo do Trabalho: vínculo em caso concreto, justa causa, rescisão indireta, competência da Justiça do Trabalho.
- Consumidor e Empresarial.
- Urbanístico e Ambiental: Estatuto da Cidade (plano diretor), PNRS, Lei 6.938/81, Lei de Crimes Ambientais, competência municipal ambiental.

---

## 5. Padrões de pegadinha nas alternativas erradas

1. **Alternativas-espelho com troca numérica.** Em cerca de 11% das questões, 3 ou mais alternativas começam com o mesmo texto e mudam só o número. No bloco de legislação específica de FA 2017 isso chega a 10/50.
   - FA 2017, Q4: prestação de contas em "trinta / sessenta / noventa / cento e vinte dias".
   - FA 2017, Q12: PPP "não inferior a 10/5, nem superior a 25/35 anos".
   - Cambará 2016, Q6: lei orgânica com "dois turnos / um turno", "dez / quinze / trinta dias", "dois terços / maioria absoluta".
   - FA 2017, Q44: licença-maternidade "120/150 dias", "1/2 semanas".
2. **Troca de órgão ou competência.** A banca atribui à Câmara o que é do Senado e ao CN o que é privativo de uma das Casas.
   - FA 2017, Q27(B): "Compete privativamente à Câmara dos Deputados suspender a execução […] de lei declarada inconstitucional" (a competência é do Senado).
   - Cambará 2016, Q9.
3. **Inserção de elemento estranho em rol legal.**
   - Foz 2019, Q1(C) acrescenta "motivação" aos princípios do caput do art. 37.
   - FA 2017, Q15 inclui "Ingresso" como modalidade de licitação.
   - CREA 2019, Q31 inclui "Menor preço" (que é tipo de licitação, não modalidade).
   - Foz 2019, Q42 inclui "parcelamento" como forma de extinção do crédito tributário (é suspensão).
4. **Absolutos.** Em cerca de 40% das questões, alguma alternativa traz "sempre", "nunca", "somente/apenas", "em qualquer hipótese", "em nenhuma hipótese" ou "exclusivamente". Normalmente é essa a alternativa errada.
   - Foz 2019, Q10(A): "responsabilidade objetiva do Estado existe em qualquer hipótese de dano, inclusive decorrente de força maior".
   - Foz 2019, Q34(III): "o juiz deverá sempre julgar antecipadamente a lide".
   - Novo Horizonte 2021, Q25(A): "Será sempre admitida a avocação temporária".
   - CREA 2019, Q30(A): "sempre correspondem a um crime".
   - Cuidado: às vezes o absoluto está **certo** por ser literal ("sempre deverá ordenar o seu afastamento", em estatuto municipal).
5. **Troca de conceitos vizinhos.**
   - Anular x revogar: Foz 2019, Q6(II), "O Poder Judiciário […] não pode anular ato administrativo, apenas revogar".
   - Dispensa x inexigibilidade: Foz 2019, Q9(C/E).
   - Encampação x caducidade x anulação: Novo Horizonte 2021, Q16.
   - Ação exacional x antiexacional: Foz 2019, Q45(B/C).
   - Remissão x remição: Foz 2019, Q42.
   - Eficácia plena x contida x limitada.
   - Ex tunc x ex nunc: Foz 2019, Q19(II).
   - Autorização x permissão x concessão de uso: Novo Horizonte 2021, Q20, em que as alternativas combinam "discricionário/vinculado", "precário/oneroso" e "depende/independe de licitação".
6. **Troca de quórum ou fração.** 3/5 x maioria absoluta (Foz 2019, Q13(II), sobre EC); 2/3 x maioria simples; 1/3 x maioria.
7. **Extrapolação da regra para outro sujeito ou hipótese.**
   - "prazo em dobro para todas as suas manifestações" (Foz 2019, Q31(I)).
   - Estender ao MP a regra da ausência do advogado.
   - Aplicar ao Município o teto dos Ministros do STF sem a ressalva do subsídio do prefeito (Foz 2019, Q54(E), comparada com Q8(E), que traz a ressalva).
8. **Questões quase gêmeas na mesma prova com um detalhe trocado.**
   - Foz 2019, Q19(III) e Q20(D) têm o mesmo texto sobre a intervenção de terceiros em ADI.
   - Foz 2019, Q8(C) (art. 37, V, "direção, chefia e assessoramento") e Q54(D) (Lei Orgânica: "apenas às atribuições de assessoramento").
9. **Combinações de afirmativas.** Normalmente há 5 opções do tipo "Todas / Somente III / Somente I e III / Somente I e II / Nenhuma", repetidas quase idênticas entre questões (Foz 2019, Q14, Q17, Q69, Q72 e Q75). A afirmativa errada costuma ter um único detalhe falso: prazo, quórum ou "sempre".

---

## 6. Enunciados reais curtos por matéria (exemplos de estilo)

**Direito Administrativo**
- "Com relação aos Princípios Constitucionais da Administração Pública, assinale a alternativa CORRETA." (Foz do Iguaçu 2019, Procurador, Q01)
- "De acordo com a Lei nº 11.079/2004, analise as assertivas e assinale a alternativa CORRETA." (Foz 2019, Q05)
- "Em razão de orientação de sua Procuradoria Jurídica, prefeito municipal edita Decreto proibindo a instalação de dois ou mais hipermercados por cada bairro da cidade. O Decreto municipal:" (Foz 2019, Q07)
- "No tocante à prescrição regulada pela lei 8.429 […], assinale a alternativa CORRETA, considerando a literalidade da lei." (Fundação Araucária 2017, Advogado, Q16)
- "No que diz respeito ao encerramento do contrato de concessão, analise as hipóteses abaixo e assinale a alternativa com a sequência correspondente CORRETA:" (Novo Horizonte do Sul 2021, Assessor Jurídico, Q16)

**Direito Constitucional**
- "Sobre a aplicabilidade das normas constitucionais, assinale a alternativa CORRETA." (Foz 2019, Q11)
- "Antônio é detentor de cargo público federal e impetrou mandado de segurança […]. Considerando o caso hipotético acima relatado e a jurisprudência do Supremo Tribunal Federal atinente aos remédios constitucionais, assinale a alternativa CORRETA:" (Foz 2019, Q15)
- "A medida provisória trata-se de espécie normativa voltada a regulamentar questões dotadas de relevância e urgência. Neste sentido, é vedada a edição de medida provisória para a tratativa de todas as matérias constantes nas alternativas abaixo, EXCETO:" (Foz 2019, Q16)
- "De acordo com disposição constitucional contida no art. 29, sobre os municípios, assinale a alternativa CORRETA:" (Cambará 2016, Procurador Jurídico, Q06)
- "NÃO pode propor a ação direta de inconstitucionalidade." (Cambará 2016, Q10)

**Direito Processual Civil**
- "Sobre saneamento do processo, assinale a alternativa INCORRETA, levando em conta o que está estabelecido no CPC/2015 (e não eventuais interpretações doutrinárias):" (Foz 2019, Q22)
- "Sobre as peculiaridades envolvendo a Fazenda Pública Municipal em juízo, considere as proposições abaixo, relativas aos prazos, citações e intimações, partes e procuradores e execução contra a fazenda pública:" (Foz 2019, Q31)
- "Levando em conta exclusivamente as normas previstas no CPC/2015, assinale a alternativa INCORRETA sobre o tema:" (Foz 2019, Q28, tutelas provisórias)
- "Acerca do incidente de desconsideração da personalidade jurídica previsto nos artigos 133 e seguintes do Código de Processo Civil vigente (Lei 13.105/2015), assinale a alternativa INCORRETA." (Cambará 2016, Q35)

**Direito Tributário**
- "Sobre o conceito de tributo e as espécies tributárias, assinale a alternativa CORRETA:" (Foz 2019, Q37)
- "Tibúrcio é dentista no Município de Foz de Iguaçu e em 10 de outubro de 2018 (quarta-feira), foi notificado […]. Sobre a defesa do presente auto de infração, é CORRETO afirmar que:" (Foz 2019, Q47)
- "Sobre o instituto da denúncia espontânea, é CORRETO afirmar que:" (Foz 2019, Q48)
- "É contribuinte do Imposto sobre Serviços de Qualquer Natureza - ISS:" (Cambará 2016, Q42)

**Direito Financeiro**
- "A Lei de Diretrizes Orçamentárias (LDO) estabelece as metas e prioridades da administração pública […]. Sobre o respectivo tema, é INCORRETO afirmar que:" (Foz 2019, Q50)
- "O Plano Plurianual - PPA:" (Cambará 2016, Q48)
- "De acordo com a Lei Complementar 101/2000, é CORRETO afirmar que:" (CREA-PR 2019, Q34; as alternativas trazem 60/65/50/40% da RCL)

**Legislação Municipal**
- "Analise as assertivas e marque (V) para verdadeiro ou (F) para falso no que se refere ao Poder Executivo Municipal, segundo a Lei Orgânica do Município de Foz do Iguaçu." (Foz 2019, Q53)
- "Quanto ao Processo Legislativo previsto na Lei Orgânica do Município de Foz do Iguaçu, é CORRETO afirmar que:" (Foz 2019, Q52)
- "Assinale a alternativa CORRETA no que se refere ao Estatuto dos Servidores Públicos do Município de Foz do Iguaçu." (Foz 2019, Q64)

**Civil / Trabalho / Urbanístico-Ambiental (blocos menores)**
- "Considerando as disposições da Lei de Introdução às Normas do Direito Brasileiro (LINDB), assinale a alternativa INCORRETA:" (Foz 2019, Q71)
- "A rescisão indireta é instituto que reconhece a justa causa da rescisão do contrato de trabalho reclamada pelo empregado contra ato do empregador. […] assinale a alternativa CORRETA:" (Foz 2019, Q68)
- "De acordo com a Constituição Federal de 05 de outubro de 1988, quanto ao poder de legislar sobre questões ambientais, é CORRETO afirmar que é competência dos Municípios:" (Foz 2019, Q80)

---

## 7. Anulações: motivos (texto oficial dos pareceres da FAFIPA)

Os pareceres são padronizados e curtos. Motivos registrados para cargos jurídicos em 2024–2026:

| Motivo oficial | Ocorrências | Onde |
|---|---|---|
| "Erro de formulação, uma vez que a questão **não apresenta alternativa correta**" | **10** | Araucária 2025 (Q6, 11, 12); São João PREV 2025 (Q3, 8, 10); Fund. Araucária 2025 (Q49); Pinhais 2025 (Q44); Rio Branco do Sul 2026 (Q37); Foz 2026 (Q34) |
| "Erro de formulação, uma vez que a questão **apresenta mais de uma alternativa correta**" | 5 | Araucária 2025 (Q5, 65); FOZPREV 2025 (Q28); Guarapuava 2025 (Q32); Foz 2026 (Q28) |
| "inconsistências em seu enunciado" / "não apresenta clareza em seu enunciado" | 2 | FOZPREV 2025 (Q31); Candói 2025 (Q36) |
| "divergência histórica dos fatos, gerando dupla interpretação" | 1 | São Mateus do Sul 2025 (Q17, conhecimentos comuns) |
| "Erro de digitação de gabarito" (gabarito alterado, sem anulação) | 3 | FOZPREV 2025 (Q24→C); Fund. Araucária 2025 (Q12→C); Cianorte 2026 (Q9→A) |

Nos cadernos antigos: em Campina Grande do Sul 2018, a Q14 foi anulada por conteúdo fora do edital (Windows 10) e a Q30 por "omissão em relação ao princípio da publicidade". Em Foz 2019 houve 2 anuladas (Q42 e Q76), mas não obtive o parecer. Na Q76 (Lei 12.305/2010), o texto extraído não permite inferir o motivo. Na Q42, as duas alternativas "completas" incluem "parcelamento" entre as formas de extinção do crédito, o que é compatível com "nenhuma alternativa correta". Isso é inferência minha.

**Inferências (não confirmadas, porque os cadernos recentes não foram obtidos):**
- O defeito mais comum da banca é deixar a questão **sem alternativa correta** (10 de 18). Isso combina com o estilo de afirmativas e de alternativas quase literais: um detalhe trocado a mais ou uma lei desatualizada torna todas erradas. As provas antigas ainda usam a Lei 8.666/93 e o texto original da LIA, antes da Lei 14.230/2021; a desatualização normativa é um risco plausível.
- As anulações se concentram nas provas grandes de procurador (Araucária 5/80, São João PREV 3/40). Nas duas, as anulações vêm em sequência (Araucária Q5–6 e Q11–12; IPSJBV Q3, Q8 e Q10), o que sugere blocos de matéria elaborados pelo mesmo examinador.
- **Consequência para o app:** as questões geradas precisam de conferência rigorosa de vigência legal (14.133/2021, 14.230/2021, EC 132/2023 etc.) e de unicidade do gabarito. É exatamente onde a banca erra.

---

## 8. Recomendações práticas para o gerador de questões do PasseiDireito

1. **Padrão:** alternativa única com 5 alternativas (A–E) e comando em caixa alta ("assinale a alternativa CORRETA" / "é INCORRETO afirmar que:"). Distribuir a polaridade em cerca de 45% INCORRETA/EXCETO, cerca de 40% CORRETA e o restante em pergunta direta.
2. **Incluir cerca de 20–25% de "Analise as assertivas I–IV/V"**, com alternativas no molde "Somente I e III estão corretas" / "Todas" / "Nenhuma", e alguns itens de V/F com sequência (sobretudo em legislação municipal).
3. **Ancorar no texto legal:** a alternativa correta deve ser paráfrase fiel do dispositivo. As erradas devem trocar um único elemento (prazo, quórum, órgão competente, "sempre/apenas", conceito vizinho ou elemento estranho no rol).
4. **Jurisprudência só consolidada** (súmulas e teses conhecidas), em cerca de 10–20% das questões. Doutrina só para classificações clássicas ou como preâmbulo.
5. **Reservar peso relevante à legislação de Curitiba** (LO 5.700/1977, Lei 11.001/2004, Código Tributário e Estatuto municipais) e à Constituição do Paraná, como fez Foz (cerca de 19% da prova).
6. **Caso concreto curto** com personagem nomeado em cerca de 5% das questões, sempre com solução por letra de lei ou súmula.
