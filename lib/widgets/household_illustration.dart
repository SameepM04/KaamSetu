import 'package:flutter/material.dart';

/// Procedurally painted illustration for the Household Sign Up screen —
/// a two-storey house with a balcony, in front of a soft city skyline,
/// matching the approved design reference. Built the same way the other
/// onboarding illustrations in this app are built (CustomPainter, no
/// external asset), so it scales crisply at any size.
class HouseholdIllustration extends StatelessWidget {
  const HouseholdIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: _HouseholdPainter(), child: const SizedBox.expand());
  }
}

class _HouseholdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Distant city skyline silhouette.
    final skyline = Paint()..color = const Color(0xFFD7E6FA);
    void block(double x, double y, double bw, double bh) {
      canvas.drawRect(Rect.fromLTWH(x, y, bw, bh), skyline);
    }

    block(w * .02, h * .28, w * .10, h * .40);
    block(w * .14, h * .18, w * .09, h * .50);
    block(w * .80, h * .22, w * .09, h * .46);
    block(w * .90, h * .32, w * .09, h * .36);

    // Clouds.
    final cloud = Paint()..color = Colors.white.withValues(alpha: .9);
    void puff(double cx, double cy, double r) =>
        canvas.drawCircle(Offset(cx, cy), r, cloud);
    puff(w * .16, h * .10, w * .028);
    puff(w * .20, h * .095, w * .034);
    puff(w * .24, h * .10, w * .026);
    puff(w * .70, h * .06, w * .024);
    puff(w * .735, h * .055, w * .03);
    puff(w * .77, h * .06, w * .022);

    // Birds (simple v-marks).
    final bird = Paint()
      ..color = const Color(0xFF9FB7D9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    void drawBird(double x, double y, double s) {
      final path = Path()
        ..moveTo(x - s, y)
        ..quadraticBezierTo(x - s / 2, y - s * .8, x, y)
        ..quadraticBezierTo(x + s / 2, y - s * .8, x + s, y);
      canvas.drawPath(path, bird);
    }

    drawBird(w * .30, h * .05, w * .018);
    drawBird(w * .36, h * .035, w * .014);
    drawBird(w * .58, h * .04, w * .016);

    // Ground.
    final ground = Paint()
      ..color = const Color(0xFFEFE3C8).withValues(alpha: .55);
    canvas.drawRect(Rect.fromLTWH(0, h * .88, w, h * .12), ground);

    // House body.
    final houseLeft = w * .18;
    final houseRight = w * .82;
    final houseTop = h * .40;
    final houseBottom = h * .90;
    final wallPaint = Paint()..color = Colors.white;
    final wallRect =
        Rect.fromLTRB(houseLeft, houseTop, houseRight, houseBottom);
    canvas.drawRRect(
        RRect.fromRectAndCorners(wallRect,
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4)),
        wallPaint);

    // Roof.
    final roofPaint = Paint()..color = const Color(0xFF1E3A5F);
    final roofPath = Path()
      ..moveTo(houseLeft - w * .04, houseTop + h * .01)
      ..lineTo((houseLeft + houseRight) / 2, houseTop - h * .17)
      ..lineTo(houseRight + w * .04, houseTop + h * .01)
      ..lineTo(houseRight + w * .02, houseTop + h * .045)
      ..lineTo((houseLeft + houseRight) / 2, houseTop - h * .12)
      ..lineTo(houseLeft - w * .02, houseTop + h * .045)
      ..close();
    canvas.drawPath(roofPath, roofPaint);

    // Chimney.
    final chimney = Paint()..color = const Color(0xFF1E3A5F);
    canvas.drawRect(
        Rect.fromLTWH(
            houseRight - w * .13, houseTop - h * .12, w * .035, h * .085),
        chimney);

    // Balcony (upper level) — recessed with railing.
    final balconyRect = Rect.fromLTWH(
        houseLeft + w * .08, houseTop + h * .015, w * .30, h * .16);
    canvas.drawRect(balconyRect, Paint()..color = const Color(0xFFEFF4FB));
    final rail = Paint()
      ..color = const Color(0xFF1E3A5F)
      ..strokeWidth = 1.4;
    canvas.drawRect(
        balconyRect,
        Paint()
          ..color = const Color(0xFF1E3A5F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
    for (var i = 1; i < 5; i++) {
      final x = balconyRect.left + balconyRect.width * i / 5;
      canvas.drawLine(
          Offset(x, balconyRect.top), Offset(x, balconyRect.bottom), rail);
    }

    // Upper window (right of balcony).
    _window(
        canvas,
        Rect.fromLTWH(
            houseRight - w * .20, houseTop + h * .03, w * .11, h * .12));

    // Lower windows either side of the door.
    _window(
        canvas,
        Rect.fromLTWH(
            houseLeft + w * .06, houseTop + h * .32, w * .13, h * .14));
    _window(
        canvas,
        Rect.fromLTWH(
            houseRight - w * .19, houseTop + h * .32, w * .13, h * .14));

    // Door.
    final doorRect = Rect.fromLTWH((houseLeft + houseRight) / 2 - w * .055,
        houseBottom - h * .22, w * .11, h * .22);
    final doorPaint = Paint()..color = const Color(0xFF1E3A5F);
    canvas.drawRRect(
      RRect.fromRectAndCorners(doorRect,
          topLeft: Radius.circular(w * .05),
          topRight: Radius.circular(w * .05)),
      doorPaint,
    );
    canvas.drawCircle(
        Offset(doorRect.right - w * .015, doorRect.top + doorRect.height * .5),
        1.6,
        Paint()..color = const Color(0xFFE8B14A));

    // Steps.
    canvas.drawRect(
        Rect.fromLTWH(doorRect.left - w * .015, houseBottom,
            doorRect.width + w * .03, h * .015),
        Paint()..color = const Color(0xFFD9D2C2));

    // Bushes / trees either side of the house.
    final bush = Paint()..color = const Color(0xFF6BB56B);
    void bushCluster(double cx, double cy, double r) {
      canvas.drawCircle(Offset(cx - r * .6, cy), r * .6, bush);
      canvas.drawCircle(Offset(cx + r * .6, cy), r * .6, bush);
      canvas.drawCircle(Offset(cx, cy - r * .3), r * .75, bush);
    }

    bushCluster(houseLeft + w * .02, houseBottom - h * .01, w * .035);
    bushCluster(houseRight - w * .02, houseBottom - h * .01, w * .035);

    // Small trees framing the scene.
    _tree(canvas, w * .10, houseBottom - h * .02, w * .11,
        const Color(0xFF4E9A52));
    _tree(canvas, w * .90, houseBottom - h * .02, w * .10,
        const Color(0xFF4E9A52));

    // Picket fence.
    final fence = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var x = houseLeft - w * .02;
        x <= houseRight + w * .02;
        x += w * .028) {
      canvas.drawLine(Offset(x, houseBottom + h * .01),
          Offset(x, houseBottom - h * .02), fence);
    }
  }

  void _window(Canvas canvas, Rect rect) {
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = const Color(0xFF1E3A5F));
    final inset = rect.deflate(rect.width * .10);
    canvas.drawRect(inset, Paint()..color = const Color(0xFF6FC1F5));
    final grid = Paint()
      ..color = const Color(0xFFE8A23A)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(inset.center.dx, inset.top),
        Offset(inset.center.dx, inset.bottom), grid);
    canvas.drawLine(Offset(inset.left, inset.center.dy),
        Offset(inset.right, inset.center.dy), grid);
  }

  void _tree(Canvas canvas, double cx, double baseY, double r, Color color) {
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(cx, baseY - r * .12),
            width: r * .12,
            height: r * .3),
        Paint()..color = const Color(0xFF8A6A46));
    canvas.drawCircle(
        Offset(cx, baseY - r * .55), r * .5, Paint()..color = color);
    canvas.drawCircle(
        Offset(cx - r * .3, baseY - r * .4), r * .32, Paint()..color = color);
    canvas.drawCircle(
        Offset(cx + r * .3, baseY - r * .4), r * .32, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
