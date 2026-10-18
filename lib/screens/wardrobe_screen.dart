import 'package:flutter/material.dart';
import '../game/models.dart';
import '../utils/storage.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});
  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  int coins = 0;
  String selectedSkin = 'white';
  String selectedFace = 'happy';
  List<String> unlockedSkins = ['white', 'rainbow'];
  List<String> unlockedFaces = ['happy', 'love'];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final c = await GameStorage.getCoins();
    final s = await GameStorage.getSkin();
    final f = await GameStorage.getFace();
    final us = await GameStorage.getUnlockedSkins();
    final uf = await GameStorage.getUnlockedFaces();
    if (!mounted) return;
    setState(() {
      coins = c;
      selectedSkin = s;
      selectedFace = f;
      unlockedSkins = us;
      unlockedFaces = uf;
    });
  }

  Future<void> _buyOrSelectSkin(SkinOption skin) async {
    if (unlockedSkins.contains(skin.id)) {
      await GameStorage.setSkin(skin.id);
      setState(() => selectedSkin = skin.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${skin.name} selected')));
      return;
    }
    if (coins < skin.price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins! Play to earn more.')));
      return;
    }
    await GameStorage.setCoins(coins - skin.price);
    final updated = [...unlockedSkins, skin.id];
    await GameStorage.setUnlockedSkins(updated);
    await GameStorage.setSkin(skin.id);
    setState(() {
      coins -= skin.price;
      unlockedSkins = updated;
      selectedSkin = skin.id;
    });
  }

  Future<void> _buyOrSelectFace(FaceOption face) async {
    if (unlockedFaces.contains(face.id)) {
      await GameStorage.setFace(face.id);
      setState(() => selectedFace = face.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${face.name} selected')));
      return;
    }
    if (coins < face.price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not enough coins! Play to earn more.')));
      return;
    }
    await GameStorage.setCoins(coins - face.price);
    final updated = [...unlockedFaces, face.id];
    await GameStorage.setUnlockedFaces(updated);
    await GameStorage.setFace(face.id);
    setState(() {
      coins -= face.price;
      unlockedFaces = updated;
      selectedFace = face.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skin = GameSkins.skinById(selectedSkin);
    final face = GameSkins.faceById(selectedFace);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe'),
        backgroundColor: Colors.brown.shade800,
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [const Text('🪙 '), Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold))]),
          ),
        ],
        bottom: TabBar(controller: _tab, tabs: const [Tab(text: 'Skins'), Tab(text: 'Faces')]),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF2A2A2A),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < 5; i++)
                  Container(width: 32, height: 32, decoration: BoxDecoration(shape: BoxShape.circle, color: skin.colors[i % skin.colors.length])),
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: Center(child: Text(face.emoji, style: const TextStyle(fontSize: 24))),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: GameSkins.skins.length,
                  itemBuilder: (ctx, i) {
                    final s = GameSkins.skins[i];
                    final owned = unlockedSkins.contains(s.id);
                    final selected = selectedSkin == s.id;
                    return GestureDetector(
                      onTap: () => _buyOrSelectSkin(s),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? Colors.green.shade800 : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(14),
                          border: selected ? Border.all(color: Colors.amber, width: 2) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (int k = 0; k < 4; k++) Container(width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, color: s.colors[k % s.colors.length]))]),
                            const SizedBox(height: 6),
                            Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(owned ? (selected ? '✓ Selected' : 'Tap to use') : '🪙 ${s.price}', style: const TextStyle(color: Colors.amber)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemCount: GameSkins.faces.length,
                  itemBuilder: (ctx, i) {
                    final f = GameSkins.faces[i];
                    final owned = unlockedFaces.contains(f.id);
                    final selected = selectedFace == f.id;
                    return GestureDetector(
                      onTap: () => _buyOrSelectFace(f),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected ? Colors.green.shade800 : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(14),
                          border: selected ? Border.all(color: Colors.amber, width: 2) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(f.emoji, style: const TextStyle(fontSize: 30)),
                            Text(f.name, style: const TextStyle(fontSize: 12)),
                            Text(owned ? (selected ? '✓' : 'Use') : '🪙 ${f.price}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
