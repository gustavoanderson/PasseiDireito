import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
import 'package:passeidireito/progresso.dart';
import 'package:passeidireito/prova.dart';
import 'package:passeidireito/tela_provas.dart';
import 'package:passeidireito/tema.dart';

Questao _q(String id, String tema, String correta, {List<String> letrasDisponiveis = letras}) => Questao(
      id: id,
      materia: 'adm',
      unidadeId: 'teste-2020',
      tema: tema,
      enunciado: 'Enunciado da $id.',
      alternativas: {for (final l in letrasDisponiveis) l: 'Alternativa $l da $id'},
      correta: correta,
      dica: 'Dica da $id.',
      explicacao: {for (final l in letrasDisponiveis) l: 'Explicação $l da $id'},
      fontes: const [Fonte(referencia: 'Lei de teste')],
      origem: const Origem(tipo: 'adaptada', prova: 'FAFIPA 2020 · Teste'),
    );

ProvaReal _prova({bool definitivo = true, int n = 4}) => ProvaReal(
      dados: DadosDaProva(
        id: 'teste-2020',
        concurso: 'Teste',
        banca: 'FAFIPA',
        ano: 2020,
        cargo: 'Procurador',
        dataAplicacao: DateTime(2020, 3, 15),
        gabaritoDefinitivoPublicado: definitivo,
        fonte: 'https://exemplo.org/teste',
      ),
      questoes: [for (var i = 1; i <= n; i++) _q('teste-2020-00$i', 'Tema $i', 'A')],
    );

class _Relogio {
  DateTime agora = DateTime(2026, 12, 1, 9);
  void avancar(Duration d) => agora = agora.add(d);
}

Future<void> _tocar(WidgetTester tester, String chave) async {
  await tester.tap(find.byKey(Key(chave)));
  await tester.pump();
}

void main() {
  group('TelaProvas (lista)', () {
    Future<void> abrir(WidgetTester tester, List<ProvaReal> provas) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ControleTema(
        alternar: (_) {},
        child: MaterialApp(
          theme: temaClaro(),
          home: TelaProvas(registro: ProgressoEmMemoria(), carregar: () async => provas),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('sem nenhuma prova, explica que ainda não há', (tester) async {
      await abrir(tester, []);
      expect(find.textContaining('Ainda não há nenhuma prova'), findsOneWidget);
    });

    testWidgets('lista a prova com cargo e quantidade de questões', (tester) async {
      await abrir(tester, [_prova()]);
      expect(find.text('FAFIPA 2020 · Teste'), findsOneWidget);
      expect(find.textContaining('Procurador · 4 questões'), findsOneWidget);
    });

    testWidgets('avisa quando o gabarito ainda é só preliminar', (tester) async {
      await abrir(tester, [_prova(definitivo: false)]);
      expect(find.textContaining('gabarito preliminar'), findsOneWidget);
    });

    testWidgets('tocar na prova abre a tela de fazer a prova', (tester) async {
      await abrir(tester, [_prova()]);
      await tester.tap(find.byKey(const Key('prova-teste-2020')));
      await tester.pumpAndSettle();
      expect(find.text('FAFIPA 2020 · Teste'), findsWidgets);
      expect(find.byKey(const Key('comecar-prova')), findsOneWidget);
    });
  });

  group('TelaFazerProva (refazer uma prova inteira)', () {
    Future<(ProgressoEmMemoria, _Relogio)> abrir(WidgetTester tester, {bool definitivo = true}) async {
      tester.view.physicalSize = const Size(1080, 4400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      final registro = ProgressoEmMemoria();
      final relogio = _Relogio();
      await tester.pumpWidget(ControleTema(
        alternar: (_) {},
        child: MaterialApp(
          theme: temaClaro(),
          home: TelaFazerProva(
            titulo: 'FAFIPA 2020 · Teste',
            questoes: _prova(definitivo: definitivo).questoes,
            registro: registro,
            avisoGabaritoPreliminar: !definitivo,
            relogio: () => relogio.agora,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return (registro, relogio);
    }

    testWidgets('a preparação mostra o total de questões e o tempo', (tester) async {
      await abrir(tester);
      expect(find.textContaining('4 questões'), findsOneWidget);
      expect(find.textContaining('12 min'), findsOneWidget, reason: '3 minutos por questão');
    });

    testWidgets('avisa de gabarito preliminar quando a prova ainda não é definitiva', (tester) async {
      await abrir(tester, definitivo: false);
      expect(find.textContaining('gabarito preliminar'), findsOneWidget);
    });

    testWidgets('durante a prova, sem matéria e sem tema', (tester) async {
      await abrir(tester);
      await _tocar(tester, 'comecar-prova');
      expect(find.text('Questão 1 de 4'), findsOneWidget);
      expect(find.textContaining('Tema'), findsNothing);
    });

    testWidgets('questão de prova com só 4 alternativas (A-D) não mostra a E', (tester) async {
      tester.view.physicalSize = const Size(1080, 4400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);
      final registro = ProgressoEmMemoria();
      await tester.pumpWidget(ControleTema(
        alternar: (_) {},
        child: MaterialApp(
          theme: temaClaro(),
          home: TelaFazerProva(
            titulo: 'Prova de 4 alternativas',
            questoes: [_q('quatro-001', 'Tema', 'A', letrasDisponiveis: const ['A', 'B', 'C', 'D'])],
            registro: registro,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await _tocar(tester, 'comecar-prova');

      expect(find.byKey(const Key('alternativa-prova-A')), findsOneWidget);
      expect(find.byKey(const Key('alternativa-prova-D')), findsOneWidget);
      expect(find.byKey(const Key('alternativa-prova-E')), findsNothing, reason: 'esta prova só tinha 4 alternativas');
    });

    testWidgets('tocar de novo na alternativa marcada deixa a questão em branco', (tester) async {
      final (registro, _) = await abrir(tester);
      await _tocar(tester, 'comecar-prova');
      await _tocar(tester, 'alternativa-prova-A');
      await _tocar(tester, 'alternativa-prova-A');
      for (var i = 0; i < 3; i++) {
        await _tocar(tester, 'proxima-questao');
      }
      await _tocar(tester, 'entregar-prova');
      await tester.pumpAndSettle();
      await _tocar(tester, 'confirmar-entrega');
      await tester.pumpAndSettle();

      expect((await registro.simulados()).single.emBranco, 4);
    });

    testWidgets('o relógio desce e entrega sozinho ao zerar', (tester) async {
      final (registro, relogio) = await abrir(tester);
      await _tocar(tester, 'comecar-prova');
      expect(find.text('00:12:00'), findsOneWidget);

      relogio.avancar(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:07:00'), findsOneWidget);

      relogio.avancar(const Duration(minutes: 8));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.textContaining('Resultado ·'), findsOneWidget);
      expect(await registro.simulados(), hasLength(1));
    });

    testWidgets('entregar corrige, grava como simulado e mostra a revisão', (tester) async {
      final (registro, _) = await abrir(tester);
      await _tocar(tester, 'comecar-prova');

      // Gabarito é sempre A: acerta a 1ª, erra as demais.
      await _tocar(tester, 'alternativa-prova-A');
      await _tocar(tester, 'proxima-questao');
      await _tocar(tester, 'alternativa-prova-B');
      await _tocar(tester, 'proxima-questao');
      await _tocar(tester, 'alternativa-prova-C');
      await _tocar(tester, 'proxima-questao');
      await _tocar(tester, 'entregar-prova');
      await tester.pumpAndSettle();
      expect(find.textContaining('1 questão está em branco'), findsOneWidget);
      await _tocar(tester, 'confirmar-entrega');
      await tester.pumpAndSettle();

      expect(find.text('1 de 4'), findsOneWidget);
      expect(find.text('Revisão das questões'), findsOneWidget);

      final s = (await registro.simulados()).single;
      expect(s.acertos, 1);
      expect(s.emBranco, 1);

      await tester.tap(find.byKey(const Key('revisao-prova-1')));
      await tester.pumpAndSettle();
      expect(find.text('Revisão da questão'), findsOneWidget);
    });

    testWidgets('abandonar pede confirmação e não grava nada', (tester) async {
      final (registro, _) = await abrir(tester);
      await _tocar(tester, 'comecar-prova');
      await tester.tap(find.byTooltip('Sair da prova'));
      await tester.pumpAndSettle();
      expect(find.text('Sair da prova?'), findsOneWidget);

      await tester.tap(find.text('Sair'));
      await tester.pumpAndSettle();
      expect(await registro.simulados(), isEmpty);
    });
  });
}
