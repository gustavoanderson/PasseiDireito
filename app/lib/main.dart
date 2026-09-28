import 'package:flutter/material.dart';

import 'banco.dart';
import 'tela_inicio.dart';
import 'tema.dart';

void main() {
  runApp(const PasseiDireito());
}

class PasseiDireito extends StatefulWidget {
  const PasseiDireito({super.key, this.carregar = carregarUnidades});

  /// Trocável nos testes, para não depender da leitura do banco real.
  final Future<List<Unidade>> Function() carregar;

  @override
  State<PasseiDireito> createState() => _PasseiDireitoState();
}

class _PasseiDireitoState extends State<PasseiDireito> {
  // Segue o celular até ela tocar no botão de lua/sol; daí em diante vale a escolha dela.
  ThemeMode _modo = ThemeMode.system;

  void _alternar(Brightness atual) {
    setState(() => _modo = atual == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
  }

  @override
  Widget build(BuildContext context) {
    return ControleTema(
      alternar: _alternar,
      child: MaterialApp(
        title: 'PasseiDireito',
        theme: temaClaro(),
        darkTheme: temaEscuro(),
        themeMode: _modo,
        home: TelaInicio(carregar: widget.carregar),
      ),
    );
  }
}
