import 'package:flutter/material.dart';
import '../utils/storage.dart';
import '../game/models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int coins = 340;
  int bestScore = 0;
  int bestLength = 0;
  String skinId = 'white';
  String faceId = 'happy';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await GameStorage.getCoins();
    final bs = await GameStorage.getBestScore();
    final bl = await GameStorage.getBestLength();
    final s = await GameStorage.getSkin();
    final f = await GameStorage.getFace();
    if (!mounted) return;
    setState(() {
      coins = c;
      bestScore = bs;
      bestLength = bl;
      skinId = s;
      faceId = f;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skin = GameSkins.skinById(skinId);
    final face = GameSkins.faceById(faceId);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1A1A1A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('🐛 WORM SNAKE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [const Text('🪙 ', style: TextStyle(fontSize: 16)), Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // Worm preview
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (int i = 0; i < 6; i++)
                          Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: skin.colors[i % skin.colors.length]),
                          ),
                        Container(
                          width: 42, height: 42,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                          child: Center(child: Text(face.emoji, style: const TextStyle(fontSize: 26))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('${skin.name}  •  ${face.name}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    Text('Best Score: $bestScore  •  Best Length: $bestLength', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity, height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/game');
                          _load();
                        },
                        child: const Text('▶  PLAY', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/wardrobe');
                          _load();
                        },
                        child: const Text('👗  WARDROBE  •  Skins & Faces', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('Eat food • Grow big • Don\'t crash into other worms', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 6),
                    const Text('Joystick = move  •  BOOST button = fast', style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
