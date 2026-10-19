import 'package:flutter/material.dart';

class FoodItem {
  double x;
  double y;
  String emoji;
  int value;
  bool isCoin;
  double radius;

  FoodItem({
    required this.x,
    required this.y,
    required this.emoji,
    required this.value,
    this.isCoin = false,
    this.radius = 14,
  });
}

class Worm {
  String name;
  List<Offset> points;
  double angle;
  double speed;
  List<Color> colors;
  String faceEmoji;
  bool isPlayer;
  int score;
  int foodsEaten;
  bool alive;
  double turnSpeed;
  int targetLength;
  double boostEnergy;

  // Anti-circle AI tracking (V2)
  double noEatTime = 0;
  double turnDir = 0;
  double sameTurnTime = 0;

  Worm({
    required this.name,
    required this.points,
    required this.angle,
    required this.colors,
    required this.faceEmoji,
    required this.isPlayer,
    this.speed = 1.6,
    this.score = 0,
    this.foodsEaten = 0,
    this.alive = true,
    this.turnSpeed = 0.08,
    this.targetLength = 12,
    this.boostEnergy = 100,
  });

  Offset get head => points.first;

  int get length => points.length;

  Color colorAt(int index) {
    if (colors.isEmpty) return Colors.white;
    if (colors.length == 1) return colors.first;
    return colors[index % colors.length];
  }
}

class SkinOption {
  final String id;
  final String name;
  final List<Color> colors;
  final int price;

  const SkinOption({
    required this.id,
    required this.name,
    required this.colors,
    required this.price,
  });
}

class FaceOption {
  final String id;
  final String name;
  final String emoji;
  final int price;

  const FaceOption({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
  });
}

/// Remote game tuning values. Admin Panel writes these to
/// Firestore config/game and the game applies them without an APK update.
class GameConfig {
  final double playerSpeed;
  final double boostSpeed;
  final double botSpeedMin;
  final double botSpeedMax;
  final int fruitCount;
  final int coinCount;
  final double worldSize;
  final int questFoodTarget;
  final int questCoinTarget;
  final String announcement;

  const GameConfig({
    required this.playerSpeed,
    required this.boostSpeed,
    required this.botSpeedMin,
    required this.botSpeedMax,
    required this.fruitCount,
    required this.coinCount,
    required this.worldSize,
    required this.questFoodTarget,
    required this.questCoinTarget,
    required this.announcement,
  });

  factory GameConfig.defaults() => const GameConfig(
        playerSpeed: 1.6,
        boostSpeed: 3.0,
        botSpeedMin: 1.2,
        botSpeedMax: 1.7,
        fruitCount: 500,
        coinCount: 30,
        worldSize: 5000,
        questFoodTarget: 120,
        questCoinTarget: 5,
        announcement: '',
      );

  factory GameConfig.fromMap(Map<String, dynamic> m) => GameConfig(
        playerSpeed: (m['playerSpeed'] as num?)?.toDouble() ?? 1.6,
        boostSpeed: (m['boostSpeed'] as num?)?.toDouble() ?? 3.0,
        botSpeedMin: (m['botSpeedMin'] as num?)?.toDouble() ?? 1.2,
        botSpeedMax: (m['botSpeedMax'] as num?)?.toDouble() ?? 1.7,
        fruitCount: (m['fruitCount'] as num?)?.toInt() ?? 500,
        coinCount: (m['coinCount'] as num?)?.toInt() ?? 30,
        worldSize: (m['worldSize'] as num?)?.toDouble() ?? 5000,
        questFoodTarget: (m['questFoodTarget'] as num?)?.toInt() ?? 120,
        questCoinTarget: (m['questCoinTarget'] as num?)?.toInt() ?? 5,
        announcement: (m['announcement'] as String?) ?? '',
      );

  Map<String, dynamic> toMap() => {
        'playerSpeed': playerSpeed,
        'boostSpeed': boostSpeed,
        'botSpeedMin': botSpeedMin,
        'botSpeedMax': botSpeedMax,
        'fruitCount': fruitCount,
        'coinCount': coinCount,
        'worldSize': worldSize,
        'questFoodTarget': questFoodTarget,
        'questCoinTarget': questCoinTarget,
        'announcement': announcement,
      };
}

class GameSkins {
  static const List<SkinOption> skins = [
    SkinOption(id: 'white', name: 'Snow White', colors: [Colors.white], price: 0),
    SkinOption(id: 'rainbow', name: 'Rainbow', colors: [Colors.red, Colors.orange, Colors.yellow, Colors.green, Colors.blue, Colors.purple], price: 0),
    SkinOption(id: 'gold', name: 'Golden', colors: [Color(0xFFFFD700), Color(0xFFFFA500)], price: 300),
    SkinOption(id: 'mint', name: 'Mint Candy', colors: [Color(0xFF7ED3B2), Color(0xFFF5E6C8), Color(0xFF9B7ED9)], price: 500),
    SkinOption(id: 'fire', name: 'Fire', colors: [Colors.red, Colors.orange, Colors.yellow], price: 700),
    SkinOption(id: 'ocean', name: 'Ocean', colors: [Color(0xFF0077B6), Color(0xFF00B4D8), Color(0xFF90E0EF)], price: 700),
    SkinOption(id: 'pink', name: 'Pink Candy', colors: [Color(0xFFFF8FAB), Color(0xFFFFC8DD), Colors.white], price: 900),
    SkinOption(id: 'neon', name: 'Neon', colors: [Color(0xFF00FF88), Color(0xFF00CCFF), Color(0xFFFF00AA)], price: 1300),
  ];

  /// Premium Snake Shop snakes (V2) - buy with coins.
  static const List<SkinOption> shopSkins = [
    SkinOption(id: 'emerald', name: 'Emerald', colors: [Color(0xFF00C853), Color(0xFF64DD17)], price: 1500),
    SkinOption(id: 'ruby', name: 'Ruby', colors: [Color(0xFFD50000), Color(0xFFFF5252)], price: 2500),
    SkinOption(id: 'sapphire', name: 'Sapphire', colors: [Color(0xFF2962FF), Color(0xFF448AFF)], price: 3500),
    SkinOption(id: 'diamond', name: 'Diamond', colors: [Color(0xFF00E5FF), Colors.white, Color(0xFFB3E5FC)], price: 5000),
  ];

  static const List<FaceOption> faces = [
    FaceOption(id: 'happy', name: 'Happy', emoji: '😊', price: 0),
    FaceOption(id: 'love', name: 'Love', emoji: '😍', price: 0),
    FaceOption(id: 'cool', name: 'Cool', emoji: '😎', price: 200),
    FaceOption(id: 'angry', name: 'Angry', emoji: '😡', price: 200),
    FaceOption(id: 'surprised', name: 'Wow', emoji: '😲', price: 300),
    FaceOption(id: 'sleepy', name: 'Sleepy', emoji: '😴', price: 300),
    FaceOption(id: 'tongue', name: 'Tongue', emoji: '😛', price: 400),
    FaceOption(id: 'devil', name: 'Devil', emoji: '😈', price: 500),
  ];

  static SkinOption skinById(String id) {
    for (final s in skins) {
      if (s.id == id) return s;
    }
    for (final s in shopSkins) {
      if (s.id == id) return s;
    }
    return skins.first;
  }

  static FaceOption faceById(String id) {
    return faces.firstWhere((f) => f.id == id, orElse: () => faces.first);
  }
}
