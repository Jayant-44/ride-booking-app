import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../ride/data/ride_model.dart';
import '../../../ride/data/ride_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Ride> _rides = [];
  bool _loading = true;
  String _filter = 'ALL';

  static const _filters = ['ALL', 'ACTIVE', 'COMPLETED', 'CANCELLED'];

  static const _activeStatuses = {
    'REQUESTED',
    'ADMIN_REVIEW',
    'QUOTED',
    'AWAITING_PAYMENT',
    'CONFIRMED',
    'ASSIGNMENT_PENDING',
    'DRIVER_OFFERED',
    'DRIVER_ASSIGNED',
    'EN_ROUTE',
    'ARRIVED',
    'IN_PROGRESS',
  };

  static const _completedStatuses = {'COMPLETED', 'REVIEWED'};
  static const _cancelledStatuses = {'CANCELLED', 'REJECTED'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await RideService().getMyRides();
    if (!mounted) return;
    setState(() {
      _rides = result.rides ?? [];
      _loading = false;
    });
  }

  List<Ride> get _filtered {
    switch (_filter) {
      case 'ACTIVE':
        return _rides
            .where((r) => _activeStatuses.contains(r.status))
            .toList();
      case 'COMPLETED':
        return _rides
            .where((r) => _completedStatuses.contains(r.status))
            .toList();
      case 'CANCELLED':
        return _rides
            .where((r) => _cancelledStatuses.contains(r.status))
            .toList();
      case 'ALL':
      default:
        return _rides;
    }
  }

  String _filterLabel(String f) {
    switch (f) {
      case 'ACTIVE':
        return 'Active';
      case 'COMPLETED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      case 'ALL':
      default:
        return 'All';
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
        title: const Text('Ride History'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    children: _filters.map((f) {
                      final selected = _filter == f;
                      final count = f == 'ALL'
                          ? _rides.length
                          : (f == 'ACTIVE'
                                  ? _rides
                                      .where((r) =>
                                          _activeStatuses.contains(r.status))
                                      .length
                                  : f == 'COMPLETED'
                                      ? _rides
                                          .where((r) => _completedStatuses
                                              .contains(r.status))
                                          .length
                                      : _rides
                                          .where((r) => _cancelledStatuses
                                              .contains(r.status))
                                          .length);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primary
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primary
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _filterLabel(f),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_rounded,
                                  size: 56, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                _filter == 'ALL'
                                    ? 'No rides yet'
                                    : 'No ${_filterLabel(_filter).toLowerCase()} rides',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _filter == 'ALL'
                                    ? 'Your booked rides will appear here'
                                    : 'Try a different filter',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppTheme.primary,
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                            itemCount: _filtered.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _HistoryCard(ride: _filtered[index]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Ride ride;
  const _HistoryCard({required this.ride});

  Color get _color {
    if (ride.status == 'CANCELLED' || ride.status == 'REJECTED') {
      return AppTheme.error;
    }
    if (ride.status == 'COMPLETED' || ride.status == 'REVIEWED') {
      return const Color(0xFF10B981);
    }
    if (ride.status == 'DRIVER_ASSIGNED' ||
        ride.status == 'EN_ROUTE' ||
        ride.status == 'ARRIVED') {
      return const Color(0xFF0EA5E9);
    }
    if (ride.status == 'IN_PROGRESS') {
      return const Color(0xFF06B6D4);
    }
    return const Color(0xFFF59E0B);
  }

  String get _date {
    final d = ride.scheduledAt;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
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
                  _date,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ride.statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _RouteLine(
            icon: Icons.my_location_rounded,
            color: const Color(0xFF10B981),
            text: ride.pickupAddress,
          ),
          const SizedBox(height: 4),
          _RouteLine(
            icon: Icons.location_on_rounded,
            color: AppTheme.error,
            text: ride.dropoffAddress,
          ),
          if (ride.assignedDriver != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_rounded,
                      size: 13, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Driver: ${ride.assignedDriver!.fullName}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _RouteLine({
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}