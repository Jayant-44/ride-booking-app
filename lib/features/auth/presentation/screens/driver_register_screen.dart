import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/auth_service.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Personal
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // License
  final _licenseNoCtrl = TextEditingController();
  DateTime? _licenseExpiry;

  // Vehicle
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _colorCtrl = TextEditingController();
  int _capacity = 4;
  int _luggageCapacity = 2;

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _licenseNoCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _plateCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _licenseExpiry ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 15)),
    );
    if (picked != null) setState(() => _licenseExpiry = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseExpiry == null) {
      _snack('Please select a license expiry date', isError: true);
      return;
    }

    setState(() => _loading = true);

    final result = await AuthService().registerDriver(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      fullName: _fullNameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      licenseNo: _licenseNoCtrl.text.trim(),
      licenseExpiry: _licenseExpiry!,
      vehicleMake: _makeCtrl.text.trim(),
      vehicleModel: _modelCtrl.text.trim(),
      plateNo: _plateCtrl.text.trim().toUpperCase(),
      vehicleColor: _colorCtrl.text.trim(),
      capacity: _capacity,
      luggageCapacity: _luggageCapacity,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      await _showSuccessDialog(result.message ?? 'Awaiting approval');
    } else {
      _snack(result.error ?? 'Registration failed', isError: true);
    }
  }

  Future<void> _showSuccessDialog(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.check_circle_rounded,
            color: Color(0xFF10B981), size: 56),
        title: const Text('Application Submitted'),
        content: Text(
          '$message\n\n'
          'Our admin team will review your details. '
          'You will receive a Driver ID via email once approved.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Become a Driver'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SectionLabel('PERSONAL DETAILS'),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      _textField(
                        controller: _fullNameCtrl,
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Full name is required'
                            : null,
                      ),
                      const Divider(height: 1),
                      _textField(
                        controller: _emailCtrl,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email required';
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(v.trim())) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      const Divider(height: 1),
                      _textField(
                        controller: _phoneCtrl,
                        label: 'Phone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+\-\s()]')),
                        ],
                        validator: (v) => (v == null || v.trim().length < 8)
                            ? 'Phone required'
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const _SectionLabel('SECURITY'),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscure1,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(_obscure1
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded),
                            onPressed: () =>
                                setState(() => _obscure1 = !_obscure1),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password required';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const Divider(height: 1),
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscure2,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(_obscure2
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded),
                            onPressed: () =>
                                setState(() => _obscure2 = !_obscure2),
                          ),
                        ),
                        validator: (v) {
                          if (v != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const _SectionLabel('LICENSE'),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      _textField(
                        controller: _licenseNoCtrl,
                        label: 'License Number',
                        icon: Icons.card_membership_outlined,
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? 'License number required'
                            : null,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.event_rounded,
                              color: AppTheme.primary, size: 18),
                        ),
                        title: const Text(
                          'License Expiry',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        subtitle: Text(
                          _licenseExpiry == null
                              ? 'Select date'
                              : '${_licenseExpiry!.day}/${_licenseExpiry!.month}/${_licenseExpiry!.year}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _licenseExpiry == null
                                ? Colors.grey.shade500
                                : Colors.black87,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _pickLicenseExpiry,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const _SectionLabel('VEHICLE'),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      _textField(
                        controller: _makeCtrl,
                        label: 'Make (e.g. Maruti)',
                        icon: Icons.directions_car_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const Divider(height: 1),
                      _textField(
                        controller: _modelCtrl,
                        label: 'Model (e.g. Dzire)',
                        icon: Icons.directions_car_filled_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                      const Divider(height: 1),
                      _textField(
                        controller: _plateCtrl,
                        label: 'Plate Number',
                        icon: Icons.pin_outlined,
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? 'Required'
                            : null,
                      ),
                      const Divider(height: 1),
                      _textField(
                        controller: _colorCtrl,
                        label: 'Color',
                        icon: Icons.palette_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Required'
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CounterCard(
                        label: 'Seats',
                        value: _capacity,
                        min: 1,
                        max: 20,
                        onChanged: (v) => setState(() => _capacity = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CounterCard(
                        label: 'Bags',
                        value: _luggageCapacity,
                        min: 0,
                        max: 30,
                        onChanged: (v) =>
                            setState(() => _luggageCapacity = v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.4),
                        )
                      : const Text(
                          'Submit Application',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: InputBorder.none,
      ),
      validator: validator,
    );
  }
}

// ============================================================
// SHARED WIDGETS
// ============================================================

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

class _CounterCard extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CounterCard({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
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
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundBtn(
                icon: Icons.remove_rounded,
                onTap: value > min ? () => onChanged(value - 1) : null,
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _RoundBtn(
                icon: Icons.add_rounded,
                onTap: value < max ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? AppTheme.primary.withValues(alpha: 0.1)
          : Colors.grey.shade200,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? AppTheme.primary : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}