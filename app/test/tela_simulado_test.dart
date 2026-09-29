import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
import 'package:passeidireito/progresso.dart';
import 'package:passeidireito/tela_simulado.dart';
import 'package:passeidireito/tema.dart';

import 'apoio.dart';

/// Relógio de teste: só anda quando o teste manda.
class _Relogio {
  DateTime agora = DateTime(2026, 12, 1, 9);
  void avancar(Duration d) => agora = agora.add(d);
}

// 3 questões de adm (gabarito A) e 1 de const (gabarito A), esta com flag de mudança na lei.
final _unidades = [
  unidadeDeTeste('adm-07', 'Licitações e contratos', 3),
  Unidade(
    materia: 'const',
    id: 'const-03',
    titulo: 'Controle de constitucionalidade',
    itemEdital: 3,
    questoes: [questaoDeTeste('const-0301', unidade: 'const-03', alerta: 'Mudança recente. Vale a norma em vigor em 21/09/2026.')],
  ),
];

Future<(ProgressoEmMemoria, _Relogio)> _abrir(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 4400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  final registro = ProgressoEmMemoria();
  final relogio = _Relogio();
  await tester.pumpWidget(ControleTema(
    alternar: (_) {},
    child: MaterialApp(
      theme: temaClaro(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TelaSimulado(
                  unidades: _unidades,
                  registro: registro,
                  relogio: () => relogio.agora,
                  sorteio: Random(7),
                ),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return (registro, relogio);
}

Future<void> _tocar(WidgetTester tester, String chave) async {
  await tester.tap(find.byKey(Key(chave)));
  await tester.pump();
}

void main() {
  testWidgets('a preparação explica as regras e avisa que o banco ainda é menor que a prova', (tester) async {
    await _abrir(tester);
    expect(find.textContaining('4 questões'), findsOneWidget);
    expect(find.textContaining('12 min de prova'), findsOneWidget, reason: '3 minutos por questão');
    expect(find.textContaining('Sem dica, sem consulta'), findsOneWidget);
    expect(find.textContaining('O banco ainda não tem questões para as 100'), findsOneWidget);
  });

  testWidgets('durante a prova: sem matéria, sem tema, sem dica e sem correção', (tester) async {
    await _abrir(tester);
    await _tocar(tester, 'comecar-simulado');

    expect(find.text('Questão 1 de 4'), findsOneWidget);
    for (final proibido in ['Direito Administrativo', 'DIREITO ADMINISTRATIVO', 'Licitações e contratos']) {
      expect(find.text(proibido), findsNothing, reason: '"$proibido" não pode aparecer no simulado');
    }
    expect(find.textContaining('Tema da'), findsNothing);
    expect(find.byKey(const Key('botao-dica')), findsNothing);

    await _tocar(tester, 'alternativa-B'); // errada
    expect(find.text('Resposta incorreta'), findsNothing);
    expect(find.textContaining('Explicação'), findsNothing);
  });

  testWidgets('a flag de mudança na lei não aparece durante o simulado', (tester) async {
    await _abrir(tester);
    await _tocar(tester, 'comecar-simulado');
    for (var i = 0; i < 4; i++) {
      expect(find.byKey(const Key('flag-mudanca')), findsNothing, reason: 'questão ${i + 1}');
      if (i < 3) await _tocar(tester, 'proxima');
    }
  });

  testWidgets('o cronômetro desce com o relógio e o simulado se entrega sozinho ao zerar', (tester) async {
    final (registro, relogio) = await _abrir(tester);
    await _tocar(tester, 'comecar-simulado');
    expect(find.text('00:12:00'), findsOneWidget);

    relogio.avancar(const Duration(minutes: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:07:00'), findsOneWidget);

    await _tocar(tester, 'alternativa-A');
    relogio.avancar(const Duration(minutes: 8));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Resultado do simulado'), findsOneWidget);
    expect(await registro.simulados(), hasLength(1));
    expect((await registro.simulados()).single.emBranco, 3);
  });

  testWidgets('entregar corrige, grava e mostra nota, matérias, onde reforçar e revisão', (tester) async {
    final (registro, _) = await _abrir(tester);
    await _tocar(tester, 'comecar-simulado');

    // Gabarito é sempre A: acerta a 1ª, erra a 2ª e a 3ª, deixa a 4ª em branco.
    await _tocar(tester, 'alternativa-A');
    await _tocar(tester, 'proxima');
    await _tocar(tester, 'alternativa-C');
    await _tocar(tester, 'proxima');
    await _tocar(tester, 'alternativa-D');
    await _tocar(tester, 'proxima');
    await _tocar(tester, 'entregar');
    await tester.pumpAndSettle();
    expect(find.textContaining('1 questão está em branco'), findsOneWidget);
    await _tocar(tester, 'confirmar-entrega');
    await tester.pumpAndSettle();

    expect(find.text('25 pontos'), findsOneWidget);
    expect(find.text('Abaixo do corte de 60 pontos.'), findsOneWidget);
    expect(find.text('Onde reforçar'), findsOneWidget);
    expect(find.text('Revisão das questões'), findsOneWidget);

    final s = (await registro.simulados()).single;
    expect(s.acertos, 1);
    expect(s.emBranco, 1);
    // As respostas do simulado alimentam o caderno de erros.
    final resumos = await registro.resumos();
    final ultimas = {for (final r in resumos.values) ...r.ultimaPorQuestao};
    expect(ultimas.values.where((a) => !a), hasLength(3));
  });

  testWidgets('a revisão de uma questão mostra a resposta dela, a correta e a explicação', (tester) async {
    await _abrir(tester);
    await _tocar(tester, 'comecar-simulado');
    await _tocar(tester, 'alternativa-C');
    for (var i = 0; i < 3; i++) {
      await _tocar(tester, 'proxima');
    }
    await _tocar(tester, 'entregar');
    await tester.pumpAndSettle();
    await _tocar(tester, 'confirmar-entrega');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('revisao-1')));
    await tester.pumpAndSettle();
    expect(find.text('Revisão da questão'), findsOneWidget);
    expect(find.text('SUA RESPOSTA'), findsOneWidget);
    expect(find.text('RESPOSTA CORRETA'), findsOneWidget);
    expect(find.textContaining('Por que a A está correta'), findsOneWidget);
  });

  testWidgets('tocar de novo na alternativa marcada deixa a questão em branco', (tester) async {
    final (registro, _) = await _abrir(tester);
    await _tocar(tester, 'comecar-simulado');
    await _tocar(tester, 'alternativa-A');
    await _tocar(tester, 'alternativa-A');
    for (var i = 0; i < 3; i++) {
      await _tocar(tester, 'proxima');
    }
    await _tocar(tester, 'entregar');
    await tester.pumpAndSettle();
    await _tocar(tester, 'confirmar-entrega');
    await tester.pumpAndSettle();

    expect((await registro.simulados()).single.emBranco, 4);
  });

  testWidgets('abandonar a prova pede confirmação e não grava nada', (tester) async {
    final (registro, _) = await _abrir(tester);
    await _tocar(tester, 'comecar-simulado');
    await _tocar(tester, 'alternativa-A');

    await tester.tap(find.byTooltip('Sair do simulado'));
    await tester.pumpAndSettle();
    expect(find.text('Sair do simulado?'), findsOneWidget);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.text('abrir'), findsOneWidget, reason: 'voltou para a tela anterior');
    expect(await registro.simulados(), isEmpty);
    expect(registro.respostas, isEmpty);
  });

  test('banco ainda vazio: a lista de letras segue válida', () => expect(letras, hasLength(5)));
}
