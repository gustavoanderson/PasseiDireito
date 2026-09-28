import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/banco.dart';
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
        home: TelaInicio(carregar: () async => [u('adm', 'adm-04', 4), u('const', 'const-03', 3)]),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('DIREITO ADMINISTRATIVO'), findsOneWidget);
    expect(find.text('DIREITO CONSTITUCIONAL'), findsOneWidget);
    expect(find.text('Unidade adm-04'), findsOneWidget);
    expect(find.text('Item 3 do edital · 0 questões'), findsOneWidget);
  });
}
