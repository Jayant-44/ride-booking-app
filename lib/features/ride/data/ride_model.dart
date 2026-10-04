class Ride {
  final String id;
  final String status;
  final String pickupAddress;
  final String dropoffAddress;
  final DateTime scheduledAt;
  final int passengers;
  final int luggageCount;
  final String? vehicleType;
  final String? notes;
  final DateTime createdAt;

  const Ride({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.scheduledAt,
    required this.passengers,
    required this.luggageCount,
    this.vehicleType,
    this.notes,
    required this.createdAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
        id: json['id'] as String,
        status: json['status'] as String,
        pickupAddress: json['pickupAddress'] as String,
        dropoffAddress: json['dropoffAddress'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
        passengers: json['passengers'] as int,
        luggageCount: json['luggageCount'] as int,
        vehicleType: json['vehicleType'] as String?,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      );

  String get statusLabel {
    switch (status) {
      case 'REQUESTED':
        return 'Pending Review';
      case 'ADMIN_REVIEW':
        return 'Under Review';
      case 'REJECTED':
        return 'Rejected';
      case 'QUOTED':
      case 'AWAITING_PAYMENT':
        return 'Awaiting Payment';
      case 'PAYMENT_FAILED':
        return 'Payment Failed';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'ASSIGNMENT_PENDING':
        return 'Finding Driver';
      case 'DRIVER_OFFERED':
        return 'Driver Notified';
      case 'DRIVER_ASSIGNED':
        return 'Driver Assigned';
      case 'EN_ROUTE':
        return 'Driver En Route';
      case 'ARRIVED':
        return 'Driver Arrived';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      case 'REVIEWED':
        return 'Reviewed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}