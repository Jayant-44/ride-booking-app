import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/driver_models.dart';
import '../../data/driver_service.dart';

class IncomingOfferDialog extends StatefulWidget {
  final DriverAssignment assignment;
  final VoidCallback onDismissed;

  const IncomingOfferDialog({
    super.key,
    required this.assignment,
    required this.onDismissed,
  });

  @override
  State<IncomingOfferDialog> createState() => _IncomingOfferDialogState();
}

class _IncomingOfferDialogState extends State<IncomingOfferDialog> {
  bool _busy = false;

  String _formatDateTime(DateTime dt) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} · $hour12:$m $ampm';
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    final result =
        await DriverService().acceptAssignment(widget.assignment.id);
    if (!mounted) return;

    if (result.success) {
      Navigator.of(context).pop(true);
      widget.onDismissed();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Ride accepted!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      setState(() => _busy = false);
      final msg = result.error ?? 'Failed';
      if (msg.toLowerCase().contains('first') ||
          msg.toLowerCase().contains('taken')) {
        Navigator.of(context).pop(false);
        widget.onDismissed();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Too late — another driver got it'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _ignore() async {
    setState(() => _busy = true);
    await DriverService().rejectAssignment(widget.assignment.id);
    if (!mounted) return;
    Navigator.of(context).pop(false);
    widget.onDismissed();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.assignment;
    final ride = a.ride;

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER WITH DATE/TIME ON THE RIGHT ---
              Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'NEW RIDE OFFER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  if (_busy)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _formatDateTime(ride.scheduledAt),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.customer.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _RouteLine(
                      icon: Icons.my_location_rounded,
                      text: ride.pickupAddress,
                    ),
                    const SizedBox(height: 6),
                    _RouteLine(
                      icon: Icons.location_on_rounded,
                      text: ride.dropoffAddress,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _Chip(
                            icon: Icons.people_alt_rounded,
                            label: '${ride.passengers} pax'),
                        const SizedBox(width: 8),
                        _Chip(
                            icon: Icons.luggage_rounded,
                            label: '${ride.luggageCount} bags'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // --- BUTTONS (FIXED WRAPPING) ---
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: _busy ? null : _ignore,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const FittedBox(
                        child: Text(
                          'IGNORE',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _accept,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFEA580C),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const FittedBox(
                        child: Text(
                          'ACCEPT RIDE',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RouteLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}