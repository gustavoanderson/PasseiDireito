import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
import 'package:passeidireito/progresso.dart';
import 'package:passeidireito/tela_questao.dart';
import 'package:passeidireito/tema.dart';

import 'apoio.dart';

Questao _questao(String id, String correta) => Questao(
      id: id,
      materia: 'adm',
      unidadeId: 'adm-04',
      tema: 'Tema de teste',
      enunciado: 'Enunciado da questão $id.',
      alternativas: {for (final l in letras) l: 'Texto da alternativa $l de $id'},
      correta: correta,
      dica: 'Dica da questão $id.',
      explicacao: {for (final l in letras) l: 'Explicação da $l de $id'},
      fontes: const [Fonte(referencia: 'Lei 9.784/1999, art. 54')],
    );

final _sessao = [_questao('adm-0001', 'B'), _questao('adm-0002', 'D')];

Widget _tela(ThemeData tema, RegistroDeProgresso registro) => ControleTema(
      alternar: (_) {},
      child: MaterialApp(
        theme: tema,
        home: TelaQuestao(nomeDaMateria: 'Direito Administrativo', questoes: _sessao, registro: registro),
      ),
    );

Future<ProgressoEmMemoria> _abrir(WidgetTester tester) async {
  final registro = ProgressoEmMemoria();
  // Tela alta o bastante para a explicação inteira caber sem rolar.
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_tela(temaClaro(), registro));
  return registro;
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

  testWidgets('dentro da questão aparecem a matéria e o tema', (tester) async {
    await _abrir(tester);
    expect(find.text('DIREITO ADMINISTRATIVO'), findsOneWidget);
    expect(find.text('Tema de teste'), findsOneWidget);
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

    expect(find.text('Sessão concluída'), findsOneWidget);
    expect(find.text('1 de 2'), findsOneWidget);
  });

  testWidgets('a tela abre também no modo escuro', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_tela(temaEscuro(), ProgressoEmMemoria()));
    await _tocar(tester, 'alternativa-A');
    await _tocar(tester, 'botao-confirmar');
    expect(find.text('Resposta incorreta'), findsOneWidget);
  });

  group('flag de mudança na lei', () {
    Future<void> abrirCom(WidgetTester tester, String? alerta) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ControleTema(
        alternar: (_) {},
        child: MaterialApp(
          theme: temaClaro(),
          home: TelaQuestao(
            nomeDaMateria: 'Direito Tributário',
            questoes: [questaoDeTeste('trib-0010', alerta: alerta)],
            registro: ProgressoEmMemoria(),
          ),
        ),
      ));
    }

    testWidgets('aparece na questão que tem alerta', (tester) async {
      await abrirCom(tester, 'Mudança recente: vale a redação em vigor em 21/09/2026.');
      expect(find.byKey(const Key('flag-mudanca')), findsOneWidget);
      expect(find.text('MUDANÇA NA LEI · vale 21/09/2026'), findsOneWidget);
      // Pequena por padrão: o texto completo só abre ao tocar.
      expect(find.byKey(const Key('flag-texto')), findsNothing);
      await tester.tap(find.byKey(const Key('flag-mudanca')));
      await tester.pump();
      expect(find.text('Mudança recente: vale a redação em vigor em 21/09/2026.'), findsOneWidget);
    });

    testWidgets('não aparece na questão sem alerta', (tester) async {
      await abrirCom(tester, null);
      expect(find.byKey(const Key('flag-mudanca')), findsNothing);
    });

    testWidgets('continua visível na revisão da questão', (tester) async {
      await tester.pumpWidget(ControleTema(
        alternar: (_) {},
        child: MaterialApp(
          theme: temaEscuro(),
          home: TelaRevisaoQuestao(
            questao: questaoDeTeste('trib-0010', alerta: 'Vale a norma em vigor em 21/09/2026.'),
            nomeDaMateria: 'Direito Tributário',
          ),
        ),
      ));
      expect(find.byKey(const Key('flag-mudanca')), findsOneWidget);
    });
  });

  group('progresso', () {
    testWidgets('cada questão confirmada é gravada na hora, com a escolha e o resultado', (tester) async {
      final registro = await _abrir(tester);
      await _tocar(tester, 'alternativa-A');
      expect(registro.respostas, isEmpty, reason: 'escolher ainda não é responder');

      await _tocar(tester, 'botao-confirmar');
      expect(registro.respostas, hasLength(1));
      final r = registro.respostas.single;
      expect(r.questaoId, 'adm-0001');
      expect(r.unidadeId, 'adm-04');
      expect(r.materia, 'adm');
      expect(r.escolhida, 'A');
      expect(r.acertou, isFalse);
      expect(r.usouDica, isFalse);
    });

    testWidgets('abrir a dica fica registrado, e a marca não passa para a questão seguinte', (tester) async {
      final registro = await _abrir(tester);
      await _tocar(tester, 'botao-dica');
      await _tocar(tester, 'botao-dica'); // fechou de novo: ainda conta
      await _tocar(tester, 'alternativa-B');
      await _tocar(tester, 'botao-confirmar');
      await _tocar(tester, 'botao-continuar');
      await _tocar(tester, 'alternativa-D');
      await _tocar(tester, 'botao-confirmar');

      expect(registro.respostas.map((r) => r.usouDica), [true, false]);
      expect(registro.respostas.map((r) => r.acertou), [true, true]);
    });
  });
}
