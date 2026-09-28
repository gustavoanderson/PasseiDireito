import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
import 'package:passeidireito/tela_questao.dart';
import 'package:passeidireito/tema.dart';

Questao _questao(String id, String correta) => Questao(
      id: id,
      tema: 'Tema de teste',
      enunciado: 'Enunciado da questão $id.',
      alternativas: {for (final l in letras) l: 'Texto da alternativa $l de $id'},
      correta: correta,
      dica: 'Dica da questão $id.',
      explicacao: {for (final l in letras) l: 'Explicação da $l de $id'},
      fontes: const [Fonte(referencia: 'Lei 9.784/1999, art. 54')],
    );

final _unidade = Unidade(
  materia: 'adm',
  id: 'adm-04',
  titulo: 'Atos e processo administrativo',
  itemEdital: 4,
  questoes: [_questao('adm-0001', 'B'), _questao('adm-0002', 'D')],
);

Future<void> _abrir(WidgetTester tester) async {
  // Tela alta o bastante para a explicação inteira caber sem rolar.
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ControleTema(
    alternar: (_) {},
    child: MaterialApp(theme: temaClaro(), home: TelaQuestao(unidade: _unidade)),
  ));
}

Future<void> _tocar(WidgetTester tester, String chave) async {
  await tester.tap(find.byKey(Key(chave)));
  await tester.pump();
}

void main() {
  testWidgets('Confirmar fica desligado até ela escolher uma alternativa', (tester) async {
    await _abrir(tester);
    FilledButton confirmar() => tester.widget(find.byKey(const Key('botao-confirmar')));

    expect(confirmar().onPressed, isNull);
    await _tocar(tester, 'alternativa-C');
    expect(confirmar().onPressed, isNotNull);
  });

  testWidgets('a dica abre e fecha pelo botão', (tester) async {
    await _abrir(tester);
    expect(find.byKey(const Key('caixa-dica')), findsNothing);

    await _tocar(tester, 'botao-dica');
    expect(find.text('Dica da questão adm-0001.'), findsOneWidget);

    await _tocar(tester, 'botao-dica');
    expect(find.byKey(const Key('caixa-dica')), findsNothing);
  });

  testWidgets('acertar mostra "Muito bem!" e a explicação na hora', (tester) async {
    await _abrir(tester);
    await _tocar(tester, 'alternativa-B');
    await _tocar(tester, 'botao-confirmar');

    expect(find.text('Muito bem!'), findsOneWidget);
    expect(find.text('SUA RESPOSTA · CORRETA'), findsOneWidget);
    expect(find.text('Por que a B está correta'), findsOneWidget);
  });

  testWidgets('errar mostra a correta, marca a escolhida e explica TODAS as alternativas', (tester) async {
    await _abrir(tester);
    await _tocar(tester, 'alternativa-A');
    await _tocar(tester, 'botao-confirmar');

    expect(find.text('Resposta incorreta'), findsOneWidget);
    expect(find.text('A correta é a B. Veja a explicação acima.'), findsOneWidget);
    expect(find.text('SUA RESPOSTA'), findsOneWidget);
    expect(find.text('RESPOSTA CORRETA'), findsOneWidget);
    for (final l in letras) {
      expect(find.text('Explicação da $l de adm-0001'), findsOneWidget, reason: 'falta a explicação da $l');
    }
    expect(find.text('Lei 9.784/1999, art. 54'), findsOneWidget);
  });

  testWidgets('uma tentativa só: depois de confirmar, tocar outra alternativa não muda nada', (tester) async {
    await _abrir(tester);
    await _tocar(tester, 'alternativa-A');
    await _tocar(tester, 'botao-confirmar');
    await _tocar(tester, 'alternativa-B');

    expect(find.text('Resposta incorreta'), findsOneWidget);
    expect(find.text('SUA RESPOSTA'), findsOneWidget);
  });

  testWidgets('a dica some depois de confirmar', (tester) async {
    await _abrir(tester);
    await _tocar(tester, 'botao-dica');
    await _tocar(tester, 'alternativa-B');
    await _tocar(tester, 'botao-confirmar');

    expect(find.byKey(const Key('caixa-dica')), findsNothing);
  });

  testWidgets('errando, ela segue na trilha; no fim vê o placar', (tester) async {
    await _abrir(tester);
    await _tocar(tester, 'alternativa-A'); // erra a 1ª
    await _tocar(tester, 'botao-confirmar');
    await _tocar(tester, 'botao-continuar');

    expect(find.text('Enunciado da questão adm-0002.'), findsOneWidget);
    expect(find.byKey(const Key('rodape-resultado')), findsNothing);

    await _tocar(tester, 'alternativa-D'); // acerta a 2ª
    await _tocar(tester, 'botao-confirmar');
    await tester.tap(find.byKey(const Key('botao-continuar')));
    await tester.pumpAndSettle();

    expect(find.text('Unidade concluída'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
  });

  testWidgets('a tela abre também no modo escuro', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ControleTema(
      alternar: (_) {},
      child: MaterialApp(theme: temaEscuro(), home: TelaQuestao(unidade: _unidade)),
    ));
    await _tocar(tester, 'alternativa-A');
    await _tocar(tester, 'botao-confirmar');
    expect(find.text('Resposta incorreta'), findsOneWidget);
  });
}
