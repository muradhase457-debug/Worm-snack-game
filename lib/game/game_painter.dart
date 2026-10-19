import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'engine.dart';

/// V2 painter: real snake style - striped body, eyes, flickering tongue,
/// emoji face, name labels, food emojis, grid, red border, camera follow.
class WormGamePainter extends CustomPainter {
  final WormGameEngine engine;
  final Size screenSize;

  WormGamePainter({required this.engine, required this.screenSize});

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF232323),
    );

    canvas.save();
    // Camera
    final camX = engine.cameraX - size.width / 2;
    final camY = engine.cameraY - size.height / 2;
    canvas.translate(-camX, -camY);

    final ws = engine.worldSize;

    // World fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, ws, ws),
      Paint()
        ..color = const Color(0xFF333333)
        ..style = PaintingStyle.fill,
    );
    // Red border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, ws, ws),
      Paint()
        ..color = Colors.redAccent.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (double x = 0; x <= ws; x += 160) {
      canvas.drawLine(Offset(x, 0), Offset(x, ws), gridPaint);
    }
    for (double y = 0; y <= ws; y += 160) {
      canvas.drawLine(Offset(0, y), Offset(ws, y), gridPaint);
    }

    // Foods - only draw visible ones
    final visible = Rect.fromLTWH(camX - 60, camY - 60, size.width + 120, size.height + 120);
    for (final food in engine.foods) {
      if (!visible.contains(Offset(food.x, food.y))) continue;
      if (food.isCoin) {
        canvas.drawCircle(
          Offset(food.x, food.y),
          20,
          Paint()..color = Colors.amber.withOpacity(0.35),
        );
      }
      _drawEmoji(canvas, food.emoji, Offset(food.x, food.y), food.radius * 2.2);
    }

    // Worms - bots first, player last (on top)
    final worms = [...engine.bots.where((b) => b.alive), engine.player];
    for (final worm in worms) {
      _drawWorm(canvas, worm, visible);
    }

    canvas.restore();
  }

  void _drawWorm(Canvas canvas, Worm worm, Rect visible) {
    // Draw from tail to head
    for (int i = worm.points.length - 1; i >= 0; i--) {
      final p = worm.points[i];
      if (!visible.contains(p)) continue;
      final isHead = i == 0;
      final radius = isHead ? 18.0 : 12.5;
      final color = worm.colorAt(i);
      // Glow for player
      if (worm.isPlayer) {
        canvas.drawCircle(p, radius + 3, Paint()..color = Colors.white.withOpacity(0.12));
      }
      canvas.drawCircle(p, radius, Paint()..color = color);
      // Real snake stripes: every 3rd segment gets a darker band.
      if (!isHead && i % 3 == 0) {
        canvas.drawCircle(
          p,
          radius * 0.92,
          Paint()..color = Colors.black.withOpacity(0.18),
        );
      }
      // Subtle ring
      canvas.drawCircle(
        p,
        radius,
        Paint()
          ..color = Colors.black.withOpacity(0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    _drawHead(canvas, worm, visible);
  }

  void _drawHead(Canvas canvas, Worm worm, Rect visible) {
    final head = worm.points.first;
    if (!visible.contains(head)) return;
    final angle = worm.angle;
    final fx = cos(angle);
    final fy = sin(angle);
    // Perpendicular direction for eye placement
    final px = -fy;
    final py = fx;

    // Tongue: red forked line flickering out of the mouth.
    final flick = (worm.points.length % 4 < 2) ? 1.0 : 0.6;
    final tongueLen = 13 * flick + 4;
    final mouthX = head.dx + fx * 14;
    final mouthY = head.dy + fy * 14;
    final tipX = head.dx + fx * (14 + tongueLen);
    final tipY = head.dy + fy * (14 + tongueLen);
    final tonguePaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    // Fork
    final fork = 0.35;
    canvas.drawLine(
      Offset(mouthX, mouthY),
      Offset(
        tipX + cos(angle + fork) * 6,
        tipY + sin(angle + fork) * 6,
      ),
      tonguePaint,
    );
    canvas.drawLine(
      Offset(mouthX, mouthY),
      Offset(
        tipX + cos(angle - fork) * 6,
        tipY + sin(angle - fork) * 6,
      ),
      tonguePaint,
    );

    // Eyes: two white circles with black pupils, looking where it goes.
    for (final side in [-1.0, 1.0]) {
      final ex = head.dx + fx * 6 + px * 7 * side;
      final ey = head.dy + fy * 6 + py * 7 * side;
      canvas.drawCircle(Offset(ex, ey), 5.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        Offset(ex + fx * 2, ey + fy * 2),
        2.5,
        Paint()..color = Colors.black,
      );
    }

    // Emoji face on head
    _drawEmoji(canvas, worm.faceEmoji, Offset(head.dx - fx * 2, head.dy - fy * 2 + 1), 20);

    // Name above head
    final tp = TextPainter(
      text: TextSpan(
        text: worm.isPlayer ? 'You' : worm.name,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 13,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(head.dx - tp.width / 2, head.dy - 40));
  }

  void _drawEmoji(Canvas canvas, String emoji, Offset pos, double size) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: TextStyle(fontSize: size)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant WormGamePainter oldDelegate) => true;
}
