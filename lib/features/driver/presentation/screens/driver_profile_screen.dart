import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/api_client.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/data/user_model.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  User? _user;
  Map<String, dynamic>? _driverData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService().getStoredUser();
    try {
      final res = await ApiClient().dio.get('/driver/profile');
      if (mounted) {
        setState(() {
          _user = user;
          _driverData = res.data['data'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final vehicle = (_driverData?['vehicles'] as List?)?.isNotEmpty == true 
        ? _driverData!['vehicles'][0] 
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.black), onPressed: () => context.pop()),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Driver Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF3B5BC4)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Text(
                    (_user?.fullName ?? 'D')[0].toUpperCase(),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_user?.fullName ?? 'Driver', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(_user?.phone ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(10)),
                        child: Text(_user?.uniqueId ?? 'N/A', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider()),

          _ProfileItem(icon: Icons.mail_outline, title: 'Email', subtitle: _user?.email ?? '', locked: true),
          
          if (vehicle != null) ...[
            const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider()),
            _ProfileItem(
              icon: Icons.directions_car,
              title: 'Vehicle',
              subtitle: '${vehicle['make']} ${vehicle['model']} · ${vehicle['plateNo']}',
            ),
            _ProfileItem(
              icon: Icons.palette_outlined,
              title: 'Vehicle Color',
              subtitle: vehicle['color'],
            ),
            _ProfileItem(
              icon: Icons.people_outline,
              title: 'Capacity',
              subtitle: '${vehicle['capacity']} Seats · ${vehicle['luggageCapacity']} Bags',
            ),
          ],

          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider()),

          _ProfileItem(
            icon: Icons.badge_outlined,
            title: 'License Number',
            subtitle: _driverData?['licenseNo'] ?? 'Not set',
          ),
          _ProfileItem(
            icon: Icons.calendar_today_outlined,
            title: 'License Expiry',
            subtitle: _driverData?['licenseExpiry'] != null
                ? DateFormat('dd MMM yyyy').format(DateTime.parse(_driverData!['licenseExpiry']))
                : 'Not set',
          ),
          
          const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider()),

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

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool locked;

  const _ProfileItem({required this.icon, required this.title, required this.subtitle, this.locked = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          if (locked) const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}