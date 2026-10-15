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

  Future<void> _reject(String rideId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject ride?'),
        content: const Text('This ride request will be rejected.'),
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

    setState(() => _busy.add(rideId));
    final result = await AdminService().rejectRide(rideId);
    if (!mounted) return;
    setState(() => _busy.remove(rideId));
    if (result.success) {
      _snack('Ride rejected');
      _load();
    } else {
      _snack(result.error ?? 'Failed', isError: true);
    }
  }

  Future<void> _broadcast(Map<String, dynamic> ride) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.campaign_rounded,
            color: Color(0xFF0EA5E9), size: 48),
        title: const Text('Broadcast to Drivers?'),
        content: const Text(
          'This ride will be sent to all available drivers. The first one to accept gets the ride.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final rideId = ride['id'] as String;
    setState(() => _busy.add(rideId));
    final result = await AdminService().broadcastRide(rideId);
    if (!mounted) return;
    setState(() => _busy.remove(rideId));

    if (result.success) {
      final count = result.data ?? 0;
      _snack('Offered to $count driver${count == 1 ? '' : 's'}');
      _load();
    } else {
      _snack(result.error ?? 'Failed', isError: true);
    }
  }

  Future<void> _sendInvoice(Map<String, dynamic> ride) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InvoiceSheet(ride: ride),
    );
    if (result == true) _load();
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
              child: _rides.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                            height:
                                MediaQuery.of(context).size.height * 0.3),
                        Icon(Icons.inbox_rounded,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'No rides yet',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
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
                        final isBusy = _busy.contains(ride['id']);

                        return _RideAdminCard(
                          ride: ride,
                          busy: isBusy,
                          onApprove: status == 'REQUESTED'
                              ? () => _approve(ride['id'] as String)
                              : null,
                          onReject: status == 'REQUESTED'
                              ? () => _reject(ride['id'] as String)
                              : null,
                          onSendInvoice: status == 'ADMIN_REVIEW'
                              ? () => _sendInvoice(ride)
                              : null,
                          onBroadcast: status == 'CONFIRMED'
                              ? () => _broadcast(ride)
                              : null,
                        );
                      },
                    ),
            ),
    );
  }
}

// ============================================================
// RIDE CARD
// ============================================================

class _RideAdminCard extends StatelessWidget {
  final Map<String, dynamic> ride;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onSendInvoice;
  final VoidCallback? onBroadcast;

  const _RideAdminCard({
    required this.ride,
    required this.busy,
    this.onApprove,
    this.onReject,
    this.onSendInvoice,
    this.onBroadcast,
  });

  Color _statusColor(String s) {
    if (s == 'REJECTED' || s == 'CANCELLED') return AppTheme.error;
    if (s == 'COMPLETED' || s == 'REVIEWED') return const Color(0xFF10B981);
    if (s == 'CONFIRMED' || s == 'DRIVER_ASSIGNED') {
      return const Color(0xFF0EA5E9);
    }
    if (s == 'QUOTED' || s == 'AWAITING_PAYMENT') {
      return const Color(0xFF8B5CF6);
    }
    if (s == 'DRIVER_OFFERED') return const Color(0xFF8B5CF6);
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

  String _formatDateTime(DateTime dt) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} · $hour12:$m $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final customer = ride['customer']?['user'] as Map<String, dynamic>?;
    final status = ride['status'] as String;
    final color = _statusColor(status);
    final scheduledAt = ride['scheduledAt'] != null
        ? DateTime.parse(ride['scheduledAt'] as String).toLocal()
        : null;

    final hasActions = onApprove != null ||
        onReject != null ||
        onSendInvoice != null ||
        onBroadcast != null;

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
          if (scheduledAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  _formatDateTime(scheduledAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
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
            ],
          ),
          if (hasActions) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error, width: 1.4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                if (onReject != null && onApprove != null)
                  const SizedBox(width: 10),
                if (onApprove != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: busy ? null : onApprove,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                if (onSendInvoice != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : onSendInvoice,
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text(
                        'Send Invoice',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                if (onBroadcast != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: busy ? null : onBroadcast,
                      icon: const Icon(Icons.campaign_rounded, size: 16),
                      label: const Text(
                        'Assign driver',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// INVOICE SHEET  (unchanged)
// ============================================================

class _InvoiceSheet extends StatefulWidget {
  final Map<String, dynamic> ride;
  const _InvoiceSheet({required this.ride});

  @override
  State<_InvoiceSheet> createState() => _InvoiceSheetState();
}

class _InvoiceSheetState extends State<_InvoiceSheet> {
  final _subtotalCtrl = TextEditingController(text: '500');
  final _taxCtrl = TextEditingController(text: '90');
  String _currency = 'INR';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _subtotalCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  int get _subtotalCents =>
      ((double.tryParse(_subtotalCtrl.text) ?? 0) * 100).round();
  int get _taxCents =>
      ((double.tryParse(_taxCtrl.text) ?? 0) * 100).round();
  int get _totalCents => _subtotalCents + _taxCents;

  String get _currencySymbol {
    switch (_currency) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return '$_currency ';
    }
  }

  Future<void> _submit() async {
    if (_totalCents <= 0) {
      setState(() => _error = 'Total must be greater than zero');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AdminService().createInvoice(
      widget.ride['id'] as String,
      subtotalCents: _subtotalCents,
      taxCents: _taxCents,
      currencyCode: _currency,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error = result.error ?? 'Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.ride['customer']?['user'] as Map<String, dynamic>?;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Send Invoice',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${customer?['fullName'] ?? 'Customer'} · ${widget.ride['pickupAddress']}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            const _Label('Currency'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _currency,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'INR', child: Text('INR — ₹')),
                DropdownMenuItem(value: 'USD', child: Text('USD — \$')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR — €')),
              ],
              onChanged: (v) => setState(() => _currency = v ?? 'INR'),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Subtotal'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _subtotalCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Tax'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _taxCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$_currencySymbol${(_totalCents / 100).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: AppTheme.error, fontSize: 12.5),
                ),
              ),
            ],

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send Invoice',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: Color(0xFF64748B),
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