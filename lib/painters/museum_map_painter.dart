import 'package:flutter/material.dart';

import '../theme.dart';

class MuseumMapPainter extends CustomPainter {
  const MuseumMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = GemColors.map);
    final line = Paint()
      ..color = GemColors.mapLine
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final thin = Paint()
      ..color = GemColors.mapGrid
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final blocks = Paint()
      ..color = const Color(0x22ffffff)
      ..style = PaintingStyle.fill;

    for (var x = -size.height; x < size.width + size.height; x += 35) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), thin);
    }

    final central = Path()
      ..moveTo(size.width * .05, size.height * .34)
      ..lineTo(size.width * .72, size.height * .22)
      ..lineTo(size.width * .93, size.height * .58)
      ..lineTo(size.width * .26, size.height * .77)
      ..close();
    canvas.drawPath(central, blocks);
    canvas.drawPath(central, line);
    canvas.drawLine(
      Offset(size.width * .16, size.height * .52),
      Offset(size.width * .75, size.height * .42),
      line,
    );
    canvas.drawLine(
      Offset(size.width * .43, size.height * .15),
      Offset(size.width * .46, size.height * .82),
      line,
    );

    _label(canvas, 'ROYAL COURT', Offset(size.width * .11, size.height * .40));
    _label(canvas, 'GALLERY 2', Offset(size.width * .54, size.height * .30));
    _label(canvas, 'GRAND HALL', Offset(size.width * .33, size.height * .66));

    final pin = Offset(size.width * .56, size.height * .52);
    canvas.drawCircle(
      pin,
      28,
      Paint()..color = GemColors.teal.withValues(alpha: .16),
    );
    canvas.drawCircle(pin, 22, Paint()..color = GemColors.teal);
    canvas.drawCircle(pin, 8, Paint()..color = GemColors.gold);
  }

  void _label(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Arial',
          fontSize: 11,
          letterSpacing: 1.4,
          color: GemColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant MuseumMapPainter oldDelegate) => false;
}
