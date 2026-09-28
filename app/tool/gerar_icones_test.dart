// Gera os ícones do app (Android e web) a partir do desenho de lib/logo.dart.
//
// Não faz parte da suíte: fica fora de test/ e só roda quando chamado.
//   cd app && flutter test tool/gerar_icones_test.dart --update-goldens
//
// Usa o mecanismo de "golden" do flutter_test só para desenhar o widget num
// PNG de tamanho exato, sem depender de ferramenta de imagem instalada.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passeidireito/logo.dart';

const _marinho = Color(0xFF1F3A5F);

Future<void> _gerar(WidgetTester tester, String destino, int px, {bool mascaravel = false}) async {
  tester.view.physicalSize = Size(px.toDouble(), px.toDouble());
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final lado = px.toDouble();
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: RepaintBoundary(
        key: const Key('icone'),
        child: mascaravel
            // Ícone "maskable" da web: fundo cheio e desenho dentro da zona segura central.
            ? Container(
                width: lado,
                height: lado,
                color: _marinho,
                alignment: Alignment.center,
                child: LogoPasseiDireito(tamanho: lado * 0.8, comFundo: true),
              )
            : LogoPasseiDireito(tamanho: lado, comFundo: true),
      ),
    ),
  ));
  await expectLater(find.byKey(const Key('icone')), matchesGoldenFile(destino));
}

void main() {
  const res = '../android/app/src/main/res';
  for (final (pasta, px) in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]) {
    testWidgets('android $pasta', (t) => _gerar(t, '$res/mipmap-$pasta/ic_launcher.png', px));
  }
  testWidgets('web 192', (t) => _gerar(t, '../web/icons/Icon-192.png', 192));
  testWidgets('web 512', (t) => _gerar(t, '../web/icons/Icon-512.png', 512));
  testWidgets('web maskable 192', (t) => _gerar(t, '../web/icons/Icon-maskable-192.png', 192, mascaravel: true));
  testWidgets('web maskable 512', (t) => _gerar(t, '../web/icons/Icon-maskable-512.png', 512, mascaravel: true));
  testWidgets('favicon', (t) => _gerar(t, '../web/favicon.png', 32));
}
