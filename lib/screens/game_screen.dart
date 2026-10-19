import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import '../game/engine.dart';
import '../game/game_painter.dart';
import '../game/joystick.dart';
import '../game/models.dart';
import '../utils/storage.dart';
import '../services/config_service.dart';

/// Worm Snake V2 game screen.
/// - Starts instantly with defaults (never stuck on loading).
/// - Applies remote GameConfig from Firestore in the background.
/// - Shows the gallery photo as a round head face when set.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final WormGameEngine _engine = WormGameEngine();
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  double _joyX = 0;
  double _joyY = 0;
  bool _boosting = false;
  bool _started = true;
  bool _showGameOver = false;
  int _finalScore = 0;
  int _finalFoods = 0;
  int _finalCoins = 0;
  String? _photoPath;
  bool _photoOk = false;
  GameConfig _config = GameConfig.defaults();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _ticker = createTicker(_onTick);
    // Start instantly with defaults - never wait for storage or network.
    try {
      _engine.startGame(colors: const [Colors.white], faceEmoji: '😊');
    } catch (_) {}
    _started = true;
    if (!_ticker.isActive) _ticker.start();
    // Load saved skin/photo + remote config in background.
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final results = await Future.wait([
        GameStorage.getSkin().timeout(const Duration(seconds: 3),
            onTimeout: () => 'white'),
        GameStorage.getFace().timeout(const Duration(seconds: 3),
            onTimeout: () => 'happy'),
        GameStorage.getPhotoPath().timeout(const Duration(seconds: 3),
            onTimeout: () => null),
      ]);
      final skinId = results[0] as String;
      final faceId = results[1] as String;
      final pp = results[2] as String?;
      // Remote config (Admin Panel can change these without an APK update).
      GameConfig cfg = GameConfig.defaults();
      try {
        cfg = await ConfigService.fetchGameConfig()
            .timeout(const Duration(seconds: 4));
      } catch (_) {}
      if (!mounted) return;
      _config = cfg;
      _engine.applyConfig(cfg);
      final skin = GameSkins.skinById(skinId);
      final face = GameSkins.faceById(faceId);
      _engine.startGame(colors: skin.colors, faceEmoji: face.emoji);
      _photoPath = (pp != null && File(pp).existsSync()) ? pp : null;
      _photoOk = _photoPath != null;
      try {
        await GameStorage.incrementGamesPlayed()
            .timeout(const Duration(seconds: 2), onTimeout: () {});
      } catch (_) {}
      if (mounted) setState(() {});
    } catch (_) {
      // Keep playing with defaults if anything fails.
    }
  }

  void _onTick(Duration elapsed) {
    if (!_started) return;
    double dt = (elapsed - _lastTick).inMilliseconds / 1000;
    _lastTick = elapsed;
    if (dt <= 0 || dt > 0.25) dt = 1 / 60;
    _engine.update(_joyX, _joyY, _boosting, dt);
    if (_engine.gameOver && !_showGameOver) {
      _onGameOver();
    }
    if (mounted) setState(() {});
  }

  Future<void> _onGameOver() async {
    _showGameOver = true;
    _ticker.stop();
    _finalScore = _engine.player.score;
    _finalFoods = _engine.foodsEaten;
    _finalCoins = _engine.coinsCollected;
    try {
      await GameStorage.setBestScore(_finalScore);
      await GameStorage.setBestLength(_engine.player.length);
      await GameStorage.addCoins(_finalCoins * 10);
      await GameStorage.addTotalFoods(_finalFoods);
    } catch (_) {}
    if (!mounted) return;
    setState(() {});
  }

  void _restart() {
    _showGameOver = false;
    _finalScore = 0;
    _finalFoods = 0;
    _finalCoins = 0;
    try {
      _engine.startGame(colors: const [Colors.white], faceEmoji: '😊');
    } catch (_) {}
    if (!_ticker.isActive) _ticker.start();
    if (mounted) setState(() {});
    _loadSaved();
  }

  @override
  void dispose() {
    _ticker.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final size = MediaQuery.of(context).size;
    final board = _engine.leaderboard();
    final rank = _engine.playerRank();
    final foodProgress =
        (_engine.foodsEaten / _engine.questFoodTarget).clamp(0.0, 1.0);
    final coinProgress =
        (_engine.coinsCollected / _engine.questCoinTarget).clamp(0.0, 1.0);

    // Head position on screen for the photo face overlay.
    final head = _engine.player.head;
    final hx = head.dx - _engine.cameraX + size.width / 2;
    final hy = head.dy - _engine.cameraY + size.height / 2;
    final showPhoto = _photoOk &&
        hx > -30 &&
        hx < size.width + 30 &&
        hy > -30 &&
        hy < size.height + 30;

    return Scaffold(
      body: Stack(
        children: [
          // Game canvas
          Positioned.fill(
            child: CustomPaint(
              painter: WormGamePainter(engine: _engine, screenSize: size),
            ),
          ),
          // Gallery photo as round head face
          if (showPhoto)
            Positioned(
              left: hx - 17,
              top: hy - 17,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: FileImage(File(_photoPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          // Leaderboard top-left
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Top players (arena: ${_engine.bots.length + 1})',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  for (int i = 0; i < board.length && i < 5; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${i + 1}. ',
                            style: TextStyle(
                                color: board[i].isPlayer
                                    ? Colors.amber
                                    : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                        SizedBox(
                          width: 70,
                          child: Text(
                              board[i].isPlayer ? 'You' : board[i].name,
                              style: TextStyle(
                                  color: board[i].isPlayer
                                      ? Colors.amber
                                      : Colors.white,
                                  fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('${board[i].score}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Text('Your rank: #$rank  •  Score: ${_engine.player.score}',
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          // Quests top-center
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('🍎 Eat ${_engine.questFoodTarget} foods  ',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                      SizedBox(
                        width: 90,
                        height: 8,
                        child: LinearProgressIndicator(
                            value: foodProgress,
                            backgroundColor: Colors.white24,
                            color: Colors.green),
                      ),
                      Text('  ${(foodProgress * 100).toInt()}%',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ]),
                    const SizedBox(height: 4),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                          '🪙 Collect ${_engine.questCoinTarget} coins  ',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11)),
                      SizedBox(
                        width: 90,
                        height: 8,
                        child: LinearProgressIndicator(
                            value: coinProgress,
                            backgroundColor: Colors.white24,
                            color: Colors.amber),
                      ),
                      Text('  ${_engine.coinsCollected}/${_engine.questCoinTarget}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11)),
                    ]),
                  ],
                ),
              ),
            ),
          ),
          // Coins top-right
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                const Text('🪙 ', style: TextStyle(fontSize: 14)),
                Text('${_engine.coinsCollected}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _ticker.stop();
                    Navigator.pop(context);
                  },
                  child:
                      const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ]),
            ),
          ),
          // Boost energy bottom-center
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡ ', style: TextStyle(fontSize: 14)),
                    SizedBox(
                      width: 120,
                      height: 8,
                      child: LinearProgressIndicator(
                          value: _engine.player.boostEnergy / 100,
                          backgroundColor: Colors.white24,
                          color: Colors.lightBlue),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Joystick bottom-left
          Positioned(
            bottom: 20,
            left: 16,
            child: JoystickView(onChanged: (dx, dy) {
              _joyX = dx;
              _joyY = dy;
            }),
          ),
          // Boost button bottom-right
          Positioned(
            bottom: 30,
            right: 20,
            child: GestureDetector(
              onLongPressStart: (_) => setState(() => _boosting = true),
              onLongPressEnd: (_) => setState(() => _boosting = false),
              onTapDown: (_) => setState(() => _boosting = true),
              onTapUp: (_) => setState(() => _boosting = false),
              onTapCancel: () => setState(() => _boosting = false),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _boosting ? Colors.orange : Colors.orange.shade800,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 8)
                  ],
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('⚡', style: TextStyle(fontSize: 22)),
                    Text('BOOST',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white))
                  ],
                ),
              ),
            ),
          ),
          // Game Over overlay
          if (_showGameOver)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('💀  GAME OVER',
                            style: TextStyle(
                                fontSize: 26, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_engine.deathReason,
                            style:
                                const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 16),
                        Text('Score: $_finalScore',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber)),
                        Text(
                            'Foods eaten: $_finalFoods  •  Coins: $_finalCoins  •  Rank: #$rank',
                            style:
                                const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white),
                              onPressed: _restart,
                              child: const Text('🔄 PLAY AGAIN'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('🏠 HOME'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
