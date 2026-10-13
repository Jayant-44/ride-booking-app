import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/data/user_model.dart';

const _timezones = [
  'Asia/Kolkata',
  'Asia/Dubai',
  'Asia/Singapore',
  'Europe/London',
  'Europe/Berlin',
  'America/New_York',
  'America/Los_Angeles',
  'Australia/Sydney',
  'UTC',
];

const _currencies = ['INR', 'USD', 'EUR', 'GBP', 'AED', 'SGD', 'AUD'];

const _locales = {
  'en': 'English',
  'hi': 'हिन्दी (Hindi)',
  'es': 'Español (Spanish)',
  'fr': 'Français (French)',
  'ar': 'العربية (Arabic)',
};

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _user;
  bool _loading = true;
  bool _saving = false;

  String? _timezone;
  String? _currency;
  String? _locale;

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
      _timezone = user?.timezone ?? 'UTC';
      _currency = user?.currency ?? 'USD';
      _locale = user?.locale ?? 'en';
      _loading = false;
    });
  }

  bool get _hasChanges {
    if (_user == null) return false;
    return _timezone != _user!.timezone ||
        _currency != _user!.currency ||
        _locale != _user!.locale;
  }

  Future<void> _save() async {
    if (!_hasChanges) return;
    setState(() => _saving = true);

    final result = await AuthService().updateSettings(
      timezone: _timezone,
      currency: _currency,
      locale: _locale,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result.success) {
      setState(() => _user = result.user);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionLabel('REGION & LANGUAGE'),
                  const SizedBox(height: 10),
                  _Card(
                    child: Column(
                      children: [
                        _DropdownTile(
                          icon: Icons.language_rounded,
                          label: 'Language',
                          value: _locale ?? 'en',
                          items: _locales.entries
                              .map((e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _locale = v),
                        ),
                        const Divider(height: 1),
                        _DropdownTile(
                          icon: Icons.attach_money_rounded,
                          label: 'Currency',
                          value: _currency ?? 'USD',
                          items: _currencies
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _currency = v),
                        ),
                        const Divider(height: 1),
                        _DropdownTile(
                          icon: Icons.schedule_rounded,
                          label: 'Time Zone',
                          value: _timezone ?? 'UTC',
                          items: _timezones
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _timezone = v),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'These settings affect how dates, times, and prices appear in the app.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: (!_hasChanges || _saving) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.4),
                          )
                        : Text(
                            _hasChanges ? 'Save Changes' : 'No Changes',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: Color(0xFF64748B),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    items: items,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}