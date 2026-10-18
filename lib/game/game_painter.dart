import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';
import 'engine.dart';

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

    // World border
    canvas.drawRect(
      Rect.fromLTWH(0, 0, WormGameEngine.worldSize, WormGameEngine.worldSize),
      Paint()
        ..color = const Color(0xFF333333)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, WormGameEngine.worldSize, WormGameEngine.worldSize),
      Paint()
        ..color = Colors.redAccent.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (double x = 0; x <= WormGameEngine.worldSize; x += 160) {
      canvas.drawLine(Offset(x, 0), Offset(x, WormGameEngine.worldSize), gridPaint);
    }
    for (double y = 0; y <= WormGameEngine.worldSize; y += 160) {
      canvas.drawLine(Offset(0, y), Offset(WormGameEngine.worldSize, y), gridPaint);
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

    // Worms - draw bots first, player last (on top)
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
      final radius = isHead ? 17.0 : 12.5;
      final color = worm.colorAt(i);
      // Glow for player
      if (worm.isPlayer) {
        canvas.drawCircle(p, radius + 3, Paint()..color = Colors.white.withOpacity(0.12));
      }
      canvas.drawCircle(p, radius, Paint()..color = color);
      // Subtle ring
      canvas.drawCircle(
        p,
        radius,
        Paint()
          ..color = Colors.black.withOpacity(0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      if (isHead) {
        // Face emoji on head
        _drawEmoji(canvas, worm.faceEmoji, p, 30);
      }
    }
    // Name above head
    final head = worm.points.first;
    if (visible.contains(head)) {
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
      tp.paint(canvas, Offset(head.dx - tp.width / 2, head.dy - 34));
    }
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
