import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Added for Date Formatting

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
  // EDIT NAME DIALOG
  // ============================================================
  void _editName() {
    final nameCtrl = TextEditingController(text: _user?.fullName);
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
                  const Text('Edit Name', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      final res = await AuthService().updateProfile(
                        fullName: nameCtrl.text.trim(),
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (res.success) {
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated successfully')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Failed'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Name', style: TextStyle(fontWeight: FontWeight.bold)),
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
  // EDIT EMERGENCY CONTACT DIALOG
  // ============================================================
  void _editEmergencyContact() {
    final contactCtrl = TextEditingController(text: _user?.emergencyContact);
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
                  const Text('Emergency Contact', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: contactCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: saving ? null : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      final res = await AuthService().updateProfile(
                        emergencyContact: contactCtrl.text.trim(),
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        if (res.success) {
                          _load();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emergency contact updated')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res.error ?? 'Failed'), backgroundColor: Colors.red));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Contact', style: TextStyle(fontWeight: FontWeight.bold)),
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
  // DATE OF BIRTH PICKER
  // ============================================================
  Future<void> _editDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _user?.dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final res = await AuthService().updateProfile(dateOfBirth: picked);
      if (res.success && mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date of birth updated')));
      }
    }
  }

  // ============================================================
  // GENDER PICKER
  // ============================================================
  void _editGender() {
    final genders = ['Male', 'Female', 'Other', 'Prefer not to say'];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Select Gender', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ...genders.map((g) => ListTile(
              title: Text(g),
              trailing: _user?.gender == g ? const Icon(Icons.check, color: AppTheme.primary) : null,
              onTap: () async {
                Navigator.pop(ctx);
                final res = await AuthService().updateProfile(gender: g);
                if (res.success && mounted) {
                  _load();
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CHANGE PASSWORD DIALOG (3 FIELDS)
  // ============================================================
  void _changePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
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
                    decoration: const InputDecoration(
                      labelText: 'Current Password', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password', 
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                    validator: (v) => v != newCtrl.text ? 'Passwords do not match' : null,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.white,
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
            onPressed: () => context.push('/support'),
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
            onTap: _editName,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ),
          _ProfileTile(
            icon: Icons.phone_outlined,
            title: 'Phone Number',
            subtitle: _user?.phone ?? 'Not set',
            onTap: null, // Locked
            trailing: const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
          ),
          _ProfileTile(
            icon: Icons.mail_outline_rounded,
            title: 'Email',
            subtitle: _user?.email ?? 'Not set',
            onTap: null, // Locked
            trailing: const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey),
          ),
          _ProfileTile(
            icon: Icons.face_outlined,
            title: 'Gender',
            subtitle: _user?.gender ?? 'Add',
            isRequired: _user?.gender == null,
            onTap: _editGender,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ),
          _ProfileTile(
            icon: Icons.calendar_today_outlined,
            title: 'Date of Birth',
            subtitle: _user?.dateOfBirth != null 
                ? DateFormat('dd MMM yyyy').format(_user!.dateOfBirth!) 
                : 'Add',
            isRequired: _user?.dateOfBirth == null,
            onTap: _editDob,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ),
          _ProfileTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Member Since',
            subtitle: 'August 2022',
            onTap: null,
          ),
          _ProfileTile(
            icon: Icons.emergency_outlined,
            title: 'Emergency contact',
            subtitle: _user?.emergencyContact ?? 'Add',
            isRequired: _user?.emergencyContact == null,
            onTap: _editEmergencyContact,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ),
          _ProfileTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Tap to update your password',
            onTap: _changePassword,
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isRequired = false,
    this.onTap,
    this.trailing,
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
                      color: isRequired ? Colors.orange.shade800 : Colors.grey.shade600,
                      fontWeight: isRequired ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing, // <--- This is the Dart 3.9 syntax replacing the 'if' check
          ],
        ),
      ),
    );
  }
}