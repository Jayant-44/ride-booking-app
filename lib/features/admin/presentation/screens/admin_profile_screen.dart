import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/auth_service.dart';
import '../../../auth/data/user_model.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService().getStoredUser();
    if (mounted) setState(() { _user = user; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black), onPressed: () => context.pop()),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(backgroundColor: Color(0xFF0F172A), child: Icon(Icons.admin_panel_settings, color: Colors.white)),
            title: Text(_user?.fullName ?? 'Admin', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text(_user?.email ?? ''),
            trailing: _user?.isSuperAdmin == true 
                ? const Chip(label: Text('SUPER ADMIN', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.orange)
                : const Chip(label: Text('ADMIN', style: TextStyle(fontSize: 10))),
          ),
          const Divider(),
          _Tile(icon: Icons.phone, title: 'Phone', subtitle: _user?.phone ?? ''),
          _Tile(icon: Icons.badge, title: 'Admin ID', subtitle: _user?.uniqueId ?? 'N/A'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              // THE FIX: Capture the router BEFORE the async gap
              final router = GoRouter.of(context);
              await AuthService().logout();
              if (mounted) router.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Tile({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade700),
      title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }
}