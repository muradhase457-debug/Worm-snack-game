import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../game/models.dart';
import '../utils/storage.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});
  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int coins = 0;
  String selectedSkin = 'white';
  String selectedFace = 'happy';
  List<String> unlockedSkins = ['white', 'rainbow'];
  List<String> unlockedFaces = ['happy', 'love'];
  String? photoPath;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final c = await GameStorage.getCoins();
    final s = await GameStorage.getSkin();
    final f = await GameStorage.getFace();
    final us = await GameStorage.getUnlockedSkins();
    final uf = await GameStorage.getUnlockedFaces();
    final pp = await GameStorage.getPhotoPath();
    if (!mounted) return;
    setState(() {
      coins = c;
      selectedSkin = s;
      selectedFace = f;
      unlockedSkins = us;
      unlockedFaces = uf;
      photoPath =
          (pp != null && File(pp).existsSync()) ? pp : null;
    });
  }

  Future<void> _buyOrSelectSkin(SkinOption skin) async {
    if (unlockedSkins.contains(skin.id)) {
      await GameStorage.setSkin(skin.id);
      setState(() => selectedSkin = skin.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${skin.name} selected')));
      }
      return;
    }
    if (coins < skin.price) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Not enough coins! Play to earn more.')));
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${face.name} selected')));
      }
      return;
    }
    if (coins < face.price) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Not enough coins! Play to earn more.')));
      }
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

  /// Pick a photo from the gallery and save it as the round head face.
  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (x == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/worm_face.png');
      await File(x.path).copy(dest.path);
      await GameStorage.setPhotoPath(dest.path);
      setState(() => photoPath = dest.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo set as your face!')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not pick photo. Try again.')));
      }
    }
  }

  Future<void> _removePhoto() async {
    try {
      final pp = photoPath;
      if (pp != null && File(pp).existsSync()) {
        await File(pp).delete();
      }
    } catch (_) {}
    await GameStorage.setPhotoPath(null);
    setState(() => photoPath = null);
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
            child: Row(children: [
              const Text('🪙 '),
              Text('$coins',
                  style: const TextStyle(fontWeight: FontWeight.bold))
            ]),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Skins'),
            Tab(text: 'Faces'),
            Tab(text: 'Snake Shop'),
            Tab(text: 'My Photo'),
          ],
        ),
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
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: skin.colors[i % skin.colors.length],
                    ),
                  ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.amber, width: 2),
                    image: photoPath != null
                        ? DecorationImage(
                            image: FileImage(File(photoPath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: photoPath == null
                      ? Center(
                          child: Text(
                            face.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _skinGrid(GameSkins.skins),
                GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: GameSkins.faces.length,
                  itemBuilder: (ctx, i) {
                    final f = GameSkins.faces[i];
                    final owned = unlockedFaces.contains(f.id);
                    final selected = selectedFace == f.id;
                    return GestureDetector(
                      onTap: () => _buyOrSelectFace(f),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.green.shade800
                              : Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(14),
                          border: selected
                              ? Border.all(color: Colors.amber, width: 2)
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(f.emoji, style: const TextStyle(fontSize: 30)),
                            Text(f.name, style: const TextStyle(fontSize: 12)),
                            Text(
                              owned
                                  ? (selected ? '✓' : 'Use')
                                  : '🪙 ${f.price}',
                              style: const TextStyle(
                                  color: Colors.amber, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Snake Shop - premium snakes
                _skinGrid(GameSkins.shopSkins, shop: true),
                // My Photo
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.shade800,
                          border: Border.all(color: Colors.amber, width: 3),
                          image: photoPath != null
                              ? DecorationImage(
                                  image: FileImage(File(photoPath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: photoPath == null
                            ? const Center(
                                child: Text('😊',
                                    style: TextStyle(fontSize: 64)))
                            : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Gallery theke tomar pic naw - gol hoye snake er mathay bosbe',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _pickPhoto,
                          child: const Text(
                            '📷  Pick from Gallery',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (photoPath != null)
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side:
                                  const BorderSide(color: Colors.redAccent),
                            ),
                            onPressed: _removePhoto,
                            child: const Text('Remove photo'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skinGrid(List<SkinOption> list, {bool shop = false}) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final s = list[i];
        final owned = unlockedSkins.contains(s.id);
        final selected = selectedSkin == s.id;
        return GestureDetector(
          onTap: () => _buyOrSelectSkin(s),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? Colors.green.shade800 : Colors.grey.shade800,
              borderRadius: BorderRadius.circular(14),
              border: selected
                  ? Border.all(color: Colors.amber, width: 2)
                  : (shop ? Border.all(color: Colors.amber.shade700) : null),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (shop)
                  const Text('👑 PREMIUM',
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int k = 0; k < 4; k++)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: s.colors[k % s.colors.length],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(s.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  owned
                      ? (selected ? '✓ Selected' : 'Tap to use')
                      : '🪙 ${s.price}',
                  style: const TextStyle(color: Colors.amber),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
