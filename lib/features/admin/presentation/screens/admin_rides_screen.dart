import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/admin_service.dart';

class AdminRidesScreen extends StatefulWidget {
  const AdminRidesScreen({super.key});

  @override
  State<AdminRidesScreen> createState() => _AdminRidesScreenState();
}

class _AdminRidesScreenState extends State<AdminRidesScreen> {
  List<dynamic> _rides = [];
  bool _loading = true;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await AdminService().getRides();
    if (!mounted) return;
    setState(() {
      _rides = result.data ?? [];
      _loading = false;
    });
  }

  Future<void> _approve(String rideId) async {
    setState(() => _busy.add(rideId));
    final result = await AdminService().approveRide(rideId);
    if (!mounted) return;
    setState(() => _busy.remove(rideId));
    if (result.success) {
      _snack('Ride approved');
      _load();
    } else {
      _snack(result.error ?? 'Failed', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin/home'),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('All Rides'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.primary,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(20),
                itemCount: _rides.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final ride = _rides[index] as Map<String, dynamic>;
                  final status = ride['status'] as String;
                  return _RideAdminCard(
                    ride: ride,
                    busy: _busy.contains(ride['id']),
                    onApprove: status == 'REQUESTED'
                        ? () => _approve(ride['id'] as String)
                        : null,
                  );
                },
              ),
            ),
    );
  }
}

class _RideAdminCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final bool busy;
  final VoidCallback? onApprove;

  const _RideAdminCard({
    required this.ride,
    required this.busy,
    this.onApprove,
  });

  Color _statusColor(String s) {
    if (s == 'REJECTED' || s == 'CANCELLED') return AppTheme.error;
    if (s == 'COMPLETED' || s == 'REVIEWED') return const Color(0xFF10B981);
    if (s == 'CONFIRMED' || s == 'DRIVER_ASSIGNED') {
      return const Color(0xFF0EA5E9);
    }
    return const Color(0xFFF59E0B);
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'REQUESTED':
        return 'New';
      case 'ADMIN_REVIEW':
        return 'Reviewed';
      case 'QUOTED':
        return 'Invoice Sent';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'DRIVER_OFFERED':
        return 'Driver Offered';
      case 'DRIVER_ASSIGNED':
        return 'Driver Assigned';
      case 'EN_ROUTE':
        return 'On the Way';
      case 'ARRIVED':
        return 'Arrived';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'REJECTED':
        return 'Rejected';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = ride['customer']?['user'] as Map<String, dynamic>?;
    final status = ride['status'] as String;
    final color = _statusColor(status);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  customer?['fullName'] as String? ?? 'Customer',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RouteRow(
            icon: Icons.my_location_rounded,
            color: const Color(0xFF10B981),
            text: ride['pickupAddress'] as String? ?? '',
          ),
          const SizedBox(height: 4),
          _RouteRow(
            icon: Icons.location_on_rounded,
            color: AppTheme.error,
            text: ride['dropoffAddress'] as String? ?? '',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Chip(label: '${ride['passengers']} pax'),
              const SizedBox(width: 8),
              _Chip(label: '${ride['luggageCount']} bags'),
              const Spacer(),
              if (onApprove != null)
                ElevatedButton(
                  onPressed: busy ? null : onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size.zero,
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Approve',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _RouteRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF475569),
        ),
      ),
    );
  }
}