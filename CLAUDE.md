# CLAUDE.md

Contexto do PasseiDireito. Leia antes de qualquer tarefa neste repositório.

---

## O que é

App de estudo gamificado, no formato do Duolingo, para **uma única aluna**: a **Flávia**, noiva do Gustavo, que vai prestar o concurso de **Procurador do Município de Curitiba** (Edital Normativo nº 6/2026, banca FAFIPA, publicado em 21/09/2026).

Android primeiro, web em seguida. O mesmo código Flutter gera os dois.

## Como trabalhar com o Gustavo

As regras do [CLAUDE.md do DevLingo](../DevLingo/CLAUDE.md) valem aqui também. As que mais pesam:

1. **Seja didático.** Explique o porquê de cada decisão, não só o resultado.
2. **Nunca avance sem consultar.** Apresente o plano e peça autorização. A análise técnica é sua; a decisão é dele.
3. **Antes de qualquer commit, rode a suíte inteira** (comandos no fim deste arquivo).
4. Declare erros e limitações abertamente. Defeito encontrado vira teste.

**O conteúdo é jurídico e é para uma prova real.** Uma questão com gabarito errado ensina errado. Na dúvida sobre uma norma, busque o texto oficial; nunca escreva questão sobre norma que você não leu.

## Datas do edital (Anexo III; a banca pode alterar)

| Evento | Data |
|---|---|
| Prova objetiva | 13/12/2026 |
| Prova discursiva | 24/02/2027 |

## Decisões tomadas, e por quem

| Decisão | Data |
|---|---|
| **Data de corte única: 21/09/2026**, para legislação e jurisprudência. Nada posterior entra no app nem no agente. Decisão da aluna, que é da área. | 28/09/2026 |
| **Trilhas e simulado objetivo: só múltipla escolha, 5 alternativas (A–E).** Não há questão de digitar resposta, ao contrário do DevLingo. Escrita existe só no simulado discursivo. | 28/09/2026 |
| **Trilhas:** uma tentativa, correção imediata, botão de dica, e a aluna segue na trilha mesmo errando. | 28/09/2026 |
| **Simulado objetivo:** 100 questões sorteadas na proporção do edital, **5 h** de cronômetro regressivo, sem dica, **sem consulta** (item 11.9), resultado só no fim. Sorteio sempre aleatório. | 28/09/2026 |
| **Simulado discursivo (web):** 6 h, sem consulta (decisão do Gustavo). O app terá **material de apoio** (lei seca, súmulas, jurisprudência) para ela estudar **antes** do simulado. | 28/09/2026 |
| **Correção da discursiva por IA**, com agente e RAG sobre a própria base do app, e o mesmo agente disponível por mensageiro (Telegram primeiro). | 28/09/2026 |
| **Prioridade de conteúdo:** Administrativo, Constitucional, Tributário e Processual Civil primeiro (79 das 100 questões da objetiva). Depois as outras; Civil (só discursiva) por último. | 28/09/2026 |
| **Provas anteriores:** questões de lei municipal ou estadual de **outro** ente são descartadas. Curitiba e Paraná, só se a norma vigorava em 21/09/2026. STF, STJ e lei federal valem, conferidos na data de corte. | 28/09/2026 |
| **Visual:** sóbrio, aprovado no mockup de 28/09/2026. Claro e escuro, seguindo o celular por padrão. Acerto e erro nunca dependem só da cor: sempre ícone e rótulo. | 28/09/2026 |

## Distribuição da prova objetiva (tabela 10.1.1)

| Código | Matéria | Questões |
|---|---|---|
| `adm` | Direito Administrativo | 22 |
| `const` | Direito Constitucional | 19 |
| `trib` | Tributário, Processo Tributário e Financeiro | 19 |
| `pc` | Processual Civil | 19 |
| `urb` | Urbanístico e Ambiental | 7 |
| `trab` | Trabalho e Processual do Trabalho | 5 |
| `prev` | Previdenciário | 3 |
| `pen` | Penal e Processual Penal | 3 |
| `emp` | Empresarial | 3 |
| `civ` | Direito Civil | só na discursiva |

Corte: 60 pontos. Nota final = (Objetiva × 3 + Discursiva × 5 + Títulos × 2) / 10.

## O banco de questões

- Um arquivo por **unidade** da trilha: `app/assets/questoes/<materia>/<materia>-NN.json`. `itemEdital` aponta para o item da matéria no Anexo II.
- O formato está em [tools/questao.schema.json](tools/questao.schema.json). O validador [tools/validar_questoes.py](tools/validar_questoes.py) recusa questão:
  - sem as 5 alternativas, ou com alternativas repetidas;
  - sem explicação de **cada** alternativa (a correta e as quatro erradas), ou com explicação curta demais;
  - com dica que cita a letra da resposta;
  - sem fonte, ou com fonte posterior à data de corte;
  - adaptada sem dizer de qual prova veio.
- **IDs são imutáveis.** O progresso da aluna aponta para eles.
- Explicações são escritas a partir da fonte oficial, nunca copiadas de comentários de cursinho.

## Fontes oficiais de Curitiba (descoberto pelos agentes em 29/09/2026)

- **leismunicipais.com.br bloqueia acesso automático** (Cloudflare, 403). O SPL da Câmara exige login com captcha.
- **Use o Legisladoc da Prefeitura:** `legisladocexterno.curitiba.pr.gov.br` (`AtosConsultaExterna.aspx`, `VisualizarHTML.aspx?id=`). Traz o texto, a situação ("Em Vigor", "Alterado", "Revogado") e os atos alteradores. O Diário Oficial Eletrônico sai em PDF pelo mesmo sistema.
- **O texto compilado nem sempre incorpora as alterações:** a Lei Orgânica compilada não traz as Emendas 24/2024 e 25/2025, e a página "texto alterado" do Decreto 1.106/2024 não traz o Decreto 1.944/2025. Confira os atos alteradores um a um.
- Constituição do Paraná: legislacao.pr.gov.br.

## Achados sobre o edital e a legislação (para a Flávia e para recursos)

- **Lei 11.001/2004** (carreira de Procurador), citada no edital, foi **revogada** pela Lei 16.200/2023, art. 38, I.
- **Decreto 610/2019**, citado no edital em PPP, está **revogado** e sua ementa é de **contratos e convênios**, não de PPP.
- **Lei 7.833/1991** (política municipal de meio ambiente), citada no edital, está **revogada** no Legisladoc.
- **Decretos 469/2023, 723/2023 e 388/2025**, citados no edital como regulamentos da Lei 14.133, **não conferem**: no Legisladoc esses números são atos de pessoal (nomeação, exoneração). Ficaram fora da base.
- **Lei 2.942/1966** (parcelamento do solo) só existe escaneada, sem texto: fora da base até ser digitada.
- O edital chama a Lei Orgânica de Curitiba de "Lei 5.700/1977"; a Lei Orgânica em vigor é de **05/04/1990**.
- **LC 236/2026** (DOU 4/9/2026, antes do corte) reescreveu os arts. 138, 151, 156 e 174 do CTN e criou os arts. 113-A e 208-A a 208-J.
- **Lei 15.484/2026** (em vigor antes do corte) alterou o CPC em recursos e precedentes (relevância do REsp, art. 1.035-A). Ainda sem questão.
- **EC 136/2025** mudou precatórios e juros contra a Fazenda; dispositivos antigos têm "Vide ADI". Ainda sem questão sobre juros.
- Resoluções CNJ 492/2023 e 598/2024 tratam de perspectiva de gênero e raça, embora o edital as ponha em "processos estruturais".

## Navegação: matéria, e nada de assunto na escolha

Regra do Gustavo (28/09/2026), dita com ênfase: **a tela inicial mostra só as matérias.** Tocou em "Direito Administrativo", a trilha começa direto na pergunta. O **tema aparece só dentro da questão**. No **simulado, nem tema nem matéria** aparecem na tela.

As unidades dos arquivos (`adm-04`, `adm-07`...) existem para organizar o banco por item do edital e medir cobertura. **Nunca viram tela.**

Cada entrada na trilha é uma **sessão de 10 questões** ([app/lib/trilha.dart](app/lib/trilha.dart)): primeiro as inéditas, na ordem do edital; depois as erradas; se acertou tudo, as acertadas. O placar da sessão é parte da própria tela de questão, e não uma rota que a substitui, para "Voltar às matérias" fechar a trilha e a tela inicial saber quando recarregar.

**Defeito já cometido aqui:** `setState(() => _x = umFuture())` devolve o Future atribuído; o Flutter recusa esse setState com um erro que, dentro de função `async` disparada por toque, some em silêncio. A tela não redesenhava o andamento ao voltar da trilha. Use chaves quando o valor atribuído for um Future.

## Progresso

Cada resposta de trilha é gravada na hora ([app/lib/progresso.dart](app/lib/progresso.dart)). As telas dependem da interface `RegistroDeProgresso`; os testes usam `ProgressoEmMemoria`.

**Por que não o SQLite + sincronização do DevLingo:** o PasseiDireito precisa rodar na **web** (discursiva), onde o SQLite do Flutter não roda sem remendo, e há **uma única usuária**, sem os casos de várias contas no aparelho que complicaram o DevLingo. O cache offline do próprio Firestore resolve os dois: grava no aparelho na hora e sobe quando houver rede.

No Firestore, por conta (`usuarios/{uid}/...`):
- `respostas/{auto}`: histórico, uma linha por resposta. Hoje ninguém lê; é para revisão de erros e estatísticas.
- `unidades/{unidadeId}`: resumo com a **última** resposta de cada questão. É o que a tela inicial lê: um documento por unidade, e não um por resposta, para não estourar a cota gratuita de leituras.

**`registrar` não espera o servidor.** `batch.commit()` só termina quando o servidor confirma; esperar travaria o "Continuar" sem internet. O SDK aplica a escrita no cache na hora. Nos testes, o Firestore falso aplica no ciclo seguinte, por isso o contrato em `progresso_test.dart` chama `pumpEventQueue()` antes de ler.

**Firebase:** [app/lib/firebase_config.dart](app/lib/firebase_config.dart) devolve `null` até o projeto existir, e o app roda em modo de demonstração com aviso na tela. Esses valores não são segredo; quem protege os dados é o [firestore.rules](firestore.rules). A conta da Flávia é criada no console (e-mail e senha); não há tela de cadastro.

## Base de lei da IA (corpus)

Decisão do Gustavo (29/09/2026): **sem pagar IA à parte.** Gemini (nível gratuito) como principal e Workers AI da Cloudflare como reserva. "Treinar" a IA = esta base de consulta (RAG) + a régua do edital + calibração com espelhos da FAFIPA, e **não** retreinar modelo: modelo retreinado decora lei mal e não acompanha mudança.

- [corpus/normas.json](corpus/normas.json): a lista das normas federais; [tools/montar_corpus.py](tools/montar_corpus.py) baixa do Planalto, corta por artigo ([tools/fatiar_lei.py](tools/fatiar_lei.py)) e grava `corpus/federal/<id>.json`.
- Cada artigo guarda texto vigente, capítulo, notas de redação, `videStf` (ADI/ADC/ADPF) e `revogado`.
- **Armadilhas do HTML do Planalto, todas com teste:** redação antiga riscada (`<strike>`); redação antiga às vezes SEM risco, ao lado da nova (fica a versão com nota "Redação dada", não simplesmente a última: a Lei 8.212, art. 21, provou a diferença); redação de MP caducada sem risco ("Vigência encerrada"); quebra de linha no meio do parágrafo; "Art. 8º-A" com a letra depois do ordinal; número partido pela formatação ("Art. 5 7."); o ADCT vem depois da assinatura da CF.
- **Trava da data de corte:** a lei é baixada hoje. Toda norma de 2026 citada nas notas precisa de data conferida em [corpus/normas_2026.json](corpus/normas_2026.json). Artigo **incluído** por norma posterior a 21/09/2026 sai da base; **alterado** por ela reprova o montador. Já aconteceu: a **Lei 15.512/2026 é de 22/09/2026** e incluiu o art. 1º-E na Lei 6.938/1981.
- **Curitiba:** [corpus/normas_curitiba.json](corpus/normas_curitiba.json) → [tools/montar_corpus_curitiba.py](tools/montar_corpus_curitiba.py) → `corpus/curitiba/`. A busca do Legisladoc só responde a um navegador de verdade: o Playwright pilota o Chrome instalado ([tools/legisladoc.py](tools/legisladoc.py)). A página do ato traz o texto "Alterado" (vigente) e depois o "Original": só o primeiro entra. O Legisladoc risca com `<s>`, não `<strike>`. Busca com mais de um resultado = republicação; fica a mais recente. **Ementa conferida contra o edital**: número que não confere entra com `ignorar` e motivo.
- Pendente: Constituição do Paraná, súmulas e teses (STF, STJ, TCE-PR).

## Comandos (rode todos antes de cada commit)

```bash
python tools/validar_questoes.py app/assets/questoes/   # banco
python tools/test_validar_questoes.py                   # validador
python tools/test_fatiar_lei.py                         # extrator da base de lei
cd app && flutter analyze && flutter test               # app
```
