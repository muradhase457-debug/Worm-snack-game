import 'dart:math';
import 'package:flutter/material.dart';
import 'models.dart';

/// Worm Snake V2 engine.
/// Tuning: 5000 arena, slow normal speed, baby-size player start,
/// 500 foods, 30 coins, rich death drops, anti-circle bot AI,
/// 4 mega bots that look like long-time real players.
class WormGameEngine {
  // V2 tuning values (can be overridden by applyConfig from Firestore).
  double worldSize = 5000;
  double playerSpeed = 1.6;
  double boostSpeed = 3.0;
  double boostDrain = 0.25;
  double boostRegen = 0.12;
  double botSpeedMin = 1.2;
  double botSpeedMax = 1.7;
  int fruitInitial = 500;
  int fruitKeepMin = 450;
  int coinInitial = 30;
  int questFoodTarget = 120;
  int questCoinTarget = 5;

  final Random _random = Random();
  late Worm player;
  List<Worm> bots = [];
  List<FoodItem> foods = [];
  double cameraX = 2500;
  double cameraY = 2500;
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

  /// Apply remote config from Firestore (Admin Panel). Falls back to V2
  /// defaults for any missing value, so a partial config never breaks the game.
  void applyConfig(GameConfig cfg) {
    playerSpeed = cfg.playerSpeed;
    boostSpeed = cfg.boostSpeed;
    botSpeedMin = cfg.botSpeedMin;
    botSpeedMax = cfg.botSpeedMax;
    fruitInitial = cfg.fruitCount;
    fruitKeepMin = cfg.fruitCount - 50 > 120 ? cfg.fruitCount - 50 : cfg.fruitCount;
    coinInitial = cfg.coinCount;
    worldSize = cfg.worldSize;
    questFoodTarget = cfg.questFoodTarget;
    questCoinTarget = cfg.questCoinTarget;
  }

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
    _spawnFoods(fruitInitial);
    _spawnPlayer();
    _spawnBots(28);
    _spawnMegaBots();
    cameraX = player.head.dx;
    cameraY = player.head.dy;
  }

  void _spawnPlayer() {
    final cx = worldSize / 2;
    final cy = worldSize / 2;
    final pts = <Offset>[];
    // Baby tiny start - grows with every food eaten.
    for (int i = 0; i < 12; i++) {
      pts.add(Offset(cx - i * 8, cy));
    }
    player = Worm(
      name: 'Player',
      points: pts,
      angle: 0,
      colors: playerColors,
      faceEmoji: playerFace,
      isPlayer: true,
      speed: playerSpeed,
      targetLength: 12,
    );
  }

  void _spawnBots(int count) {
    for (int i = 0; i < count; i++) {
      final name = _botNames[i % _botNames.length];
      final x = 200 + _random.nextDouble() * (worldSize - 400);
      final y = 200 + _random.nextDouble() * (worldSize - 400);
      // Keep bots away from player spawn
      if ((x - worldSize / 2).abs() < 300 && (y - worldSize / 2).abs() < 300) {
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
        speed: botSpeedMin + _random.nextDouble() * (botSpeedMax - botSpeedMin),
      ));
    }
  }

  /// 4 mega bots that look like real players who have played for a long time.
  void _spawnMegaBots() {
    final megaNames = ['King', 'Titan', 'Legend', 'Boss'];
    final megaSkins = [
      GameSkins.skinById('gold'),
      GameSkins.skinById('neon'),
      GameSkins.skinById('rainbow'),
      GameSkins.skinById('fire'),
    ];
    for (int i = 0; i < 4; i++) {
      final x = 400 + _random.nextDouble() * (worldSize - 800);
      final y = 400 + _random.nextDouble() * (worldSize - 800);
      if ((x - worldSize / 2).abs() < 450 && (y - worldSize / 2).abs() < 450) {
        continue;
      }
      final angle = _random.nextDouble() * 2 * pi;
      final len = 120 + _random.nextInt(61);
      final pts = <Offset>[];
      for (int j = 0; j < len; j++) {
        pts.add(Offset(
          x - cos(angle) * j * 8,
          y - sin(angle) * j * 8,
        ));
      }
      bots.add(Worm(
        name: megaNames[i],
        points: pts,
        angle: angle,
        colors: megaSkins[i].colors,
        faceEmoji: '👑',
        isPlayer: false,
        score: 20000 + _random.nextInt(20001),
        targetLength: len,
        speed: 1.3,
        turnSpeed: 0.05,
      ));
    }
  }

  void _spawnFoods(int count) {
    for (int i = 0; i < count; i++) {
      _spawnOneFood();
    }
    for (int i = 0; i < coinInitial; i++) {
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

  void update(double joyX, double joyY, bool boosting, [double dt = 1 / 60]) {
    if (gameOver) return;

    // Player steering from joystick
    if (joyX.abs() > 0.15 || joyY.abs() > 0.15) {
      final target = atan2(joyY, joyX);
      player.angle = _turnTowards(player.angle, target, 0.12);
    }
    final spd = boosting && player.boostEnergy > 0 ? boostSpeed : playerSpeed;
    if (boosting && player.boostEnergy > 0) {
      player.boostEnergy -= boostDrain;
      if (player.boostEnergy < 0) player.boostEnergy = 0;
    } else {
      player.boostEnergy += boostRegen;
      if (player.boostEnergy > 100) player.boostEnergy = 100;
    }
    _moveWorm(player, spd);

    // Bots AI
    for (final bot in List<Worm>.from(bots)) {
      if (!bot.alive) continue;
      bot.noEatTime += dt;
      _botThink(bot, dt);
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

  void _botThink(Worm bot, double dt) {
    final head = bot.head;
    // Find nearest food
    FoodItem? nearest;
    double bestDist = 600;
    for (final f in foods) {
      final d = (Offset(f.x, f.y) - head).distance;
      if (d < bestDist) {
        bestDist = d;
        nearest = f;
      }
    }
    double desired = bot.angle + (_random.nextDouble() - 0.5) * 0.15;
    if (nearest != null) {
      desired = atan2(nearest.y - head.dy, nearest.x - head.dx);
    }
    // Avoid walls
    if (head.dx < 300 || head.dx > worldSize - 300 || head.dy < 300 || head.dy > worldSize - 300) {
      desired = atan2(worldSize / 2 - head.dy, worldSize / 2 - head.dx);
    }
    // Avoid other worms
    for (final other in [player, ...bots]) {
      if (other == bot || !other.alive) continue;
      for (int i = 12; i < other.points.length; i += 4) {
        final p = other.points[i];
        final d = (p - head).distance;
        if (d < 60) {
          desired = atan2(head.dy - p.dy, head.dx - p.dx);
          break;
        }
      }
    }
    // Anti-circle: track whether the bot keeps turning the same way
    double diff = desired - bot.angle;
    while (diff > pi) diff -= 2 * pi;
    while (diff < -pi) diff += 2 * pi;
    final dir = diff == 0 ? 0 : (diff > 0 ? 1 : -1);
    if (dir != 0 && dir == bot.turnDir) {
      bot.sameTurnTime += dt;
    } else {
      bot.sameTurnTime = 0;
      bot.turnDir = dir.toDouble();
    }
    if (bot.noEatTime > 8 || bot.sameTurnTime > 2.5) {
      // Break out of the loop: pick a fresh random direction.
      desired = _random.nextDouble() * 2 * pi;
      bot.noEatTime = 0;
      bot.sameTurnTime = 0;
      bot.turnDir = 0;
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
          worm.noEatTime = 0;
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
    // Rich drops: every 3rd body point becomes food.
    for (int i = 0; i < worm.points.length; i += 3) {
      if (foods.length > 900) break;
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
    while (foods.length < fruitKeepMin) {
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
