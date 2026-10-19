import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/storage.dart';
import '../services/auth_service.dart';

/// Settings. The Admin Panel button exists ONLY for the admin Gmail.
/// It is not rendered at all for normal users - not even hidden.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sound = true;

  @override
  void initState() {
    super.initState();
    GameStorage.getSound().then((v) {
      if (mounted) setState(() => _sound = v);
    });
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final isAdmin = AuthService.isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2E7D32),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: (user?.photoURL?.isNotEmpty ?? false)
                    ? NetworkImage(user!.photoURL!)
                    : null,
                child: (user?.photoURL?.isNotEmpty ?? false)
                    ? null
                    : const Icon(Icons.person),
              ),
              title: Text(user?.displayName ?? 'Player'),
              subtitle: Text(user?.email ?? 'Guest mode'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: user == null || user.isAnonymous
                  ? null
                  : FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
              builder: (ctx, snap) {
                final coins =
                    (snap.data?.data()?['coins'] as num?)?.toInt();
                return ListTile(
                  leading: const Text('🪙', style: TextStyle(fontSize: 24)),
                  title: const Text('My coins'),
                  trailing: Text(
                    '${coins ?? '...'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: SwitchListTile(
              title: const Text('Sound'),
              secondary: const Icon(Icons.volume_up),
              value: _sound,
              onChanged: (v) async {
                await GameStorage.setSound(v);
                setState(() => _sound = v);
              },
            ),
          ),
          const SizedBox(height: 8),
          // Admin Panel button - admin ONLY. Not rendered for others.
          if (isAdmin)
            Card(
              color: Colors.amber.shade100,
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings,
                    color: Colors.brown),
                title: const Text(
                  'Admin Panel',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Users, coins, config, skins'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.pushNamed(context, '/admin'),
              ),
            ),
          if (isAdmin) const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.red)),
              onTap: _logout,
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Worm Snake V2 • Made with Flutter',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
