import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ConnectionIllustration extends StatelessWidget {
  const ConnectionIllustration({super.key});

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _ConnectionPainter(), child: const SizedBox.expand());
}

class _ConnectionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final left = Offset(size.width * .23, size.height * .55);
    final right = Offset(size.width * .77, size.height * .55);
    final radius = math.min(size.width * .21, size.height * .34);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(left, radius, ring..color = const Color(0xFF4C81FA));
    canvas.drawCircle(right, radius, ring..color = const Color(0xFFFFAB68));
    canvas.drawCircle(
        left, radius - 5, Paint()..color = const Color(0xFFCCDEFF));
    canvas.drawCircle(
        right, radius - 5, Paint()..color = const Color(0xFFFFE4CD));
    final worker = Paint()..color = const Color(0xFF245BCB);
    canvas.drawCircle(
        Offset(left.dx, left.dy - radius * .32), radius * .2, worker);
    final body = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(left.dx, left.dy + radius * .26),
            width: radius * .85,
            height: radius * .77),
        Radius.circular(radius * .35));
    canvas.drawRRect(body, worker);
    final helmet = Path()
      ..addArc(
          Rect.fromCircle(
              center: Offset(left.dx, left.dy - radius * .41),
              radius: radius * .28),
          math.pi,
          math.pi)
      ..lineTo(left.dx + radius * .28, left.dy - radius * .38)
      ..lineTo(left.dx - radius * .28, left.dy - radius * .38)
      ..close();
    canvas.drawPath(helmet, Paint()..color = const Color(0xFF6FA3FF));
    final house = Paint()..color = const Color(0xFFFF8B33);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(right.dx, right.dy + radius * .15),
                width: radius * .95,
                height: radius * .75),
            Radius.circular(9)),
        house);
    final roof = Path()
      ..moveTo(right.dx - radius * .65, right.dy - radius * .12)
      ..lineTo(right.dx, right.dy - radius * .75)
      ..lineTo(right.dx + radius * .65, right.dy - radius * .12)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFFE75E16));
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(right.dx, right.dy + radius * .36),
            width: radius * .2,
            height: radius * .38),
        Paint()..color = Colors.white);
    final dashed = Paint()
      ..color = AppColors.electricBlue
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
          Offset(size.width * (.44 + i * .024), size.height * .56),
          i == 0 ? 9 : 3.5,
          dashed);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HandsIllustration extends StatelessWidget {
  const HandsIllustration({super.key, required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: _HandsPainter(progress), child: const SizedBox.expand());
}

class _HandsPainter extends CustomPainter {
  _HandsPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final blueX = size.width * (-.05 + progress * .25);
    final orangeX = size.width * (1.05 - progress * .25);
    final y = size.height * .56;
    final center = Offset(size.width * .5, y);
    final glowRadius = 22 + progress * 62;
    canvas.drawCircle(
        center,
        glowRadius,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFD165).withValues(alpha: .8 * progress),
            const Color(0x00FFD165)
          ]).createShader(Rect.fromCircle(center: center, radius: glowRadius)));
    final left = Path()
      ..moveTo(blueX - size.width * .16, y + size.height * .18)
      ..lineTo(blueX + size.width * .09, y + size.height * .18)
      ..quadraticBezierTo(blueX + size.width * .17, y + size.height * .13,
          blueX + size.width * .12, y + size.height * .07)
      ..lineTo(blueX + size.width * .035, y - size.height * .05)
      ..lineTo(blueX + size.width * .22, y + size.height * .07)
      ..quadraticBezierTo(blueX + size.width * .28, y + size.height * .1,
          blueX + size.width * .3, y + size.height * .06)
      ..quadraticBezierTo(blueX + size.width * .32, y, blueX + size.width * .25,
          y - size.height * .04)
      ..lineTo(blueX + size.width * .08, y - size.height * .19)
      ..quadraticBezierTo(blueX, y - size.height * .26,
          blueX - size.width * .07, y - size.height * .18)
      ..lineTo(blueX - size.width * .16, y - size.height * .04)
      ..close();
    canvas.drawPath(left, Paint()..color = const Color(0xFF3E7CEB));
    final right = Path()
      ..moveTo(orangeX + size.width * .16, y + size.height * .18)
      ..lineTo(orangeX - size.width * .09, y + size.height * .18)
      ..quadraticBezierTo(orangeX - size.width * .17, y + size.height * .13,
          orangeX - size.width * .12, y + size.height * .07)
      ..lineTo(orangeX - size.width * .035, y - size.height * .05)
      ..lineTo(orangeX - size.width * .22, y + size.height * .07)
      ..quadraticBezierTo(orangeX - size.width * .28, y + size.height * .1,
          orangeX - size.width * .3, y + size.height * .06)
      ..quadraticBezierTo(orangeX - size.width * .32, y,
          orangeX - size.width * .25, y - size.height * .04)
      ..lineTo(orangeX - size.width * .08, y - size.height * .19)
      ..quadraticBezierTo(orangeX, y - size.height * .26,
          orangeX + size.width * .07, y - size.height * .18)
      ..lineTo(orangeX + size.width * .16, y - size.height * .04)
      ..close();
    canvas.drawPath(right, Paint()..color = const Color(0xFFFF8A30));
    for (var i = 0; i < 14; i++) {
      final angle = i / 14 * math.pi * 2;
      final radius = glowRadius * (.55 + (i % 3) * .18);
      final p =
          center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      canvas.drawCircle(p, 1.6 + progress * 2.1,
          Paint()..color = const Color(0xFFFFD471).withValues(alpha: progress));
    }
  }

  @override
  bool shouldRepaint(covariant _HandsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class HandshakeIllustration extends StatelessWidget {
  const HandshakeIllustration({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _HandshakePainter(), child: const SizedBox.expand());
}

class _HandshakePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * .5, size.height * .5);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
          center,
          58 + i * 28,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color =
                const Color(0xFFFFD479).withValues(alpha: .28 - i * .045));
    }
    canvas.drawCircle(Offset(center.dx, center.dy - 53), 25,
        Paint()..color = const Color(0xFFFDE0A4).withValues(alpha: .9));
    final pin = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(center.dx, center.dy - 57), radius: 15))
      ..moveTo(center.dx - 12, center.dy - 47)
      ..lineTo(center.dx, center.dy - 24)
      ..lineTo(center.dx + 12, center.dy - 47)
      ..close();
    canvas.drawPath(pin, Paint()..color = Colors.white);
    final blue = Path()
      ..moveTo(-20, size.height * .63)
      ..lineTo(size.width * .38, size.height * .45)
      ..lineTo(size.width * .59, size.height * .61)
      ..lineTo(size.width * .48, size.height * .78)
      ..lineTo(size.width * .3, size.height * .68)
      ..lineTo(-20, size.height * .82)
      ..close();
    canvas.drawPath(blue, Paint()..color = const Color(0xFF3979EA));
    final orange = Path()
      ..moveTo(size.width + 20, size.height * .62)
      ..lineTo(size.width * .62, size.height * .45)
      ..lineTo(size.width * .41, size.height * .61)
      ..lineTo(size.width * .52, size.height * .78)
      ..lineTo(size.width * .7, size.height * .68)
      ..lineTo(size.width + 20, size.height * .82)
      ..close();
    canvas.drawPath(orange, Paint()..color = const Color(0xFFFF8C32));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(center.dx, size.height * .64),
                width: size.width * .25,
                height: size.height * .17),
            const Radius.circular(30)),
        Paint()..color = const Color(0xFFF2B18A));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
