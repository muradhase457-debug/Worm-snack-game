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

  Worm({
    required this.name,
    required this.points,
    required this.angle,
    required this.colors,
    required this.faceEmoji,
    required this.isPlayer,
    this.speed = 2.2,
    this.score = 0,
    this.foodsEaten = 0,
    this.alive = true,
    this.turnSpeed = 0.08,
    this.targetLength = 18,
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
    return skins.firstWhere((s) => s.id == id, orElse: () => skins.first);
  }

  static FaceOption faceById(String id) {
    return faces.firstWhere((f) => f.id == id, orElse: () => faces.first);
  }
}
