import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/main.dart';
import 'package:passeidireito/tema.dart';

void main() {
  testWidgets('o app abre e segue o modo do celular', (tester) async {
    await tester.pumpWidget(const PasseiDireito());
    expect(find.text('PasseiDireito'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
  });

  test('os dois temas carregam as cores de acerto, erro e dica', () {
    expect(temaClaro().extension<Cores>(), Cores.claro);
    expect(temaEscuro().extension<Cores>(), Cores.escuro);
    expect(temaClaro().brightness, Brightness.light);
    expect(temaEscuro().brightness, Brightness.dark);
  });
}
