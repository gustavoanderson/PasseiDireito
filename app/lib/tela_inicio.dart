import 'package:flutter/material.dart';

import 'banco.dart';
import 'logo.dart';
import 'progresso.dart';
import 'tela_desempenho.dart';
import 'tela_questao.dart';
import 'tela_simulado.dart';
import 'tema.dart';
import 'trilha.dart';

/// Data da prova objetiva (Edital 6/2026, Anexo III). Muda, se o edital mudar.
final dataDaProvaObjetiva = DateTime(2026, 12, 13);

/// Dias entre [hoje] e [data], arredondado pela diferença de calendário (não
/// de 24h): consultada às 23h do dia anterior, ainda mostra "falta 1 dia", e
/// não "0" por uma questão de horas.
int diasAte(DateTime data, DateTime hoje) {
  final soData = DateTime(data.year, data.month, data.day);
  final soHoje = DateTime(hoje.year, hoje.month, hoje.day);
  return soData.difference(soHoje).inDays;
}

/// A tela de entrada: uma linha por matéria. Tocou, começa a trilha.
class TelaInicio extends StatefulWidget {
  const TelaInicio({
    super.key,
    required this.registro,
    this.carregar = carregarUnidades,
    this.progressoSalvo = true,
    this.hoje = DateTime.now,
  });

  final RegistroDeProgresso registro;

  /// Trocável nos testes, para não depender do banco real.
  final Future<List<Unidade>> Function() carregar;

  /// Falso quando o Firebase não está configurado: a tela avisa que nada será guardado.
  final bool progressoSalvo;

  /// Trocável nos testes, para a contagem para a prova não depender do relógio real.
  final DateTime Function() hoje;

  @override
  State<TelaInicio> createState() => _TelaInicioState();
}

class _TelaInicioState extends State<TelaInicio> {
  late final Future<List<Unidade>> _unidades = widget.carregar();
  late final Future<List<Materia>> _materias = _unidades.then(agruparPorMateria);
  late Future<Map<String, ResumoUnidade>> _resumos = widget.registro.resumos();

  Future<void> _abrir(Materia materia, Map<String, bool> ultimas) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TelaQuestao(
        nomeDaMateria: materia.nome,
        questoes: montarSessao(materia.questoes, ultimas),
        registro: widget.registro,
      ),
    ));
    _recarregar();
  }

  /// Na volta de qualquer tela, o andamento tem que refletir o que ela acabou
  /// de fazer. Progresso que não aparece parece progresso perdido (DevLingo).
  void _recarregar() {
    if (!mounted) return;
    // Chaves, e não seta: com seta o callback devolveria o Future atribuído, o
    // Flutter recusa setState assim, e o erro sumia em silêncio dentro desta
    // função assíncrona — a tela ficava com o andamento antigo.
    setState(() {
      _resumos = widget.registro.resumos();
    });
  }

  Future<void> _abrirSimulado() async {
    final unidades = await _unidades;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TelaSimulado(unidades: unidades, registro: widget.registro),
    ));
    _recarregar();
  }

  Future<void> _abrirDesempenho() async {
    final (unidades, resumos, simulados) =
        await (_unidades, widget.registro.resumos(), widget.registro.simulados()).wait;
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TelaDesempenho(
        unidades: unidades,
        ultimas: ultimasRespostas(resumos),
        simulados: simulados,
        registro: widget.registro,
      ),
    ));
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder(
          future: Future.wait([_materias, _resumos]),
          builder: (context, estado) {
            if (estado.hasError) {
              return Center(child: Text('Não consegui abrir as matérias.\n${estado.error}'));
            }
            if (!estado.hasData) return const Center(child: CircularProgressIndicator());

            final materias = estado.data![0] as List<Materia>;
            final ultimas = ultimasRespostas(estado.data![1] as Map<String, ResumoUnidade>);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 24),
              children: [
                Row(
                  children: [
                    const LogoPasseiDireito(tamanho: 44),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'PasseiDireito',
                        style: TextStyle(fontFamily: fonteTitulo, fontSize: 26, fontWeight: FontWeight.w600, color: esquema.onSurface),
                      ),
                    ),
                    const BotaoTema(),
                  ],
                ),
                Text(
                  'Procurador do Município de Curitiba · Edital 6/2026',
                  style: TextStyle(fontSize: 14, color: esquema.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                _ContagemParaAProva(dias: diasAte(dataDaProvaObjetiva, widget.hoje())),
                if (!widget.progressoSalvo) ...[
                  const SizedBox(height: 16),
                  const _AvisoSemSalvar(),
                ],
                const SizedBox(height: 24),
                for (final m in materias) ...[
                  _CartaoMateria(materia: m, ultimas: ultimas, aoTocar: () => _abrir(m, ultimas)),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 18),
                _Atalho(
                  chave: 'abrir-simulado',
                  icone: Icons.timer_outlined,
                  titulo: 'Simulado da prova objetiva',
                  subtitulo: 'Questões sorteadas, cronômetro e resultado no fim',
                  aoTocar: _abrirSimulado,
                ),
                const SizedBox(height: 10),
                _Atalho(
                  chave: 'abrir-desempenho',
                  icone: Icons.insights_outlined,
                  titulo: 'Seu desempenho',
                  subtitulo: 'Acertos, onde reforçar e caderno de erros',
                  aoTocar: _abrirDesempenho,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Contador regressivo até a prova objetiva. Some depois da data (o foco
/// vira a discursiva, que este contador não é sobre), e muda de texto no
/// próprio dia — "faltam 0 dias" leria estranho.
class _ContagemParaAProva extends StatelessWidget {
  const _ContagemParaAProva({required this.dias});

  final int dias;

  @override
  Widget build(BuildContext context) {
    if (dias < 0) return const SizedBox.shrink();
    final esquema = Theme.of(context).colorScheme;
    final dataLegivel =
        '${dataDaProvaObjetiva.day.toString().padLeft(2, '0')}/${dataDaProvaObjetiva.month.toString().padLeft(2, '0')}/${dataDaProvaObjetiva.year}';
    return Container(
      key: const Key('contagem-para-a-prova'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: esquema.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.event_outlined, size: 20, color: esquema.onPrimaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: esquema.onPrimaryContainer),
                children: [
                  TextSpan(text: dias == 0 ? 'É hoje: ' : 'Faltam '),
                  if (dias > 0)
                    TextSpan(
                      text: dias == 1 ? '1 dia ' : '$dias dias ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  TextSpan(text: 'para a prova objetiva · $dataLegivel'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoSemSalvar extends StatelessWidget {
  const _AvisoSemSalvar();

  @override
  Widget build(BuildContext context) {
    final cores = Cores.de(context);
    return Container(
      key: const Key('aviso-sem-salvar'),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cores.dicaSuave,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cores.dica),
      ),
      child: Text(
        'Modo de demonstração: o progresso não está sendo salvo. Fechar o app apaga as respostas.',
        style: TextStyle(fontSize: 14, color: cores.dicaTexto),
      ),
    );
  }
}

class _CartaoMateria extends StatelessWidget {
  const _CartaoMateria({required this.materia, required this.ultimas, required this.aoTocar});

  final Materia materia;
  final Map<String, bool> ultimas;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final total = materia.questoes.length;
    // Só conta questões que existem hoje: id aposentado não infla o número.
    final respondidas = [for (final q in materia.questoes) if (ultimas.containsKey(q.id)) ultimas[q.id]!];
    final feitas = respondidas.length;
    final acertos = respondidas.where((a) => a).length;
    final andamento = feitas == 0 ? (total == 1 ? '1 questão' : '$total questões') : '$feitas de $total feitas · $acertos acertos';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        key: Key('materia-${materia.codigo}'),
        color: esquema.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: esquema.outline, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(materia.nome, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(andamento, style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: esquema.onSurfaceVariant),
                  ],
                ),
                if (feitas > 0) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: feitas / total,
                      minHeight: 6,
                      color: esquema.primary,
                      backgroundColor: esquema.outline.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.chave,
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.aoTocar,
  });

  final String chave;
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        key: Key(chave),
        color: esquema.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoTocar,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icone, color: esquema.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: esquema.onSurface)),
                      const SizedBox(height: 2),
                      Text(subtitulo, style: TextStyle(fontSize: 13, color: esquema.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: esquema.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
