import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  
  bool _codeSent = false;
  bool _loading = false;
  String? _error;

  Future<void> _sendCode() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    
    final res = await AuthService().forgotPassword(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) { _codeSent = true; } else { _error = res.error; }
    });
  }

  Future<void> _resetPassword() async {
    if (_codeCtrl.text.isEmpty || _passwordCtrl.text.length < 6) {
      setState(() => _error = 'Enter a valid code and a password (min 6 chars)');
      return;
    }
    setState(() { _loading = true; _error = null; });
    
    final res = await AuthService().resetPassword(
      email: _emailCtrl.text.trim(),
      code: _codeCtrl.text.trim(),
      newPassword: _passwordCtrl.text,
    );
    
    if (!mounted) return;
    setState(() => _loading = false);
    
    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully!'), backgroundColor: Colors.green));
      context.go('/login');
    } else {
      setState(() => _error = res.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reset Password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _codeSent ? 'Enter the 6-digit code sent to ${_emailCtrl.text}' : 'Enter your email address to receive a reset code.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _emailCtrl,
              enabled: !_codeSent,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            if (_codeSent) ...[
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '6-Digit Code', prefixIcon: Icon(Icons.pin_outlined), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_outline), border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
            ],

            ElevatedButton(
              onPressed: _loading ? null : (_codeSent ? _resetPassword : _sendCode),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(_codeSent ? 'Reset Password' : 'Send Reset Code', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}