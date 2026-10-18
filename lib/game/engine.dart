import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';

class WormGameEngine {
  static const double worldSize = 3200;
  static const int questFoodTarget = 120;
  static const int questCoinTarget = 5;

  final Random _random = Random();
  late Worm player;
  List<Worm> bots = [];
  List<FoodItem> foods = [];
  double cameraX = 1600;
  double cameraY = 1600;
  bool gameOver = false;
  String deathReason = '';
  int coinsCollected = 0;
  int foodsEaten = 0;
  bool questFoodDone = false;
  bool questCoinDone = false;

  List<Color> playerColors = [Colors.white];
  String playerFace = '😊';

  final List<String> _foodEmojis = [
    '🍎', '🍓', '🍇', '🍊', '🍉', '🍌', '🍒', '🥕', '🍟', '🍔',
    '🍩', '🍕', '🧁', '🍰', '🥝', '🍑', '🥭', '🍍', '🥦', '🌽',
  ];

  final List<String> _botNames = [
    'Timothy', 'Hugo', 'Tab', 'Lou', 'Leopold', 'Norton', 'Rachel',
    'Quinn', 'Osborn', 'Mitchell', 'Tim', 'Sampson', 'Harley',
    'Roy', 'Lyndon', 'Hiram', 'Reg', 'Mia', 'Zara', 'Alex',
    'Kira', 'Leo', 'Nina', 'Omar', 'Pia', 'Rex', 'Sara', 'Tina',
  ];

  final List<String> _botFaces = ['😊', '😎', '😡', '😲', '😴', '😛', '😈', '😍'];

  void startGame({required List<Color> colors, required String faceEmoji}) {
    playerColors = colors;
    playerFace = faceEmoji;
    gameOver = false;
    deathReason = '';
    coinsCollected = 0;
    foodsEaten = 0;
    questFoodDone = false;
    questCoinDone = false;
    foods = [];
    bots = [];
    _spawnFoods(280);
    _spawnPlayer();
    _spawnBots(28);
    cameraX = player.head.dx;
    cameraY = player.head.dy;
  }

  void _spawnPlayer() {
    final cx = worldSize / 2;
    final cy = worldSize / 2;
    final pts = <Offset>[];
    for (int i = 0; i < 35; i++) {
      pts.add(Offset(cx - i * 8, cy));
    }
    player = Worm(
      name: 'Player',
      points: pts,
      angle: 0,
      colors: playerColors,
      faceEmoji: playerFace,
      isPlayer: true,
      targetLength: 35,
    );
  }

  void _spawnBots(int count) {
    for (int i = 0; i < count; i++) {
      final name = _botNames[i % _botNames.length];
      final x = 200 + _random.nextDouble() * (worldSize - 400);
      final y = 200 + _random.nextDouble() * (worldSize - 400);
      // Keep bots away from player spawn
      if ((x - worldSize / 2).abs() < 250 && (y - worldSize / 2).abs() < 250) {
        continue;
      }
      final angle = _random.nextDouble() * 2 * pi;
      final pts = <Offset>[];
      final len = 25 + _random.nextInt(45);
      for (int j = 0; j < len; j++) {
        pts.add(Offset(
          x - cos(angle) * j * 8,
          y - sin(angle) * j * 8,
        ));
      }
      final skin = GameSkins.skins[_random.nextInt(GameSkins.skins.length)];
      bots.add(Worm(
        name: name,
        points: pts,
        angle: angle,
        colors: skin.colors,
        faceEmoji: _botFaces[_random.nextInt(_botFaces.length)],
        isPlayer: false,
        score: _random.nextInt(8000) + 500,
        targetLength: len,
        speed: 1.8 + _random.nextDouble() * 0.7,
      ));
    }
  }

  void _spawnFoods(int count) {
    for (int i = 0; i < count; i++) {
      _spawnOneFood();
    }
    // A few coins
    for (int i = 0; i < 12; i++) {
      foods.add(FoodItem(
        x: 100 + _random.nextDouble() * (worldSize - 200),
        y: 100 + _random.nextDouble() * (worldSize - 200),
        emoji: '🪙',
        value: 50,
        isCoin: true,
        radius: 16,
      ));
    }
  }

  void _spawnOneFood() {
    final isSpecial = _random.nextDouble() < 0.08;
    foods.add(FoodItem(
      x: 80 + _random.nextDouble() * (worldSize - 160),
      y: 80 + _random.nextDouble() * (worldSize - 160),
      emoji: _foodEmojis[_random.nextInt(_foodEmojis.length)],
      value: isSpecial ? 30 : 10,
      radius: isSpecial ? 18 : 13,
    ));
  }

  void update(double joyX, double joyY, bool boosting) {
    if (gameOver) return;

    // Player steering from joystick
    if (joyX.abs() > 0.15 || joyY.abs() > 0.15) {
      final target = atan2(joyY, joyX);
      player.angle = _turnTowards(player.angle, target, 0.12);
    }
    final playerSpeed = boosting && player.boostEnergy > 0 ? 4.2 : 2.4;
    if (boosting && player.boostEnergy > 0) {
      player.boostEnergy -= 0.35;
      if (player.boostEnergy < 0) player.boostEnergy = 0;
    } else {
      player.boostEnergy += 0.08;
      if (player.boostEnergy > 100) player.boostEnergy = 100;
    }
    _moveWorm(player, playerSpeed);

    // Bots AI
    for (final bot in List<Worm>.from(bots)) {
      if (!bot.alive) continue;
      _botThink(bot);
      _moveWorm(bot, bot.speed);
    }

    _checkEating();
    _checkCollisions();
    _keepFoodCount();

    // Camera follows player
    cameraX = player.head.dx;
    cameraY = player.head.dy;

    // Quests
    if (foodsEaten >= questFoodTarget) questFoodDone = true;
    if (coinsCollected >= questCoinTarget) questCoinDone = true;
  }

  double _turnTowards(double current, double target, double maxTurn) {
    double diff = target - current;
    while (diff > pi) diff -= 2 * pi;
    while (diff < -pi) diff += 2 * pi;
    if (diff.abs() <= maxTurn) return target;
    return current + (diff > 0 ? maxTurn : -maxTurn);
  }

  void _moveWorm(Worm worm, double speed) {
    final head = worm.points.first;
    double nx = head.dx + cos(worm.angle) * speed * 3.2;
    double ny = head.dy + sin(worm.angle) * speed * 3.2;

    // Wall: steer back to centre instead of instant death
    if (nx < 40 || nx > worldSize - 40 || ny < 40 || ny > worldSize - 40) {
      final toCenter = atan2(worldSize / 2 - head.dy, worldSize / 2 - head.dx);
      worm.angle = _turnTowards(worm.angle, toCenter, 0.25);
      nx = head.dx + cos(worm.angle) * speed * 3.2;
      ny = head.dy + sin(worm.angle) * speed * 3.2;
      nx = nx.clamp(40, worldSize - 40);
      ny = ny.clamp(40, worldSize - 40);
    }
    worm.points.insert(0, Offset(nx, ny));
    while (worm.points.length > worm.targetLength) {
      worm.points.removeLast();
    }
  }

  void _botThink(Worm bot) {
    final head = bot.head;
    // Find nearest food
    FoodItem? nearest;
    double bestDist = 500;
    for (final f in foods) {
      final d = (Offset(f.x, f.y) - head).distance;
      if (d < bestDist) {
        bestDist = d;
        nearest = f;
      }
    }
    double desired = bot.angle + (_random.nextDouble() - 0.5) * 0.3;
    if (nearest != null) {
      desired = atan2(nearest.y - head.dy, nearest.x - head.dx);
    }
    // Avoid walls
    if (head.dx < 250 || head.dx > worldSize - 250 || head.dy < 250 || head.dy > worldSize - 250) {
      desired = atan2(worldSize / 2 - head.dy, worldSize / 2 - head.dx);
    }
    // Avoid other worms - simple: if close to player body, turn away
    for (final other in [player, ...bots]) {
      if (other == bot || !other.alive) continue;
      for (int i = 12; i < other.points.length; i += 4) {
        final p = other.points[i];
        final d = (p - head).distance;
        if (d < 55) {
          final away = atan2(head.dy - p.dy, head.dx - p.dx);
          desired = away;
          break;
        }
      }
    }
    bot.angle = _turnTowards(bot.angle, desired, bot.turnSpeed);
  }

  void _checkEating() {
    final all = [player, ...bots.where((b) => b.alive)];
    for (final worm in all) {
      final head = worm.points.first;
      for (int i = foods.length - 1; i >= 0; i--) {
        final f = foods[i];
        final d = (Offset(f.x, f.y) - head).distance;
        if (d < 26) {
          foods.removeAt(i);
          worm.score += f.value;
          worm.foodsEaten += 1;
          worm.targetLength += 1;
          if (worm.isPlayer) {
            foodsEaten += 1;
            if (f.isCoin) {
              coinsCollected += 1;
              worm.score += 40;
            }
          }
          break;
        }
      }
    }
  }

  void _checkCollisions() {
    // Player vs bot bodies
    if (_hitsBody(player, bots.where((b) => b.alive).toList())) {
      gameOver = true;
      deathReason = 'You crashed into another worm!';
      return;
    }
    // Bots vs player + other bots
    for (final bot in List<Worm>.from(bots)) {
      if (!bot.alive) continue;
      final others = [player, ...bots.where((b) => b != bot && b.alive)];
      if (_hitsBody(bot, others)) {
        bot.alive = false;
        _dropFoodFromWorm(bot);
      }
    }
    bots.removeWhere((b) => !b.alive);
  }

  bool _hitsBody(Worm worm, List<Worm> others) {
    final head = worm.points.first;
    for (final other in others) {
      if (!other.alive) continue;
      // Skip near-head points to avoid false hits
      for (int i = 14; i < other.points.length; i += 2) {
        final p = other.points[i];
        if ((p - head).distance < 15) return true;
      }
    }
    return false;
  }

  void _dropFoodFromWorm(Worm worm) {
    for (int i = 0; i < worm.points.length; i += 6) {
      if (foods.length > 600) break;
      final p = worm.points[i];
      foods.add(FoodItem(
        x: p.dx + _random.nextDouble() * 20 - 10,
        y: p.dy + _random.nextDouble() * 20 - 10,
        emoji: _foodEmojis[_random.nextInt(_foodEmojis.length)],
        value: 10,
      ));
    }
  }

  void _keepFoodCount() {
    while (foods.length < 240) {
      _spawnOneFood();
    }
  }

  List<Worm> leaderboard() {
    final all = [player, ...bots.where((b) => b.alive)];
    all.sort((a, b) => b.score.compareTo(a.score));
    return all.take(10).toList();
  }

  int playerRank() {
    final all = [player, ...bots.where((b) => b.alive)];
    all.sort((a, b) => b.score.compareTo(a.score));
    final idx = all.indexWhere((w) => w.isPlayer);
    return idx + 1;
  }
}
