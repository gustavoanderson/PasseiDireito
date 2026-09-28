import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/main.dart';
import 'package:passeidireito/tema.dart';

void main() {
  testWidgets('o app abre seguindo o modo do celular', (tester) async {
    await tester.pumpWidget(const PasseiDireito());
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.system);
  });

  testWidgets('o botão de lua/sol troca o modo e a troca vale para o app', (tester) async {
    await tester.pumpWidget(PasseiDireito(carregar: () async => []));
    await tester.pumpAndSettle();
    // No teste, o "celular" está no modo claro: o botão leva ao escuro.
    await tester.tap(find.byKey(const Key('botao-tema')));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);

    await tester.tap(find.byKey(const Key('botao-tema')));
    await tester.pumpAndSettle();
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.light);
  });

  test('os dois temas carregam as cores de acerto, erro e dica', () {
    expect(temaClaro().extension<Cores>(), Cores.claro);
    expect(temaEscuro().extension<Cores>(), Cores.escuro);
    expect(temaClaro().brightness, Brightness.light);
    expect(temaEscuro().brightness, Brightness.dark);
  });
}
