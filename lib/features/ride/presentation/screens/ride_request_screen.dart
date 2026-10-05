import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/ride_service.dart';

class RideRequestScreen extends StatefulWidget {
  const RideRequestScreen({super.key});

  @override
  State<RideRequestScreen> createState() => _RideRequestScreenState();
}

class _RideRequestScreenState extends State<RideRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupCtrl = TextEditingController();
  final _dropoffCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  int _passengers = 1;
  int _luggage = 0;
  String _vehicleType = 'Sedan';
  bool _loading = false;

  final List<String> _vehicleTypes = const [
    'Sedan',
    'SUV',
    'Hatchback',
    'Luxury',
    'Van',
  ];

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _dropoffCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _scheduledTime = picked);
  }

  String get _dateLabel {
    if (_scheduledDate == null) return 'Select date';
    return '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}';
  }

  String get _timeLabel {
    if (_scheduledTime == null) return 'Select time';
    final h = _scheduledTime!.hour.toString().padLeft(2, '0');
    final m = _scheduledTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scheduledDate == null || _scheduledTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both date and time'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final scheduledAt = DateTime(
      _scheduledDate!.year,
      _scheduledDate!.month,
      _scheduledDate!.day,
      _scheduledTime!.hour,
      _scheduledTime!.minute,
    );

    if (scheduledAt.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scheduled time must be in the future'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final result = await RideService().createRide(
      pickupAddress: _pickupCtrl.text.trim(),
      dropoffAddress: _dropoffCtrl.text.trim(),
      scheduledAt: scheduledAt,
      passengers: _passengers,
      luggageCount: _luggage,
      vehicleType: _vehicleType,
      notes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ride request submitted'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Request failed'),
          backgroundColor: AppTheme.error,
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
    onPressed: () => context.go('/home'),
  ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Book a Ride'),
      
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
                _SectionLabel('Trip Details'),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      _AddressField(
                        controller: _pickupCtrl,
                        icon: Icons.my_location_rounded,
                        iconColor: const Color(0xFF10B981),
                        label: 'Pickup',
                        hint: 'Where should we pick you up?',
                      ),
                      const Divider(height: 1),
                      _AddressField(
                        controller: _dropoffCtrl,
                        icon: Icons.location_on_rounded,
                        iconColor: AppTheme.error,
                        label: 'Drop-off',
                        hint: 'Where are you going?',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _SectionLabel('When'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TapField(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: _dateLabel,
                        onTap: _pickDate,
                        isPlaceholder: _scheduledDate == null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TapField(
                        icon: Icons.access_time_rounded,
                        label: 'Time',
                        value: _timeLabel,
                        onTap: _pickTime,
                        isPlaceholder: _scheduledTime == null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                _SectionLabel('Who & What'),
                const SizedBox(height: 10),
                _Card(
                  child: Column(
                    children: [
                      _CounterRow(
                        icon: Icons.person_rounded,
                        label: 'Passengers',
                        value: _passengers,
                        min: 1,
                        max: 10,
                        onChanged: (v) => setState(() => _passengers = v),
                      ),
                      const Divider(height: 1),
                      _CounterRow(
                        icon: Icons.luggage_rounded,
                        label: 'Luggage',
                        value: _luggage,
                        min: 0,
                        max: 20,
                        onChanged: (v) => setState(() => _luggage = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                _SectionLabel('Vehicle Type'),
                const SizedBox(height: 10),
                _Card(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _vehicleType,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: _vehicleTypes
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _vehicleType = v ?? 'Sedan'),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _SectionLabel('Notes (Optional)'),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    hintText: 'Any special requests?',
                    fillColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 24),
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
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WIDGETS
// ============================================================

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: Color(0xFF64748B),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _Card({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
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

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String hint;

  const _AddressField({
    required this.controller,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return '$label is required';
                }
                if (v.trim().length < 3) {
                  return 'Enter a valid address';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TapField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isPlaceholder;

  const _TapField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    required this.isPlaceholder,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
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
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),
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
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isPlaceholder
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
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

class _CounterRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CounterRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.remove_rounded,
            onTap: value > min ? () => onChanged(value - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _RoundIconButton(
            icon: Icons.add_rounded,
            onTap: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundIconButton({required this.icon, this.onTap});

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
            size: 18,
            color: enabled ? AppTheme.primary : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}