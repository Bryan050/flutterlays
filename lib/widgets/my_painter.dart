import 'package:flutter/material.dart';

class MyPainter extends CustomPainter {
  String _text;
  Color _color;

  MyPainter(this._text, this._color);
  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint
    Paint paint = Paint();
    Paint paintBorder = Paint()
      ..color = Colors.black
      ..strokeWidth = size.width / 100
      ..style = PaintingStyle.stroke;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final RRect rRect = RRect.fromRectAndRadius(rect, Radius.circular(10));

    paint.color = Colors.white;
    canvas.drawRRect(rRect, paint);

    paint.color = this._color;

    canvas.drawCircle(Offset(20, size.height / 2), 10, paint);
    canvas.drawCircle(Offset(20, size.height / 2), 10, paintBorder);

    final textPainter = TextPainter(
        text: TextSpan(
            text: this._text,
            style: TextStyle(fontSize: 18, color: Colors.black)),
        maxLines: 2,
        textDirection: TextDirection.ltr);
    textPainter.layout(minWidth: 0, maxWidth: size.width - 20 - 20);
    textPainter.paint(
        canvas, Offset(40, size.height / 2 - textPainter.size.height / 2));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
