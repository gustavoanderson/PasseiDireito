# CLAUDE.md

Contexto do PasseiDireito. Leia antes de qualquer tarefa neste repositório.

---

## O que é

App de estudo gamificado, no formato do Duolingo, para **uma única aluna**: a noiva do Gustavo, que vai prestar o concurso de **Procurador do Município de Curitiba** (Edital Normativo nº 6/2026, banca FAFIPA, publicado em 21/09/2026).

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

## Comandos (rode todos antes de cada commit)

```bash
python tools/validar_questoes.py app/assets/questoes/   # banco
python tools/test_validar_questoes.py                   # validador
cd app && flutter analyze && flutter test               # app
```
