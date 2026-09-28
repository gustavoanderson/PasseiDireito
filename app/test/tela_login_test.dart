import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/tela_login.dart';
import 'package:passeidireito/tema.dart';

Future<void> _abrir(
  WidgetTester tester, {
  required Future<void> Function(String, String) entrar,
  Future<void> Function(String)? recuperar,
}) async {
  await tester.pumpWidget(MaterialApp(
    theme: temaClaro(),
    home: TelaLogin(entrar: entrar, recuperarSenha: recuperar ?? (_) async {}),
  ));
}

void main() {
  testWidgets('entrar envia o e-mail sem espaços e a senha como digitada', (tester) async {
    String? email;
    String? senha;
    await _abrir(tester, entrar: (e, s) async {
      email = e;
      senha = s;
    });

    await tester.enterText(find.byKey(const Key('campo-email')), '  flavia@exemplo.com ');
    await tester.enterText(find.byKey(const Key('campo-senha')), ' senha com espaço ');
    await tester.tap(find.byKey(const Key('botao-entrar')));
    await tester.pump();

    expect(email, 'flavia@exemplo.com');
    expect(senha, ' senha com espaço ');
  });

  testWidgets('falha ao entrar mostra a mensagem e deixa tentar de novo', (tester) async {
    await _abrir(tester, entrar: (_, _) async => throw 'E-mail ou senha incorretos.');

    await tester.tap(find.byKey(const Key('botao-entrar')));
    await tester.pump();

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
    final botao = tester.widget<FilledButton>(find.byKey(const Key('botao-entrar')));
    expect(botao.onPressed, isNotNull);
  });

  testWidgets('esqueci a senha confirma o envio do e-mail', (tester) async {
    String? pedido;
    await _abrir(tester, entrar: (_, _) async {}, recuperar: (e) async => pedido = e);

    await tester.enterText(find.byKey(const Key('campo-email')), 'flavia@exemplo.com');
    await tester.tap(find.byKey(const Key('botao-esqueci')));
    await tester.pump();

    expect(pedido, 'flavia@exemplo.com');
    expect(find.text('Enviamos um e-mail para redefinir a senha.'), findsOneWidget);
  });
}
