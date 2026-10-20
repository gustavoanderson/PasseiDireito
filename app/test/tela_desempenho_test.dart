import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/progresso.dart';
import 'package:passeidireito/tela_desempenho.dart';
import 'package:passeidireito/tema.dart';

import 'apoio.dart';

final _unidades = [
  unidadeDeTeste('adm-04', 'Atos administrativos', 3),
  unidadeDeTeste('adm-07', 'Licitações e contratos', 3),
  unidadeDeTeste('const-03', 'Controle de constitucionalidade', 2),
];

Future<ProgressoEmMemoria> _abrir(
  WidgetTester tester,
  Map<String, bool> ultimas, {
  List<ResultadoSimulado> simulados = const [],
}) async {
  tester.view.physicalSize = const Size(1080, 5000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  final registro = ProgressoEmMemoria();
  await tester.pumpWidget(ControleTema(
    alternar: (_) {},
    child: MaterialApp(
      theme: temaClaro(),
      home: TelaDesempenho(unidades: _unidades, ultimas: ultimas, simulados: simulados, registro: registro),
    ),
  ));
  await tester.pumpAndSettle();
  return registro;
}

void main() {
  testWidgets('sem nada feito, explica o que vai aparecer', (tester) async {
    await _abrir(tester, {});
    expect(find.textContaining('Aqui aparece onde você está bem'), findsOneWidget);
  });

  testWidgets('mostra a taxa geral e os assuntos a reforçar na ordem certa', (tester) async {
    await _abrir(tester, {
      'adm-0701': false, 'adm-0702': false, 'adm-0703': true, // Licitações: 2 erros
      'adm-0401': false, 'adm-0402': true, // Atos: 1 erro
      'const-0301': true,
    });
    expect(find.byKey(const Key('taxa-geral')), findsOneWidget);
    expect(find.text('50%'), findsWidgets);
    expect(find.text('Onde reforçar'), findsOneWidget);

    final licitacoes = tester.getTopLeft(find.text('Licitações e contratos').first).dy;
    final atos = tester.getTopLeft(find.text('Atos administrativos').first).dy;
    expect(licitacoes, lessThan(atos), reason: 'o assunto com mais erros vem primeiro');
    expect(find.text('2 erros em 3 feitas'), findsWidgets);
  });

  testWidgets('o caderno de erros lista as erradas e abre a revisão', (tester) async {
    await _abrir(tester, {'adm-0701': false, 'adm-0401': true});
    expect(find.text('Caderno de erros'), findsOneWidget);
    expect(find.text('Direito Administrativo · 1 para rever'), findsOneWidget);

    await tester.tap(find.byKey(const Key('erro-adm-0701')));
    await tester.pumpAndSettle();
    expect(find.text('Revisão da questão'), findsOneWidget);
    expect(find.text('Enunciado da adm-0701.'), findsOneWidget);
  });

  testWidgets('"Refazer" abre uma sessão só com as questões erradas', (tester) async {
    await _abrir(tester, {'adm-0701': false, 'adm-0402': false, 'adm-0401': true});
    await tester.tap(find.byKey(const Key('refazer-adm')));
    await tester.pumpAndSettle();
    expect(find.text('Enunciado da adm-0402.'), findsOneWidget, reason: 'primeira errada na ordem do edital');
  });

  group('zerar progresso de uma matéria', () {
    Future<ProgressoEmMemoria> abrirComRegistro(WidgetTester tester) async {
      final registro = ProgressoEmMemoria();
      await registro.registrar(Resposta(
        questaoId: 'adm-0701',
        unidadeId: 'adm-07',
        materia: 'adm',
        escolhida: 'A',
        acertou: false,
        usouDica: false,
        em: DateTime(2026, 10, 20),
      ));
      await registro.registrar(Resposta(
        questaoId: 'const-0301',
        unidadeId: 'const-03',
        materia: 'const',
        escolhida: 'A',
        acertou: true,
        usouDica: false,
        em: DateTime(2026, 10, 20),
      ));

      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ControleTema(
        alternar: (_) {},
        child: MaterialApp(
          theme: temaClaro(),
          home: TelaDesempenho(
            unidades: _unidades,
            ultimas: {'adm-0701': false, 'const-0301': true},
            simulados: const [],
            registro: registro,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return registro;
    }

    testWidgets('pede confirmação, e cancelar não muda nada', (tester) async {
      await abrirComRegistro(tester);
      await tester.tap(find.byKey(const Key('zerar-adm')));
      await tester.pumpAndSettle();
      expect(find.text('Zerar o progresso de Direito Administrativo?'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('bloco-adm')), findsOneWidget);
    });

    testWidgets('confirmar apaga só a matéria escolhida, na tela e no registro', (tester) async {
      final registro = await abrirComRegistro(tester);
      expect(find.byKey(const Key('bloco-adm')), findsOneWidget);
      expect(find.byKey(const Key('bloco-const')), findsOneWidget);

      await tester.tap(find.byKey(const Key('zerar-adm')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmar-zerar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bloco-adm')), findsNothing, reason: 'adm some da tela');
      expect(find.byKey(const Key('bloco-const')), findsOneWidget, reason: 'const não é afetado');
      expect((await registro.resumos()).containsKey('adm-07'), isFalse);
      expect((await registro.resumos()).containsKey('const-03'), isTrue);
    });
  });

  testWidgets('lista os simulados com a nota', (tester) async {
    final inicio = DateTime(2026, 11, 20, 9);
    await _abrir(tester, {}, simulados: [
      ResultadoSimulado(
        inicio: inicio,
        duracao: const Duration(hours: 1),
        tempoPrevisto: const Duration(hours: 2),
        respostas: [
          for (var i = 0; i < 10; i++)
            Resposta(
              questaoId: 'adm-000$i',
              unidadeId: 'adm-04',
              materia: 'adm',
              escolhida: 'A',
              acertou: i < 7,
              usouDica: false,
              em: inicio,
              origem: OrigemResposta.simulado,
            ),
        ],
      ),
    ]);
    expect(find.text('Simulados'), findsOneWidget);
    expect(find.text('20/11/2026 · 7 de 10'), findsOneWidget);
    expect(find.text('70 pts'), findsOneWidget);
  });
}
