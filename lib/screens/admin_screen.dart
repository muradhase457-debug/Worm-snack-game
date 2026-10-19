import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../game/models.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/config_service.dart';

/// Admin Panel - visible ONLY when AuthService.isAdmin is true.
/// Tabs: Users (coins give/take, ban/unban), Config (game values),
/// Skins (add new), Announcement.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  // Config form
  final _speedC = TextEditingController();
  final _boostC = TextEditingController();
  final _fruitC = TextEditingController();
  final _coinC = TextEditingController();
  final _worldC = TextEditingController();
  final _questFoodC = TextEditingController();
  final _questCoinC = TextEditingController();
  bool _configLoaded = false;

  // Skin form
  final _skinNameC = TextEditingController();
  final _skinPriceC = TextEditingController();
  Color _skinColor = Colors.green;

  // Announcement
  final _announceC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final cfg = await ConfigService.fetchGameConfig();
    if (!mounted) return;
    setState(() {
      _speedC.text = '${cfg.playerSpeed}';
      _boostC.text = '${cfg.boostSpeed}';
      _fruitC.text = '${cfg.fruitCount}';
      _coinC.text = '${cfg.coinCount}';
      _worldC.text = '${cfg.worldSize}';
      _questFoodC.text = '${cfg.questFoodTarget}';
      _questCoinC.text = '${cfg.questCoinTarget}';
      _announceC.text = cfg.announcement;
      _configLoaded = true;
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _speedC.dispose();
    _boostC.dispose();
    _fruitC.dispose();
    _coinC.dispose();
    _worldC.dispose();
    _questFoodC.dispose();
    _questCoinC.dispose();
    _skinNameC.dispose();
    _skinPriceC.dispose();
    _announceC.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    try {
      await AdminService.updateConfig({
        'playerSpeed': double.tryParse(_speedC.text) ?? 1.6,
        'boostSpeed': double.tryParse(_boostC.text) ?? 3.0,
        'fruitCount': int.tryParse(_fruitC.text) ?? 500,
        'coinCount': int.tryParse(_coinC.text) ?? 30,
        'worldSize': double.tryParse(_worldC.text) ?? 5000,
        'questFoodTarget': int.tryParse(_questFoodC.text) ?? 120,
        'questCoinTarget': int.tryParse(_questCoinC.text) ?? 5,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Config saved! Game updates now.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save failed. Try again.')));
      }
    }
  }

  Future<void> _addSkin() async {
    final name = _skinNameC.text.trim();
    final price = int.tryParse(_skinPriceC.text) ?? 0;
    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a name and a price.')));
      return;
    }
    try {
      await AdminService.addSkin({
        'name': name,
        'price': price,
        'colors': [_skinColor.value],
      });
      _skinNameC.clear();
      _skinPriceC.clear();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Skin added!')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add failed. Try again.')));
      }
    }
  }

  Future<void> _saveAnnouncement() async {
    try {
      await AdminService.setAnnouncement(_announceC.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement updated!')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Save failed. Try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Double guard: only the admin email ever renders this screen.
    if (!AuthService.isAdmin) {
      return const Scaffold(
        body: Center(child: Text('Not allowed.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('👑 Admin Panel'),
        backgroundColor: Colors.brown.shade800,
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Config'),
            Tab(text: 'Skins'),
            Tab(text: 'Notice'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _usersTab(),
          _configTab(),
          _skinsTab(),
          _noticeTab(),
        ],
      ),
    );
  }

  Widget _usersTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AdminService.usersStream(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No users yet.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d = docs[i].data();
            final uid = docs[i].id;
            final name = (d['name'] as String?) ?? 'Player';
            final email = (d['email'] as String?) ?? '';
            final coins = (d['coins'] as num?)?.toInt() ?? 0;
            final banned = (d['banned'] as bool?) ?? false;
            final isMe = email == AuthService.adminEmail;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: banned ? Colors.red.shade50 : null,
              child: ListTile(
                title: Text('$name  ${banned ? '(BANNED)' : ''}',
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$email\n🪙 $coins coins'),
                isThreeLine: true,
                trailing: isMe
                    ? const Text('YOU',
                        style: TextStyle(
                            color: Colors.brown,
                            fontWeight: FontWeight.bold))
                    : Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Give 100 coins',
                            icon: const Icon(Icons.add_circle,
                                color: Colors.green),
                            onPressed: () =>
                                AdminService.giveCoins(uid, 100),
                          ),
                          IconButton(
                            tooltip: 'Take 100 coins',
                            icon: const Icon(Icons.remove_circle,
                                color: Colors.orange),
                            onPressed: () =>
                                AdminService.takeCoins(uid, 100),
                          ),
                          IconButton(
                            tooltip: banned ? 'Unban' : 'Ban',
                            icon: Icon(
                              banned ? Icons.check_circle : Icons.block,
                              color: banned ? Colors.blue : Colors.red,
                            ),
                            onPressed: () =>
                                AdminService.setBanned(uid, !banned),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _configTab() {
    if (!_configLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Game values - save korlei sobar game e update hobe, APK lagbe na.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        _numField('Player speed', _speedC),
        _numField('Boost speed', _boostC),
        _numField('Fruit count', _fruitC),
        _numField('Coin count', _coinC),
        _numField('Arena size', _worldC),
        _numField('Quest: eat foods target', _questFoodC),
        _numField('Quest: collect coins target', _questCoinC),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: _saveConfig,
            child: const Text('💾  SAVE CONFIG',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _numField(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _skinsTab() {
    final preset = [Colors.green, Colors.red, Colors.blue, Colors.purple, Colors.orange];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Notun skin add koro - Wardrobe e sobai dekhte pabe.',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 12),
        TextField(
          controller: _skinNameC,
          decoration: const InputDecoration(
            labelText: 'Skin name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _skinPriceC,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price (coins)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        const Text('Color:'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final col in preset)
              GestureDetector(
                onTap: () => setState(() => _skinColor = col),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: col,
                    border: _skinColor == col
                        ? Border.all(color: Colors.amber, width: 3)
                        : null,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            onPressed: _addSkin,
            child: const Text('➕  ADD SKIN',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _noticeTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Home screen e sobai ei notice dekhbe.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _announceC,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Announcement',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: _saveAnnouncement,
            child: const Text('📢  UPDATE NOTICE',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
