import 'package:flutter/material.dart';

/// Le triangle multicolore de Google Play, dessiné en vectoriel (aucun fichier
/// image) à partir d'un dessin de 48 × 54.
class GooglePlayMark extends StatelessWidget {
  final double height;
  const GooglePlayMark({super.key, this.height = 36});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: height * 48 / 54,
        height: height,
        child: CustomPaint(painter: _PlayMarkPainter()),
      );
}

class _PlayMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 54);
    Paint fill(int argb) => Paint()
      ..color = Color(argb)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final blue = Path()
      ..moveTo(2, 2.5)
      ..relativeLineTo(0, 49)
      ..relativeCubicTo(0, 1.2, 1.3, 1.9, 2.3, 1.3)
      ..lineTo(26, 27)
      ..close();
    final green = Path()
      ..moveTo(33.5, 19.6)
      ..lineTo(7, 1.8)
      ..cubicTo(5.7, 0.9, 4, 1, 2.7, 2.2)
      ..lineTo(26, 27)
      ..close();
    final red = Path()
      ..moveTo(33.5, 34.4)
      ..lineTo(26, 27)
      ..lineTo(2.7, 51.8)
      ..relativeCubicTo(1.3, 1.2, 3, 1.3, 4.3, 0.4)
      ..close();
    final yellow = Path()
      ..moveTo(45.2, 24.4)
      ..lineTo(33.5, 19.6)
      ..lineTo(26, 27)
      ..relativeLineTo(7.5, 7.4)
      ..relativeLineTo(11.7, -4.8)
      ..relativeCubicTo(2.2, -1.2, 2.2, -4.1, 0, -5.2)
      ..close();

    canvas.drawPath(blue, fill(0xFF00D3FF));
    canvas.drawPath(green, fill(0xFF00F076));
    canvas.drawPath(red, fill(0xFFFF3A44));
    canvas.drawPath(yellow, fill(0xFFFFC400));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Un badge « Disponible sur Google Play » dessiné dans l'application : un
/// pavé noir à bord gris, le triangle, une petite ligne puis « Google Play ».
/// Ce n'est pas le fichier officiel de Google : on le remplace par lui quand on
/// le fournit.
class GooglePlayBadge extends StatelessWidget {
  /// La petite ligne au-dessus, par exemple « DISPONIBLE SUR ».
  final String topLine;
  final double scale;
  const GooglePlayBadge({super.key, required this.topLine, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10 * scale, 6 * scale, 14 * scale, 6 * scale),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(9 * scale),
        border: Border.all(color: const Color(0xFFA6A6A6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GooglePlayMark(height: 26 * scale),
          SizedBox(width: 8 * scale),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                topLine,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8.5 * scale,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                  height: 1.1,
                ),
              ),
              Text(
                'Google Play',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19 * scale,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
