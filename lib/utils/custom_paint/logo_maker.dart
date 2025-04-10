import 'package:flutter/material.dart';

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw the background (optional)
    paint.color = Colors.white;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 1.5, paint);

    // Draw the barcode section (adjust line width and spacing)
    paint.color = Colors.black;
    paint.strokeWidth = 2;
    for (double i = 0; i < size.width / 2; i += 5) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw the "Expire" text
    paint.color = Colors.red;
    paint.style = PaintingStyle.fill;  // Set to fill for solid text
    const textStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: Colors.red,
      wordSpacing: 2,
    );
    final textPainter = TextPainter(
      text: const TextSpan(text: "Expired Tracker", style: textStyle),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: size.width / 2);
    textPainter.paint(canvas, Offset(size.width / 2, size.height / 3));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}