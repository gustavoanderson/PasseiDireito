import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/progresso.dart';
import 'package:passeidireito/tela_favoritas.dart';
import 'package:passeidireito/tema.dart';

import 'apoio.dart';

final _unidades = [
  unidadeDeTeste('adm-01', 'Atos administrativos', 3),
  unidadeDeTeste('const-01', 'Teoria da Constituição', 2),
];

Future<void> _abrir(WidgetTester tester, RegistroDeProgresso registro) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ControleTema(
    alternar: (_) {},
    child: MaterialApp(
      theme: temaClaro(),
      home: TelaFavoritas(unidades: _unidades, registro: registro),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem nenhuma favorita, explica como marcar uma', (tester) async {
    await _abrir(tester, ProgressoEmMemoria());
    expect(find.textContaining('Toque na estrela'), findsOneWidget);
  });

  testWidgets('lista as favoritas, da mais recente para a mais antiga, com matéria e tema', (tester) async {
    final registro = ProgressoEmMemoria();
    await registro.favoritar('adm-0101', true);
    await registro.favoritar('const-0101', true);
    await _abrir(tester, registro);

    expect(find.byKey(const Key('favorita-const-0101')), findsOneWidget);
    expect(find.byKey(const Key('favorita-adm-0101')), findsOneWidget);
    expect(find.text('DIREITO CONSTITUCIONAL'), findsOneWidget);
    expect(find.text('Tema da const-0101'), findsOneWidget);

    // A última marcada (const) aparece antes da primeira (adm).
    final ordem = tester.getTopLeft(find.byKey(const Key('favorita-const-0101'))).dy;
    final ordemAdm = tester.getTopLeft(find.byKey(const Key('favorita-adm-0101'))).dy;
    expect(ordem, lessThan(ordemAdm));
  });

  testWidgets('ignora id de questão que não existe mais no banco', (tester) async {
    final registro = ProgressoEmMemoria();
    await registro.favoritar('adm-9999', true); // não existe em _unidades
    await registro.favoritar('adm-0101', true);
    await _abrir(tester, registro);

    expect(find.byKey(const Key('favorita-adm-0101')), findsOneWidget);
    expect(find.byKey(const Key('favorita-adm-9999')), findsNothing);
  });

  testWidgets('tocar numa favorita abre a revisão, já marcada', (tester) async {
    final registro = ProgressoEmMemoria();
    await registro.favoritar('adm-0101', true);
    await _abrir(tester, registro);

    await tester.tap(find.byKey(const Key('favorita-adm-0101')));
    await tester.pumpAndSettle();

    expect(find.text('Revisão da questão'), findsOneWidget);
    final botao = tester.widget<IconButton>(find.byKey(const Key('botao-favoritar')));
    expect((botao.icon as Icon).icon, Icons.star);
  });

  testWidgets('desmarcar na revisão some da lista ao voltar', (tester) async {
    final registro = ProgressoEmMemoria();
    await registro.favoritar('adm-0101', true);
    await _abrir(tester, registro);

    await tester.tap(find.byKey(const Key('favorita-adm-0101')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('botao-favoritar')));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('favorita-adm-0101')), findsNothing);
    expect(find.textContaining('Toque na estrela'), findsOneWidget);
  });
}
