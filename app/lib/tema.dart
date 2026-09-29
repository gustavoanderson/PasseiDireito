import 'package:flutter/material.dart';

/// As cores do mockup aprovado em 28/09/2026, nos dois modos.
///
/// Acerto, erro e dica não cabem no ColorScheme do Material, então moram
/// numa extensão do tema: qualquer tela pega com `Cores.de(context)`.
@immutable
class Cores extends ThemeExtension<Cores> {
  const Cores({
    required this.acerto,
    required this.acertoSuave,
    required this.acertoTexto,
    required this.erro,
    required this.erroSuave,
    required this.erroTexto,
    required this.dica,
    required this.dicaSuave,
    required this.dicaTexto,
    required this.sobreSelo,
    required this.alerta,
    required this.sobreAlerta,
  });

  final Color acerto;
  final Color acertoSuave;
  final Color acertoTexto;
  final Color erro;
  final Color erroSuave;
  final Color erroTexto;
  final Color dica;
  final Color dicaSuave;
  final Color dicaTexto;

  /// Cor do ícone (✓ ou ✗) dentro do selo preenchido de acerto ou erro.
  final Color sobreSelo;

  /// Flag de mudança na lei: violeta vivo, que não se confunde com dica, acerto ou erro.
  final Color alerta;
  final Color sobreAlerta;

  static Cores de(BuildContext context) => Theme.of(context).extension<Cores>()!;

  static const claro = Cores(
    acerto: Color(0xFF2B6A4B),
    acertoSuave: Color(0xFFE4F0E8),
    acertoTexto: Color(0xFF1E4D36),
    erro: Color(0xFFA3402C),
    erroSuave: Color(0xFFF7E6E1),
    erroTexto: Color(0xFF7E2F20),
    dica: Color(0xFFB87A1E),
    dicaSuave: Color(0xFFF6E9CF),
    dicaTexto: Color(0xFF5E3C0C),
    sobreSelo: Color(0xFFFFFFFF),
    alerta: Color(0xFF6D28D9),
    sobreAlerta: Color(0xFFFFFFFF),
  );

  static const escuro = Cores(
    acerto: Color(0xFF74C29A),
    acertoSuave: Color(0xFF18291F),
    acertoTexto: Color(0xFF9AD6B5),
    erro: Color(0xFFE4907E),
    erroSuave: Color(0xFF301D19),
    erroTexto: Color(0xFFF0B3A6),
    dica: Color(0xFFE2AA4A),
    dicaSuave: Color(0xFF33280F),
    dicaTexto: Color(0xFFF3CC85),
    sobreSelo: Color(0xFF11161C),
    alerta: Color(0xFFC4B5FD),
    sobreAlerta: Color(0xFF1E1033),
  );

  @override
  Cores copyWith() => this;

  @override
  Cores lerp(ThemeExtension<Cores>? other, double t) => this;
}

/// Dá a qualquer tela o botão de lua/sol sem passar callback de mão em mão.
class ControleTema extends InheritedWidget {
  const ControleTema({super.key, required this.alternar, required super.child});

  final void Function(Brightness atual) alternar;

  static void alternarEm(BuildContext context) {
    context.getInheritedWidgetOfExactType<ControleTema>()!.alternar(Theme.of(context).brightness);
  }

  @override
  bool updateShouldNotify(ControleTema oldWidget) => false;
}

/// O botão de lua/sol do cabeçalho. Lua no claro (vai para o escuro), sol no escuro.
class BotaoTema extends StatelessWidget {
  const BotaoTema({super.key});

  @override
  Widget build(BuildContext context) {
    final escuro = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      key: const Key('botao-tema'),
      tooltip: escuro ? 'Usar modo claro' : 'Usar modo escuro',
      icon: Icon(escuro ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      onPressed: () => ControleTema.alternarEm(context),
    );
  }
}

const fonteTexto = 'IBMPlexSans';
const fonteTitulo = 'SourceSerif4';

ThemeData temaClaro() => _tema(
      brilho: Brightness.light,
      fundo: const Color(0xFFF5F4F0),
      superficie: const Color(0xFFFFFFFF),
      texto: const Color(0xFF1C2330),
      textoSecundario: const Color(0xFF566072),
      borda: const Color(0xFFD9D7D0),
      primaria: const Color(0xFF1F3A5F),
      sobrePrimaria: const Color(0xFFFFFFFF),
      primariaSuave: const Color(0xFFE6EDF6),
      cores: Cores.claro,
    );

ThemeData temaEscuro() => _tema(
      brilho: Brightness.dark,
      fundo: const Color(0xFF14171C),
      superficie: const Color(0xFF1C2128),
      texto: const Color(0xFFE6E8EB),
      textoSecundario: const Color(0xFFA0A8B4),
      borda: const Color(0xFF2F3640),
      primaria: const Color(0xFF8DB1DE),
      sobrePrimaria: const Color(0xFF0E1622),
      primariaSuave: const Color(0xFF1F2B3A),
      cores: Cores.escuro,
    );

ThemeData _tema({
  required Brightness brilho,
  required Color fundo,
  required Color superficie,
  required Color texto,
  required Color textoSecundario,
  required Color borda,
  required Color primaria,
  required Color sobrePrimaria,
  required Color primariaSuave,
  required Cores cores,
}) {
  final esquema = ColorScheme(
    brightness: brilho,
    primary: primaria,
    onPrimary: sobrePrimaria,
    primaryContainer: primariaSuave,
    onPrimaryContainer: primaria,
    secondary: cores.dica,
    onSecondary: cores.dicaTexto,
    error: cores.erro,
    onError: cores.sobreSelo,
    surface: superficie,
    onSurface: texto,
    onSurfaceVariant: textoSecundario,
    outline: borda,
  );
  return ThemeData(
    colorScheme: esquema,
    fontFamily: fonteTexto,
    scaffoldBackgroundColor: fundo,
    // Leitura em primeiro lugar: enunciado a 18 e alternativas a 16, como no mockup.
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 18, height: 1.55, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(fontSize: 15.5, height: 1.55),
    ).apply(bodyColor: texto, displayColor: texto),
    extensions: [cores],
  );
}
