import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/widgets/notification_bell.dart';
import '../../../auth/data/auth_service.dart';
import '../../../auth/data/user_model.dart';
import '../../data/driver_models.dart';
import '../../data/driver_service.dart';
import '../widgets/incoming_offer_dialog.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen>
    with WidgetsBindingObserver {
  User? _user;
  List<DriverAssignment> _assignments = [];
  bool _loading = true;
  Timer? _pollTimer;
  bool _offerDialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkForOffers(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  Future<void> _loadData() async {
    final user = await AuthService().getStoredUser();
    final result = await DriverService().getMyAssignments();

    if (mounted) {
      setState(() {
        _user = user;
        _assignments = result.assignments ?? [];
        _loading = false;
      });
    }
  }

  Future<void> _checkForOffers() async {
    if (_offerDialogOpen) return;
    if (!mounted) return;

    try {
      final result = await DriverService().getMyAssignments();
      final offers = (result.assignments ?? []).where((a) => a.isOffered).toList();

      if (offers.isEmpty || !mounted) return;

      // Sort by schedule date to pick the nearest one
      offers.sort((a, b) => a.ride.scheduledAt.compareTo(b.ride.scheduledAt));

      _offerDialogOpen = true;
      await showDialog(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
        builder: (_) => IncomingOfferDialog(
          assignment: offers.first,
          onDismissed: () {
            _offerDialogOpen = false;
            _loadData();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error polling for offers: $e');
    }
  }

  // ============================================================
  // SORTED GETTERS — nearest scheduled date first
  // ============================================================

  List<DriverAssignment> get _offers {
    final list = _assignments.where((a) => a.isOffered).toList();
    list.sort((a, b) => a.ride.scheduledAt.compareTo(b.ride.scheduledAt));
    return list;
  }

  List<DriverAssignment> get _active {
    final list = _assignments.where((a) => a.isAccepted).toList();
    list.sort((a, b) => a.ride.scheduledAt.compareTo(b.ride.scheduledAt));
    return list;
  }

  List<DriverAssignment> get _completed {
    final list =
        _assignments.where((a) => a.ride.status == 'COMPLETED').toList();
    list.sort((a, b) => a.ride.scheduledAt.compareTo(b.ride.scheduledAt));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user;
    final firstName = user?.fullName.split(' ').first ?? 'Driver';
    final initials = (user?.fullName ?? 'D')
        .split(' ')
        .take(2)
        .map((s) => s.isNotEmpty ? s[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      drawer: const AppDrawer(),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppTheme.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: false,
                elevation: 0,
                backgroundColor: const Color(0xFF0F172A),
                toolbarHeight: 64,
                expandedHeight: 64,
                automaticallyImplyLeading: false,
                titleSpacing: 16,
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF10B981),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        firstName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                actions: [
                  const NotificationBell(),
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: 'Offers',
                            value: _offers.length.toString(),
                            color: const Color(0xFFF59E0B),
                            icon: Icons.notifications_active_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatBox(
                            label: 'Active',
                            value: _active.length.toString(),
                            color: const Color(0xFF0EA5E9),
                            icon: Icons.directions_car_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatBox(
                            label: 'Completed',
                            value: _completed.length.toString(),
                            color: const Color(0xFF10B981),
                            icon: Icons.check_circle_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    if (_offers.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'New Offers',
                        badge: _offers.length,
                        badgeColor: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 12),
                      ..._offers.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _OfferCard(assignment: a),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (_active.isNotEmpty) ...[
                      const _SectionHeader(title: 'Active Rides'),
                      const SizedBox(height: 12),
                      ..._active.map((a) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ActiveAssignmentCard(assignment: a),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (_offers.isEmpty && _active.isEmpty)
                      const _EmptyState(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGETS
// ============================================================

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? badge;
  final Color? badgeColor;

  const _SectionHeader({
    required this.title,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        if (badge != null && badge! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (badgeColor ?? AppTheme.primary).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$badge',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: badgeColor ?? AppTheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  final DriverAssignment assignment;

  const _OfferCard({required this.assignment});

  String _formatDateTimeShort(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} · $hour12:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/driver/assignment/${assignment.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER: NEW OFFER badge + date/time on right =====
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'NEW OFFER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF59E0B),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Date/time pill on the RIGHT
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTimeShort(assignment.ride.scheduledAt),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Customer
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person_rounded,
                        color: Color(0xFF8B5CF6), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      assignment.ride.customer.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Route
              _RouteLine(
                icon: Icons.my_location_rounded,
                color: const Color(0xFF10B981),
                text: assignment.ride.pickupAddress,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Container(
                  width: 2,
                  height: 14,
                  color: Colors.grey.shade300,
                ),
              ),
              _RouteLine(
                icon: Icons.location_on_rounded,
                color: AppTheme.error,
                text: assignment.ride.dropoffAddress,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _Chip(
                      icon: Icons.people_alt_rounded,
                      label: '${assignment.ride.passengers} pax',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Chip(
                      icon: Icons.luggage_rounded,
                      label: '${assignment.ride.luggageCount} bags',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Chip(
                      icon: Icons.directions_car_rounded,
                      label: assignment.ride.vehicleType ?? 'Any',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Review & Respond',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveAssignmentCard extends StatelessWidget {
  final DriverAssignment assignment;

  const _ActiveAssignmentCard({required this.assignment});

  String get _dateLabel {
    final d = assignment.ride.scheduledAt;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} • $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = assignment.ride.statusLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/driver/assignment/${assignment.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0EA5E9),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _dateLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                assignment.ride.customer.fullName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _RouteLine(
                icon: Icons.my_location_rounded,
                color: const Color(0xFF10B981),
                text: assignment.ride.pickupAddress,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Container(
                  width: 2,
                  height: 14,
                  color: Colors.grey.shade300,
                ),
              ),
              _RouteLine(
                icon: Icons.location_on_rounded,
                color: AppTheme.error,
                text: assignment.ride.dropoffAddress,
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
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primary.withValues(alpha: 0.08),
            ),
            child: const Icon(
              Icons.inbox_rounded,
              size: 36,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No active assignments',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'New ride offers will appear here.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}