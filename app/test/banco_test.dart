import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
import 'package:passeidireito/progresso.dart';
import 'package:passeidireito/tela_inicio.dart';
import 'package:passeidireito/tema.dart';

Questao _q(String id, String unidade) => Questao(
      id: id,
      materia: unidade.split('-').first,
      unidadeId: unidade,
      tema: 'Tema da $id',
      enunciado: 'Enunciado da $id.',
      alternativas: {for (final l in letras) l: 'Alternativa $l da $id'},
      correta: 'A',
      dica: 'Dica da $id.',
      explicacao: {for (final l in letras) l: 'Explicação $l da $id'},
      fontes: const [Fonte(referencia: 'Lei X')],
    );

Unidade _u(String id, String titulo, List<String> questoes) => Unidade(
      materia: id.split('-').first,
      id: id,
      titulo: titulo,
      itemEdital: 1,
      questoes: [for (final q in questoes) _q(q, id)],
    );

final _banco = [
  _u('adm-03', 'Advocacia pública', ['adm-0007']),
  _u('adm-04', 'Atos e processo administrativo', ['adm-0001', 'adm-0002']),
  _u('const-01', 'Teoria da Constituição', ['const-0001']),
];

Future<void> _abrirInicio(WidgetTester tester, RegistroDeProgresso registro, {bool salvo = true}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ControleTema(
    alternar: (_) {},
    child: MaterialApp(
      theme: temaClaro(),
      home: TelaInicio(registro: registro, carregar: () async => _banco, progressoSalvo: salvo),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _responder(RegistroDeProgresso r, String id, String unidade, bool acertou) => r.registrar(Resposta(
      questaoId: id,
      unidadeId: unidade,
      materia: unidade.split('-').first,
      escolhida: 'A',
      acertou: acertou,
      usouDica: false,
      em: DateTime(2026, 10, 1),
    ));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('o banco real que vai no app é lido inteiro, com matéria e unidade em cada questão', () async {
    final unidades = await carregarUnidades();
    expect(unidades, isNotEmpty);

    final q = unidades.firstWhere((u) => u.id == 'adm-04').questoes.first;
    expect(q.materia, 'adm');
    expect(q.unidadeId, 'adm-04');
    expect(q.alternativas.keys, letras);
    expect(q.explicacao.keys, letras);
    expect(q.fontes, isNotEmpty);

    final comAlerta = [for (final u in unidades) ...u.questoes.where((q) => q.alerta != null)];
    expect(comAlerta.map((q) => q.id), containsAll(['const-0020', 'trib-0010', 'trib-0044']));
    expect(comAlerta.every((q) => q.alerta!.contains('21/09/2026')), isTrue);
  });

  testWidgets('a tela inicial mostra só as matérias, sem os assuntos', (tester) async {
    await _abrirInicio(tester, ProgressoEmMemoria());

    expect(find.text('Direito Administrativo'), findsOneWidget);
    expect(find.text('Direito Constitucional'), findsOneWidget);
    expect(find.text('3 questões'), findsOneWidget);
    for (final assunto in ['Advocacia pública', 'Atos e processo administrativo', 'Teoria da Constituição']) {
      expect(find.text(assunto), findsNothing, reason: 'assunto "$assunto" não pode aparecer na escolha da matéria');
    }
  });

  testWidgets('tocar na matéria começa a trilha direto na pergunta', (tester) async {
    await _abrirInicio(tester, ProgressoEmMemoria());
    await tester.tap(find.byKey(const Key('materia-adm')));
    await tester.pumpAndSettle();

    expect(find.text('Enunciado da adm-0007.'), findsOneWidget);
    // O tema aparece dentro da questão.
    expect(find.text('Tema da adm-0007'), findsOneWidget);
  });

  testWidgets('a trilha retoma da primeira questão ainda não respondida', (tester) async {
    final registro = ProgressoEmMemoria();
    await _responder(registro, 'adm-0007', 'adm-03', true);
    await _abrirInicio(tester, registro);
    await tester.tap(find.byKey(const Key('materia-adm')));
    await tester.pumpAndSettle();

    expect(find.text('Enunciado da adm-0001.'), findsOneWidget);
  });

  testWidgets('o andamento da matéria soma todas as suas unidades', (tester) async {
    final registro = ProgressoEmMemoria();
    await _responder(registro, 'adm-0007', 'adm-03', true);
    await _responder(registro, 'adm-0001', 'adm-04', false);
    await _responder(registro, 'adm-9999', 'adm-04', true); // id que não existe mais
    await _abrirInicio(tester, registro);

    expect(find.text('2 de 3 feitas · 1 acertos'), findsOneWidget);
    expect(find.byKey(const Key('aviso-sem-salvar')), findsNothing);
  });

  testWidgets('ao voltar da trilha, o andamento já mostra o que ela fez', (tester) async {
    final registro = ProgressoEmMemoria();
    await _abrirInicio(tester, registro);
    await tester.tap(find.byKey(const Key('materia-const')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('alternativa-A')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('botao-confirmar')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('botao-continuar')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Voltar às matérias'));
    await tester.pumpAndSettle();

    expect(find.text('1 de 1 feitas · 1 acertos'), findsOneWidget);
  });

  testWidgets('sem Firebase, a tela avisa que o progresso não está sendo salvo', (tester) async {
    await _abrirInicio(tester, ProgressoEmMemoria(), salvo: false);
    expect(find.byKey(const Key('aviso-sem-salvar')), findsOneWidget);
  });
}
