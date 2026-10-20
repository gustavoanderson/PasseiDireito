import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
import 'package:passeidireito/progresso.dart';
import 'package:passeidireito/prova.dart';
import 'package:passeidireito/tela_simulado_personalizado.dart';
import 'package:passeidireito/tema.dart';

Questao _q(String id, {String unidade = 'teste-2020'}) => Questao(
      id: id,
      materia: unidade.split('-').first == 'adm' ? 'adm' : 'adm',
      unidadeId: unidade,
      tema: 'Tema de $id',
      enunciado: 'Enunciado de $id.',
      alternativas: {for (final l in letras) l: 'Alternativa $l'},
      correta: 'A',
      dica: 'Dica.',
      explicacao: {for (final l in letras) l: 'Explicação $l'},
      fontes: const [Fonte(referencia: 'Lei de teste')],
      origem: const Origem(tipo: 'inedita'),
    );

ProvaReal _prova(String id, int n, {bool definitivo = true}) => ProvaReal(
      dados: DadosDaProva(
        id: id,
        concurso: 'Concurso $id',
        banca: 'FAFIPA',
        ano: 2020,
        cargo: 'Procurador',
        dataAplicacao: DateTime(2020, 1, 1),
        gabaritoDefinitivoPublicado: definitivo,
        fonte: 'https://exemplo.org/$id',
      ),
      questoes: [for (var i = 1; i <= n; i++) _q('$id-00$i', unidade: id)],
    );

final _unidades = [
  Unidade(materia: 'adm', id: 'adm-04', titulo: 'Atos administrativos', itemEdital: 4, questoes: [for (var i = 1; i <= 60; i++) _q('adm-${i.toString().padLeft(4, '0')}')]),
];

Future<void> _abrir(WidgetTester tester, List<ProvaReal> provas, {Random? sorteio}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ControleTema(
    alternar: (_) {},
    child: MaterialApp(
      theme: temaClaro(),
      home: TelaSimuladoPersonalizado(
        unidades: _unidades,
        registro: ProgressoEmMemoria(),
        carregar: () async => provas,
        sorteio: sorteio,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem nenhuma prova, avisa e o botão fica desabilitado até somar inéditas', (tester) async {
    await _abrir(tester, []);
    expect(find.textContaining('Ainda não há nenhuma prova'), findsOneWidget);
    expect(find.text('Escolha ao menos uma fonte'), findsOneWidget);

    final botaoAntes = tester.widget<FilledButton>(find.byKey(const Key('gerar-simulado-personalizado')));
    expect(botaoAntes.onPressed, isNull);

    await tester.tap(find.byKey(const Key('somar-ineditas')));
    await tester.pumpAndSettle();
    expect(find.text('Gerar simulado · 20 questões'), findsOneWidget);
  });

  testWidgets('lista as provas disponíveis com cargo e quantidade', (tester) async {
    await _abrir(tester, [_prova('ano2020', 3), _prova('ano2021', 5)]);
    expect(find.text('FAFIPA 2020 · Concurso ano2020'), findsOneWidget);
    expect(find.textContaining('Procurador · 3 questões'), findsOneWidget);
    expect(find.text('FAFIPA 2020 · Concurso ano2021'), findsOneWidget);
    expect(find.textContaining('Procurador · 5 questões'), findsOneWidget);
  });

  testWidgets('marcar uma prova soma ao total do botão', (tester) async {
    await _abrir(tester, [_prova('ano2020', 3), _prova('ano2021', 5)]);
    await tester.tap(find.byKey(const Key('escolher-ano2020')));
    await tester.pumpAndSettle();
    expect(find.text('Gerar simulado · 3 questões'), findsOneWidget);

    await tester.tap(find.byKey(const Key('escolher-ano2021')));
    await tester.pumpAndSettle();
    expect(find.text('Gerar simulado · 8 questões'), findsOneWidget);
  });

  testWidgets('somar inéditas soma a quantidade escolhida ao total', (tester) async {
    await _abrir(tester, [_prova('ano2020', 3)]);
    await tester.tap(find.byKey(const Key('escolher-ano2020')));
    await tester.tap(find.byKey(const Key('somar-ineditas')));
    await tester.pumpAndSettle();
    expect(find.text('Gerar simulado · 23 questões'), findsOneWidget, reason: '3 da prova + 20 inéditas padrão');

    await tester.tap(find.byKey(const Key('quantidade-ineditas-10')));
    await tester.pumpAndSettle();
    expect(find.text('Gerar simulado · 13 questões'), findsOneWidget);
  });

  testWidgets('gerar leva para a prova com o total certo de questões, embaralhadas', (tester) async {
    await _abrir(tester, [_prova('ano2020', 3), _prova('ano2021', 5)], sorteio: Random(1));
    await tester.tap(find.byKey(const Key('escolher-ano2020')));
    await tester.tap(find.byKey(const Key('escolher-ano2021')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gerar-simulado-personalizado')));
    await tester.pumpAndSettle();

    expect(find.text('Simulado personalizado'), findsOneWidget);
    expect(find.textContaining('8 questões'), findsOneWidget);
  });

  testWidgets('avisa gabarito preliminar quando alguma prova escolhida ainda não tem gabarito definitivo', (tester) async {
    await _abrir(tester, [_prova('ano2020', 3, definitivo: false)]);
    await tester.tap(find.byKey(const Key('escolher-ano2020')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('gerar-simulado-personalizado')));
    await tester.pumpAndSettle();

    expect(find.textContaining('gabarito preliminar'), findsOneWidget);
  });
}
