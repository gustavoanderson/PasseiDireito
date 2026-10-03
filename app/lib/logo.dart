import 'dart:math';

import 'package:flutter/material.dart';

/// O logo do PasseiDireito: o martelo do juiz batendo, e a fagulha da
/// pancada saindo como o "POW" dos quadrinhos.
///
/// Desenhado em código, e não com imagem: fica nítido em qualquer tamanho e
/// não precisa de pacote para SVG. O ícone do app é gerado deste mesmo desenho
/// (app/tool/gerar_icones_test.dart).
class LogoPasseiDireito extends StatelessWidget {
  const LogoPasseiDireito({super.key, this.tamanho = 40, this.comFundo = false});

  final double tamanho;

  /// Com o quadrado azul atrás: é a versão do ícone do app.
  final bool comFundo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PasseiDireito',
      image: true,
      child: CustomPaint(
        size: Size.square(tamanho),
        painter: PintorDoLogo(comFundo: comFundo, escuro: Theme.of(context).brightness == Brightness.dark),
      ),
    );
  }
}

class PintorDoLogo extends CustomPainter {
  PintorDoLogo({required this.comFundo, this.escuro = false});

  final bool comFundo;

  /// No fundo grafite, o contorno marinho sumiria: ele clareia.
  final bool escuro;

  static const _marinho = Color(0xFF1F3A5F);
  static const _marinhoClaro = Color(0xFF3E6391);
  static const _ambar = Color(0xFFE2AA4A);
  static const _ambarClaro = Color(0xFFF6E2B3);
  static const _madeira = Color(0xFF9A6A2F);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.scale(s);

    if (comFundo) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 1, 1), const Radius.circular(0.22)),
        Paint()..color = _marinho,
      );
      // Área útil menor, para o desenho não encostar na borda do ícone.
      canvas.translate(0.1, 0.1);
      canvas.scale(0.8);
    }

    const impacto = Offset(0.42, 0.63);
    final contorno = comFundo ? const Color(0xFF0E1B2C) : (escuro ? const Color(0xFF8DB1DE) : _marinho);

    // 1. A fagulha da pancada: estrela serrilhada em três camadas, em tons de
    // âmbar até o branco no centro — um lampejo, não uma explosão de fogo
    // (o Gustavo pediu para tirar o vermelho-terracota que tinha antes).
    canvas.drawPath(_estrela(impacto, 0.27, 0.17, 12, 0.08), Paint()..color = _ambar);
    canvas.drawPath(
      _estrela(impacto, 0.27, 0.17, 12, 0.08),
      Paint()
        ..color = contorno
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.022
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(_estrela(impacto, 0.185, 0.105, 10, 0.3), Paint()..color = _ambarClaro);
    canvas.drawPath(_estrela(impacto, 0.1, 0.055, 8, 0.1), Paint()..color = Colors.white);

    // 2. As fagulhas: riscos que saem do impacto, para longe do martelo.
    final fagulha = Paint()
      ..color = comFundo || escuro ? _ambar : _marinho
      ..strokeWidth = 0.028
      ..strokeCap = StrokeCap.round;
    for (final (angulo, de, ate) in [(150.0, 0.31, 0.39), (185.0, 0.32, 0.4), (220.0, 0.31, 0.38), (255.0, 0.31, 0.36)]) {
      final r = angulo * pi / 180;
      final dir = Offset(cos(r), -sin(r));
      canvas.drawLine(impacto + dir * de, impacto + dir * ate, fagulha);
    }

    // 3. O martelo: cabeça e cabo desenhados num eixo local (o cabo sai do
    // meio da cabeça; a cabeça é um cilindro deitado, com uma face em cada
    // ponta, em x = ±0.21). Giramos 38° e escalamos por 0.9 em torno de um
    // ponto escolhido para que a face DIREITA (x = 0.21, a ponta que bate)
    // caia exatamente no centro da fagulha — e não o meio da cabeça, como
    // estava antes (o Gustavo notou: "o impacto tem que sair da ponta que
    // bate, não de cima"). As constantes abaixo são impacto - 0.9 · R(38°) ·
    // (0.21, 0); mexer no ângulo ou na escala exige recalcular as duas.
    canvas.save();
    canvas.translate(0.2711, 0.5136);
    canvas.rotate(38 * pi / 180);
    canvas.scale(0.9);

    final tracado = Paint()
      ..color = contorno
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.022
      ..strokeJoin = StrokeJoin.round;

    // Cabo, saindo da cabeça para cima.
    final cabo = RRect.fromRectAndRadius(const Rect.fromLTWH(-0.04, -0.5, 0.08, 0.44), const Radius.circular(0.04));
    canvas.drawRRect(cabo, Paint()..color = _madeira);
    canvas.drawRRect(cabo, tracado);

    // Cabeça: corpo com as duas faces mais largas nas pontas.
    final corpo = RRect.fromRectAndRadius(const Rect.fromLTWH(-0.2, -0.085, 0.4, 0.17), const Radius.circular(0.03));
    canvas.drawRRect(corpo, Paint()..color = _marinhoClaro);
    canvas.drawRRect(corpo, tracado);
    for (final x in [-0.26, 0.16]) {
      final face = RRect.fromRectAndRadius(Rect.fromLTWH(x, -0.12, 0.1, 0.24), const Radius.circular(0.035));
      canvas.drawRRect(face, Paint()..color = _marinho);
      canvas.drawRRect(face, tracado);
    }
    // Brilho discreto no corpo.
    canvas.drawLine(
      const Offset(-0.12, -0.035),
      const Offset(0.1, -0.035),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 0.018
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();

    canvas.restore();
  }

  /// Estrela de [pontas] pontas alternando raio externo e interno, com um
  /// giro [fase] (em fração de volta) para as camadas não ficarem alinhadas.
  Path _estrela(Offset c, double externo, double interno, int pontas, double fase) {
    final p = Path();
    for (var i = 0; i < pontas * 2; i++) {
      // Pontas levemente irregulares, como o desenho de quadrinho.
      final irregular = i.isEven ? (i % 4 == 0 ? 1.0 : 0.88) : 1.0;
      final r = (i.isEven ? externo * irregular : interno);
      final a = (i / (pontas * 2) + fase) * 2 * pi;
      final ponto = c + Offset(cos(a), sin(a)) * r;
      i == 0 ? p.moveTo(ponto.dx, ponto.dy) : p.lineTo(ponto.dx, ponto.dy);
    }
    return p..close();
  }

  @override
  bool shouldRepaint(PintorDoLogo antigo) => antigo.comFundo != comFundo || antigo.escuro != escuro;
}
