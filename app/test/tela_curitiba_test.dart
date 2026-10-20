import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
import 'package:passeidireito/progresso.dart';
import 'package:passeidireito/tela_curitiba.dart';
import 'package:passeidireito/tema.dart';

Questao _q(String id, String unidade, String referencia) => Questao(
      id: id,
      materia: unidade.split('-').first,
      unidadeId: unidade,
      tema: 'Tema da $id',
      enunciado: 'Enunciado da $id.',
      alternativas: {for (final l in letras) l: 'Alternativa $l da $id'},
      correta: 'A',
      dica: 'Dica da $id.',
      explicacao: {for (final l in letras) l: 'Explicação $l da $id'},
      fontes: [Fonte(referencia: referencia)],
      origem: const Origem(tipo: 'inedita'),
    );

final _unidades = [
  Unidade(
    materia: 'adm',
    id: 'adm-04',
    titulo: 'Atos administrativos',
    itemEdital: 4,
    questoes: [
      _q('adm-0001', 'adm-04', 'Lei Municipal de Curitiba 1.656/1958, art. 10'),
      _q('adm-0002', 'adm-04', 'Lei 9.784/1999, art. 54'), // geral, não entra
    ],
  ),
  Unidade(
    materia: 'const',
    id: 'const-03',
    titulo: 'Controle de constitucionalidade',
    itemEdital: 3,
    questoes: [_q('const-0001', 'const-03', 'Constituição Federal, art. 102')], // sem nenhuma de Curitiba
  ),
];

Future<ProgressoEmMemoria> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  final registro = ProgressoEmMemoria();
  await tester.pumpWidget(ControleTema(
    alternar: (_) {},
    child: MaterialApp(
      theme: temaClaro(),
      home: TelaCuritiba(unidades: _unidades, registro: registro),
    ),
  ));
  await tester.pumpAndSettle();
  return registro;
}

void main() {
  testWidgets('lista só as matérias que têm questão de legislação de Curitiba', (tester) async {
    await _abrir(tester);
    expect(find.text('Direito Administrativo'), findsOneWidget);
    expect(find.text('Direito Constitucional'), findsNothing, reason: 'const não tem nenhuma questão de Curitiba');
    expect(find.text('1 questão'), findsOneWidget);
  });

  testWidgets('tocar na matéria abre a trilha só com as questões de Curitiba', (tester) async {
    await _abrir(tester);
    await tester.tap(find.byKey(const Key('curitiba-adm')));
    await tester.pumpAndSettle();

    expect(find.text('Enunciado da adm-0001.'), findsOneWidget);
    expect(find.textContaining('DIREITO ADMINISTRATIVO · CURITIBA'), findsOneWidget, reason: '_Etiqueta mostra o nome em caixa alta');
  });

  testWidgets('sem nenhuma questão de Curitiba no banco, explica que ainda não há', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ControleTema(
      alternar: (_) {},
      child: MaterialApp(
        theme: temaClaro(),
        home: TelaCuritiba(unidades: const [], registro: ProgressoEmMemoria()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ainda não há questões'), findsOneWidget);
  });
}
