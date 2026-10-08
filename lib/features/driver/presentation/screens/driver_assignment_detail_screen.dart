import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/driver_models.dart';
import '../../data/driver_service.dart';

class DriverAssignmentDetailScreen extends StatefulWidget {
  final String assignmentId;
  const DriverAssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  State<DriverAssignmentDetailScreen> createState() =>
      _DriverAssignmentDetailScreenState();
}

class _DriverAssignmentDetailScreenState
    extends State<DriverAssignmentDetailScreen> {
  DriverAssignment? _assignment;
  bool _loading = true;
  bool _acting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result =
        await DriverService().getAssignmentDetail(widget.assignmentId);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _assignment = result.assignment;
      } else {
        _error = result.error;
      }
    });
  }

  Future<void> _accept() async {
    setState(() => _acting = true);
    final result = await DriverService().acceptAssignment(widget.assignmentId);
    if (!mounted) return;
    setState(() => _acting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer accepted'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      _load();
    } else {
      _snack(result.error ?? 'Failed to accept', isError: true);
    }
  }

  Future<void> _reject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject this offer?'),
        content: const Text(
          'The admin will assign another driver. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _acting = true);
    final result = await DriverService().rejectAssignment(widget.assignmentId);
    if (!mounted) return;
    setState(() => _acting = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer rejected')),
      );
      context.go('/driver/home');
    } else {
      _snack(result.error ?? 'Failed to reject', isError: true);
    }
  }

  Future<void> _progress(String nextStatus, String label) async {
    setState(() => _acting = true);
    final result = await DriverService()
        .progressRide(_assignment!.ride.id, nextStatus);
    if (!mounted) return;
    setState(() => _acting = false);

    if (result.success) {
      _snack('Marked as $label');
      _load();
    } else {
      _snack(result.error ?? 'Failed to update', isError: true);
    }
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : null,
      ),
    );
  }

  Future<void> _callCustomer() async {
    final phone = _assignment?.ride.customer.phone;
    if (phone == null || phone.isEmpty) return;

    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception();
    } catch (_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Call ${_assignment!.ride.customer.fullName}'),
          content: SelectableText(
            phone,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
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
          onPressed: () => context.go('/driver/home'),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Ride Details'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final a = _assignment!;
    final ride = a.ride;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ---------- STATUS HEADER ----------
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: a.isOffered
                    ? [const Color(0xFFF59E0B), const Color(0xFFEA580C)]
                    : [const Color(0xFF0EA5E9), const Color(0xFF06B6D4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: (a.isOffered
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF0EA5E9))
                      .withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.isOffered ? 'NEW OFFER' : ride.statusLabel.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹--', // fare not in assignment payload; can show later
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ride.passengers} passenger${ride.passengers > 1 ? 's' : ''} · ${ride.luggageCount} bag${ride.luggageCount != 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---------- CUSTOMER ----------
          _SectionLabel('CUSTOMER'),
          const SizedBox(height: 8),
          _Card(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded,
                      color: Color(0xFF8B5CF6), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.customer.fullName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ride.customer.hasContact
                            ? ride.customer.phone!
                            : 'Contact revealed after acceptance',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: ride.customer.hasContact
                              ? const Color(0xFF64748B)
                              : const Color(0xFFF59E0B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ride.customer.hasContact)
                  Material(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _callCustomer,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.phone_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---------- ROUTE ----------
          _SectionLabel('ROUTE'),
          const SizedBox(height: 8),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RouteLine(
                  icon: Icons.my_location_rounded,
                  color: const Color(0xFF10B981),
                  label: 'Pickup',
                  text: ride.pickupAddress,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                  child: Container(
                    width: 2,
                    height: 22,
                    color: Colors.grey.shade300,
                  ),
                ),
                _RouteLine(
                  icon: Icons.location_on_rounded,
                  color: AppTheme.error,
                  label: 'Drop-off',
                  text: ride.dropoffAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---------- SCHEDULE ----------
          _SectionLabel('SCHEDULE'),
          const SizedBox(height: 8),
          _Card(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.schedule_rounded,
                      color: AppTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDateTime(ride.scheduledAt),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ---------- NOTES ----------
          if (ride.notes != null && ride.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionLabel('NOTES'),
            const SizedBox(height: 8),
            _Card(
              child: Text(
                ride.notes!,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ---------- ACTIONS ----------
          if (a.isOffered) ...[
            ElevatedButton(
              onPressed: _acting ? null : _accept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _acting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text(
                      'Accept Offer',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _acting ? null : _reject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: BorderSide(color: AppTheme.error, width: 1.5),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Reject',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ] else if (a.isAccepted) ...[
            _buildProgressButton(ride.status),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProgressButton(String currentStatus) {
    String nextStatus;
    String label;
    Color color;

    switch (currentStatus) {
      case 'DRIVER_ASSIGNED':
        nextStatus = 'EN_ROUTE';
        label = 'Start Driving';
        color = const Color(0xFF0EA5E9);
        break;
      case 'EN_ROUTE':
        nextStatus = 'ARRIVED';
        label = 'I Have Arrived';
        color = const Color(0xFF8B5CF6);
        break;
      case 'ARRIVED':
        nextStatus = 'IN_PROGRESS';
        label = 'Start Trip';
        color = const Color(0xFF06B6D4);
        break;
      case 'IN_PROGRESS':
        nextStatus = 'COMPLETED';
        label = 'Complete Trip';
        color = const Color(0xFF10B981);
        break;
      default:
        return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: _acting ? null : () => _progress(nextStatus, label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: _acting
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.4),
            )
          : Text(
              label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
    );
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = dt.day.toString().padLeft(2, '0');
    final mon = months[dt.month - 1];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$d $mon ${dt.year} · $h:$m';
  }
}

// ---------- SHARED WIDGETS ----------

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
      padding: const EdgeInsets.all(16),
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

class _RouteLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String text;

  const _RouteLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
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
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}