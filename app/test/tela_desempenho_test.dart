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
