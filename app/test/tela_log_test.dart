import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/log.dart';
import 'package:passeidireito/tela_log.dart';
import 'package:passeidireito/tema.dart';

LogDeAlteracoes _log() => LogDeAlteracoes(
      atualizadoEm: DateTime(2026, 10, 14),
      introducao: 'Introdução de teste do log.',
      eventos: [
        EventoDoLog(
          data: DateTime(2026, 9, 21),
          tipo: TipoEvento.edital,
          titulo: 'Edital publicado',
          descricao: 'Descrição do edital original.',
        ),
        EventoDoLog(
          data: DateTime(2026, 10, 13),
          tipo: TipoEvento.remocao,
          titulo: 'Questões antigas saíram',
          descricao: 'Descrição da remoção.',
          questoesRemovidas: const ['pen-0001', 'pen-0002'],
          commit: 'abc1234',
        ),
        EventoDoLog(
          data: DateTime(2026, 10, 14),
          tipo: TipoEvento.criacao,
          titulo: 'Questões novas entraram',
          descricao: 'Descrição da criação.',
          questoesCriadas: const ['civ-0001', 'civ-0002', 'civ-0003'],
          commit: 'def5678',
        ),
      ],
    );

Future<void> _abrir(WidgetTester tester, LogDeAlteracoes log) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ControleTema(
    alternar: (_) {},
    child: MaterialApp(
      theme: temaClaro(),
      home: TelaLog(carregar: () async => log),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra a introdução e a data de atualização', (tester) async {
    await _abrir(tester, _log());
    expect(find.text('Introdução de teste do log.'), findsOneWidget);
    expect(find.textContaining('14/10/2026'), findsWidgets);
  });

  testWidgets('lista os eventos do mais recente para o mais antigo', (tester) async {
    await _abrir(tester, _log());
    final posCriacao = tester.getTopLeft(find.text('Questões novas entraram')).dy;
    final posRemocao = tester.getTopLeft(find.text('Questões antigas saíram')).dy;
    final posEdital = tester.getTopLeft(find.text('Edital publicado')).dy;
    expect(posCriacao, lessThan(posRemocao));
    expect(posRemocao, lessThan(posEdital));
  });

  testWidgets('mostra o rótulo certo por tipo de evento', (tester) async {
    await _abrir(tester, _log());
    expect(find.text('EDITAL'), findsOneWidget);
    expect(find.text('SAIU DO BANCO'), findsOneWidget);
    expect(find.text('ENTROU NO BANCO'), findsOneWidget);
  });

  testWidgets('evento sem questão associada não mostra lista pra expandir', (tester) async {
    await _abrir(tester, _log());
    expect(find.byKey(const Key('expandir-Edital publicado')), findsNothing);
  });

  testWidgets('expandir o evento mostra os ids das questões removidas ou criadas', (tester) async {
    await _abrir(tester, _log());
    expect(find.text('pen-0001, pen-0002'), findsNothing, reason: 'começa fechado');

    await tester.tap(find.text('2 questões removidas'));
    await tester.pumpAndSettle();
    expect(find.text('pen-0001, pen-0002'), findsOneWidget);

    await tester.tap(find.text('3 questões novas'));
    await tester.pumpAndSettle();
    expect(find.text('civ-0001, civ-0002, civ-0003'), findsOneWidget);
  });

  testWidgets('mostra o commit de cada evento que tem um', (tester) async {
    await _abrir(tester, _log());
    expect(find.textContaining('abc1234'), findsOneWidget);
    expect(find.textContaining('def5678'), findsOneWidget);
  });
}
