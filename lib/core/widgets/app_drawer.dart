import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_service.dart';
import '../../features/auth/data/user_model.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getStoredUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AuthService().logout();
      if (mounted) context.go('/login');
    }
  }

  void _go(String path) {
    Navigator.pop(context);
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final initials = (user?.fullName ?? 'U')
        .split(' ')
        .take(2)
        .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
        .join();

    final isAdmin = user?.role == 'ADMIN';
    final isDriver = user?.role == 'DRIVER';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // ---------- HEADER ----------
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B5BC4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isAdmin || isDriver) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${user?.role} · ${user?.uniqueId ?? ""}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------- MENU ----------
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  if (isAdmin) ...[
                    _DrawerItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Dashboard',
                      onTap: () => _go('/admin/home'),
                    ),
                    _DrawerItem(
                      icon: Icons.local_taxi_rounded,
                      label: 'Manage Rides',
                      onTap: () => _go('/admin/rides'),
                    ),
                    _DrawerItem(
                      icon: Icons.people_alt_rounded,
                      label: 'Pending Users',
                      onTap: () => _go('/admin/users'),
                    ),
                  ] else if (isDriver) ...[
                    _DrawerItem(
                      icon: Icons.dashboard_rounded,
                      label: 'Driver Home',
                      onTap: () => _go('/driver/home'),
                    ),
                  ] else ...[
                    _DrawerItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      onTap: () => _go('/home'),
                    ),
                  ],

                  const Divider(height: 24, indent: 20, endIndent: 20),

                  // Shared menu
                  _DrawerItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    onTap: () {
                      if (isAdmin) {
                        _go('/admin/profile');
                      } else if (isDriver) {
                        _go('/driver/profile');
                      } else {
                        _go('/profile'); // Customer profile
                      }
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.history_rounded,
                    label: 'History',
                    onTap: () => _go('/history'),
                  ),
                  _DrawerItem(
                    icon: Icons.support_agent_rounded,
                    label: 'Support',
                    onTap: () => _go('/support'),
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: () => _go('/settings'),
                  ),
                ],
              ),
            ),

            // ---------- LOGOUT ----------
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _logout,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded,
                            color: AppTheme.error, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Log Out',
                          style: TextStyle(
                            color: AppTheme.error,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF334155), size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}