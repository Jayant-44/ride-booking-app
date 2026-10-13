import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _faqs = [
    _Faq(
      q: 'How do I book a ride?',
      a: 'From the home screen, tap "Book a Ride", fill in your pickup and drop-off locations, choose a date and time, and submit. Our team will review and send you an invoice.',
    ),
    _Faq(
      q: 'How do I pay for my ride?',
      a: 'Once the admin sends your invoice, a "Payment Due" card appears on your home screen. Tap it and use the Pay Now button.',
    ),
    _Faq(
      q: 'Can I cancel a ride?',
      a: 'Yes. You can cancel any ride before a driver is assigned. Once a driver has accepted, contact support.',
    ),
    _Faq(
      q: 'How do I contact my driver?',
      a: 'Once your driver has accepted, their name, vehicle, and phone number appear on your ride card. Tap the Call button to reach them.',
    ),
    _Faq(
      q: 'How do I apply to become a driver?',
      a: 'On the login screen, select the Driver tab and tap Apply. Fill in your details and vehicle info. Our admin will review and send you a Driver ID.',
    ),
  ];

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
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
        title: const Text('Support'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B5BC4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'We\'re here to help',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reach out anytime — we usually reply within an hour',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const _SectionLabel('CONTACT US'),
            const SizedBox(height: 10),
            _Card(
              child: Column(
                children: [
                  _ContactTile(
                    icon: Icons.email_rounded,
                    color: const Color(0xFF3B5BC4),
                    label: 'Email',
                    value: 'support@ridebooking.app',
                    onTap: () => _launch(
                        context, 'mailto:support@ridebooking.app'),
                  ),
                  const Divider(height: 1),
                  _ContactTile(
                    icon: Icons.phone_rounded,
                    color: const Color(0xFF10B981),
                    label: 'Phone',
                    value: '+91 90000 00000',
                    onTap: () => _launch(context, 'tel:+919000000000'),
                  ),
                  const Divider(height: 1),
                  _ContactTile(
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFFF59E0B),
                    label: 'WhatsApp',
                    value: '+91 90000 00000',
                    onTap: () =>
                        _launch(context, 'https://wa.me/919000000000'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const _SectionLabel('FREQUENTLY ASKED'),
            const SizedBox(height: 10),
            ..._faqs.map((faq) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FaqTile(faq: faq),
                )),

            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded,
                      color: AppTheme.primary, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Version 1.0.0 · Ride Booking',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
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

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppTheme.primary,
          collapsedIconColor: const Color(0xFF64748B),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            faq.q,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          children: [
            Text(
              faq.a,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}