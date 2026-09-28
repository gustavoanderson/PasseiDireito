import 'package:flutter/material.dart';

import 'tema.dart';

void main() {
  runApp(const PasseiDireito());
}

class PasseiDireito extends StatelessWidget {
  const PasseiDireito({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PasseiDireito',
      theme: temaClaro(),
      darkTheme: temaEscuro(),
      // Segue o celular por padrão. A chave manual chega com a tela de ajustes.
      themeMode: ThemeMode.system,
      home: const Scaffold(
        body: Center(child: Text('PasseiDireito')),
      ),
    );
  }
}
