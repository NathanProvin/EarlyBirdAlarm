import 'package:flutter/material.dart';

/// The bird of each theme, drawn in its plumage: colors of the body, belly, wing, cap,
/// cheek (or null), beak, and an eye ring (or null).
typedef Plumage = ({
  Color body,
  Color belly,
  Color wing,
  Color cap,
  Color? cheek,
  Color beak,
  Color? eyeRing,
});

const plumages = <String, Plumage>{
  'blackbird': (
    body: Color(0xFF141618),
    belly: Color(0xFF1B1E21),
    wing: Color(0xFF2A2E33),
    cap: Color(0xFF141618),
    cheek: null,
    beak: Color(0xFFE8A33D),
    eyeRing: Color(0xFFE8A33D),
  ),
  'serin': (
    body: Color(0xFFB8C043),
    belly: Color(0xFFF2D43A),
    wing: Color(0xFF5F7A34),
    cap: Color(0xFFE6D63B),
    cheek: null,
    beak: Color(0xFF8C8A7A),
    eyeRing: null,
  ),
  'bluetit': (
    body: Color(0xFF8DA65A),
    belly: Color(0xFFF2C94C),
    wing: Color(0xFF2F6DB5),
    cap: Color(0xFF2F6DB5),
    cheek: Color(0xFFFFFFFF),
    beak: Color(0xFF2B2B2B),
    eyeRing: null,
  ),
  // The Black-headed Gull (mouette rieuse): chocolate hood, red bill and legs.
  'gull': (
    body: Color(0xFFFFFFFF),
    belly: Color(0xFFFFFFFF),
    wing: Color(0xFFB9BEC4),
    cap: Color(0xFF4A3830), // the whole head: its hood
    cheek: null,
    beak: Color(0xFFB5442E),
    eyeRing: Color(0xFFFFFFFF),
  ),
};

/// A cute round bird facing right, drawn in a 100 × 100 box scaled to the canvas.
/// [flap] lifts the wing (radians, for animations); [asleep] closes its eye.
class BirdPainter extends CustomPainter {
  const BirdPainter(
    this.p, {
    required this.gull,
    this.flap = 0,
    this.asleep = false,
  });
  final Plumage p;
  final bool gull; // black wingtip, a hood over the whole head, red legs
  final double flap;
  final bool asleep;

  /// The plumage of the bird of [theme] ('blackbird', 'serin', 'bluetit', 'gull').
  static BirdPainter of(String theme, {double flap = 0, bool asleep = false}) =>
      BirdPainter(
        plumages[theme] ?? plumages['bluetit']!,
        gull: theme == 'gull',
        flap: flap,
        asleep: asleep,
      );

  @override
  void paint(Canvas canvas, Size size) {
    Paint fill(Color c) => Paint()..color = c;
    canvas
      ..save()
      ..scale(size.width / 100, size.height / 100)
      // Tail, body, belly.
      ..drawPath(
        Path()..addPolygon(const [
          Offset(26, 60),
          Offset(6, 70),
          Offset(10, 78),
          Offset(32, 70),
        ], true),
        fill(p.wing),
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(48, 62), width: 54, height: 40),
        fill(p.body),
      )
      ..drawOval(
        Rect.fromCenter(center: const Offset(56, 70), width: 36, height: 22),
        fill(p.belly),
      );
    // Wing, a little tilted.
    canvas
      ..save()
      ..translate(52, 54) // the shoulder: the wing lifts from there
      ..rotate(-0.25 - flap)
      ..translate(-10, 6)
      ..drawOval(
        Rect.fromCenter(center: Offset.zero, width: 36, height: 20),
        fill(p.wing),
      );
    if (gull) {
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(-15, 1), width: 10, height: 12),
        fill(const Color(0xFF1C1B1A)),
      );
    }
    canvas.restore();
    // Head with its cap (the top of the head), cheek, eye, beak, legs.
    const head = Offset(70, 40);
    canvas
      ..drawCircle(head, 17, fill(gull ? p.cap : p.body))
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: head, radius: 17)))
      ..drawRect(const Rect.fromLTWH(50, 20, 40, 13), fill(p.cap))
      ..restore();
    if (p.cheek case final c?) {
      canvas.drawCircle(const Offset(72, 45), 8, fill(c));
    }
    if (p.eyeRing case final c?) {
      canvas.drawCircle(const Offset(76, 38), 5.5, fill(c));
    }
    if (asleep) {
      canvas.drawArc(
        Rect.fromCircle(center: const Offset(76, 37), radius: 3.8),
        0.2,
        2.7,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = const Color(0xFF111111),
      );
    } else {
      canvas
        ..drawCircle(const Offset(76, 38), 3.8, fill(const Color(0xFF111111)))
        ..drawCircle(const Offset(77.3, 36.8), 1.3, fill(Colors.white));
    }
    canvas.drawPath(
      Path()..addPolygon(const [
        Offset(85, 37),
        Offset(97, 41.5),
        Offset(85, 46),
      ], true),
      fill(p.beak),
    );
    final leg = Paint()
      ..color = gull ? p.beak : const Color(0xFF6B5E55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(44, 80), const Offset(42, 92), leg)
      ..drawLine(const Offset(55, 80), const Offset(55, 92), leg)
      ..restore();
  }

  @override
  bool shouldRepaint(BirdPainter oldDelegate) =>
      oldDelegate.flap != flap ||
      oldDelegate.asleep != asleep ||
      oldDelegate.p != p;
}
