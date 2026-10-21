import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/data/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await AuthService().getStoredUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  // ============================================================
  // EDIT PROFILE DIALOG
  // ============================================================
  void _editProfile() {
    final nameCtrl = TextEditingController(text: _user?.fullName);
    final phoneCtrl = TextEditingController(text: _user?.phone);
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().length < 8) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      final res = await AuthService().updateProfile(
                        fullName: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (res.success) {
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Failed'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(0, 50),
                    ),
                    child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CHANGE PASSWORD DIALOG
  // ============================================================
  void _changePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Change Password', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: currentCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      final res = await AuthService().changePassword(
                        currentPassword: currentCtrl.text,
                        newPassword: newCtrl.text,
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (res.success) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed successfully')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Failed'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      minimumSize: const Size(0, 50),
                    ),
                    child: saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Update Password'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white, // Matching the screenshot
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/support'), // Links to your support page
            icon: const Icon(Icons.help_outline, color: Colors.black, size: 20),
            label: const Text('Help', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        children: [
          _ProfileTile(
            icon: Icons.person_outline_rounded,
            title: 'Name',
            subtitle: _user?.fullName ?? 'Not set',
            onTap: _editProfile,
          ),
          _ProfileTile(
            icon: Icons.phone_outlined,
            title: 'Phone Number',
            subtitle: _user?.phone ?? 'Not set',
            onTap: _editProfile,
          ),
          _ProfileTile(
            icon: Icons.mail_outline_rounded,
            title: 'Email',
            subtitle: _user?.email ?? 'Not set',
            onTap: null, // Locked
          ),
          _ProfileTile(
            icon: Icons.face_outlined,
            title: 'Gender',
            subtitle: 'Male', // Placeholder
            onTap: null,
          ),
          _ProfileTile(
            icon: Icons.calendar_today_outlined,
            title: 'Date of Birth',
            subtitle: 'Required',
            isRequired: true,
            onTap: null, // Wire to a date picker later
          ),
          _ProfileTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Member Since',
            subtitle: 'August 2022', // You can format _user.createdAt here
            onTap: null,
          ),
          _ProfileTile(
            icon: Icons.emergency_outlined,
            title: 'Emergency contact',
            subtitle: 'Add',
            isActionText: true,
            isRequired: true,
            onTap: null,
          ),
          
          // Added Change Password here since you had it before
          _ProfileTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Tap to update your password',
            onTap: _changePassword,
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isRequired;
  final bool isActionText;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isRequired = false,
    this.isActionText = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade700, size: 24),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isRequired ? Colors.orange.shade800 : (isActionText ? AppTheme.primary : Colors.grey.shade600),
                      fontWeight: isRequired || isActionText ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null && !isActionText)
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            if (isActionText)
              TextButton(
                onPressed: onTap, 
                child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold))
              ),
          ],
        ),
      ),
    );
  }
}