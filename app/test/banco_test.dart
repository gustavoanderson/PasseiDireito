import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
import 'package:passeidireito/progresso.dart';
import 'package:passeidireito/tela_inicio.dart';
import 'package:passeidireito/tema.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('o banco real que vai no app é lido inteiro', () async {
    final unidades = await carregarUnidades();
    expect(unidades, isNotEmpty);

    final adm04 = unidades.firstWhere((u) => u.id == 'adm-04');
    expect(adm04.materia, 'adm');
    final q = adm04.questoes.first;
    expect(q.alternativas.keys, letras);
    expect(q.explicacao.keys, letras);
    expect(q.fontes, isNotEmpty);
  });

  testWidgets('a tela inicial agrupa as unidades por matéria, na ordem do edital', (tester) async {
    Unidade u(String materia, String id, int item) => Unidade(
          materia: materia,
          id: id,
          titulo: 'Unidade $id',
          itemEdital: item,
          questoes: const [],
        );

    await tester.pumpWidget(ControleTema(
      alternar: (_) {},
      child: MaterialApp(
        theme: temaClaro(),
        home: TelaInicio(registro: ProgressoEmMemoria(), carregar: () async => [u('adm', 'adm-04', 4), u('const', 'const-03', 3)]),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('DIREITO ADMINISTRATIVO'), findsOneWidget);
    expect(find.text('DIREITO CONSTITUCIONAL'), findsOneWidget);
    expect(find.text('Unidade adm-04'), findsOneWidget);
    expect(find.text('Item 3 do edital · 0 questões'), findsOneWidget);
  });

  testWidgets('a tela inicial mostra o andamento gravado de cada unidade', (tester) async {
    Questao q(String id) => Questao(
          id: id,
          tema: 't',
          enunciado: 'e',
          alternativas: {for (final l in letras) l: l},
          correta: 'A',
          dica: 'd',
          explicacao: {for (final l in letras) l: l},
          fontes: const [],
        );
    final unidade = Unidade(
      materia: 'adm',
      id: 'adm-04',
      titulo: 'Atos',
      itemEdital: 4,
      questoes: [q('adm-0001'), q('adm-0002'), q('adm-0003')],
    );
    final registro = ProgressoEmMemoria();
    for (final (id, acertou) in [('adm-0001', true), ('adm-0002', false), ('adm-9999', true)]) {
      await registro.registrar(Resposta(
        questaoId: id,
        unidadeId: 'adm-04',
        materia: 'adm',
        escolhida: 'A',
        acertou: acertou,
        usouDica: false,
        em: DateTime(2026, 10, 1),
      ));
    }

    await tester.pumpWidget(ControleTema(
      alternar: (_) {},
      child: MaterialApp(
        theme: temaClaro(),
        home: TelaInicio(registro: registro, carregar: () async => [unidade]),
      ),
    ));
    await tester.pumpAndSettle();

    // adm-9999 não existe mais na unidade: não entra na conta.
    expect(find.text('2 de 3 feitas · 1 acertos'), findsOneWidget);
    expect(find.byKey(const Key('aviso-sem-salvar')), findsNothing);
  });

  testWidgets('sem Firebase, a tela avisa que o progresso não está sendo salvo', (tester) async {
    await tester.pumpWidget(ControleTema(
      alternar: (_) {},
      child: MaterialApp(
        theme: temaClaro(),
        home: TelaInicio(registro: ProgressoEmMemoria(), carregar: () async => [], progressoSalvo: false),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('aviso-sem-salvar')), findsOneWidget);
  });
}
