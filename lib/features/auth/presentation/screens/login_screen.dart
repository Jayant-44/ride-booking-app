import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/auth_service.dart';

enum LoginRole { customer, driver, admin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _uniqueIdCtrl = TextEditingController();

  LoginRole _role = LoginRole.customer;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    _uniqueIdCtrl.dispose();
    super.dispose();
  }

  bool get _needsUniqueId => _role != LoginRole.customer;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final result = await AuthService().login(
        identifier: _identifierCtrl.text.trim(),
        password: _passwordCtrl.text,
        uniqueId: _needsUniqueId ? _uniqueIdCtrl.text.trim() : null,
      );

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Login failed'), backgroundColor: AppTheme.error),
        );
        return;
      }

      // Role-based routing
      switch (result.user!.role) {
        case 'DRIVER': context.go('/driver/home'); break;
        case 'ADMIN': context.go('/admin/home'); break;
        default: context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ============================================================
  // GOOGLE SIGN IN (v7.0.0 API)
  // ============================================================
    Future<void> _handleGoogleSignIn() async {
    setState(() => _loading = true);
    try {
      final GoogleSignIn signIn = GoogleSignIn.instance;

      await signIn.initialize(
        clientId: '116575376090-tg7qfiuscnkj3toln3bk3b89cp526vme.apps.googleusercontent.com',
        serverClientId: '116575376090-t3r633nqf4liils0vo5hia1u3u69n3t2.apps.googleusercontent.com',
      ); 
      
      final GoogleSignInAccount googleUser = await signIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the Google token
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // 5. Get the Firebase ID Token to send to our backend
      final idToken = await userCredential.user?.getIdToken();
      
      if (idToken == null) throw Exception('Failed to get Firebase token');

      // 6. Send to our backend
      final result = await AuthService().googleLogin(idToken);

      if (!mounted) return;
      setState(() => _loading = false);

      if (result.success) {
        switch (result.user!.role) {
          case 'DRIVER': context.go('/driver/home'); break;
          case 'ADMIN': context.go('/admin/home'); break;
          default: context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? 'Login failed'), backgroundColor: AppTheme.error),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------- LOGO ----------
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, Color(0xFF3B5BC4)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ---------- ROLE TABS ----------
                  _RoleTabs(
                    selected: _role,
                    onChanged: (r) => setState(() => _role = r),
                  ),

                  const SizedBox(height: 24),

                  // ---------- IDENTIFIER ----------
                  TextFormField(
                    controller: _identifierCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'Email or Phone',
                      hintText: 'you@example.com or +91...',
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email or phone is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ---------- UNIQUE ID (Driver/Admin only) ----------
                  if (_needsUniqueId) ...[
                    TextFormField(
                      controller: _uniqueIdCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: '${_role == LoginRole.driver ? "Driver" : "Admin"} ID',
                        hintText: 'e.g. ${_role == LoginRole.driver ? "DRV-XXXX" : "ADM-XXXX"}',
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return '${_role == LoginRole.driver ? "Driver" : "Admin"} ID is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ---------- PASSWORD ----------
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Password is required';
                      return null;
                    },
                  ),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Forgot Password?', style: TextStyle(color: AppTheme.primary)),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ---------- SIGN IN BUTTON ----------
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),
                  
                  // ---------- GOOGLE SIGN IN ----------
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text("OR", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton(
                    onPressed: _loading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('G', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
                        const SizedBox(width: 10),
                        const Text('Continue with Google', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ---------- SIGN UP / REGISTER LINKS ----------
                  if (_role == LoginRole.customer) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (_role == LoginRole.driver) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Want to drive with us?",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register-driver'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "New admin?",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register-admin'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ROLE TABS
// ============================================================

class _RoleTabs extends StatelessWidget {
  final LoginRole selected;
  final ValueChanged<LoginRole> onChanged;

  const _RoleTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: LoginRole.values.map((role) {
          final isSelected = role == selected;
          final label = switch (role) {
            LoginRole.customer => 'Customer',
            LoginRole.driver => 'Driver',
            LoginRole.admin => 'Admin',
          };

          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? AppTheme.primary
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}