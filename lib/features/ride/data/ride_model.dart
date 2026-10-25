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
  final AssignedDriver? assignedDriver;
  final AssignedVehicle? assignedVehicle;

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
    this.assignedDriver,
    this.assignedVehicle,
  });

  static AssignedDriver? _parseAssignedDriver(dynamic assignments) {
    if (assignments is! List || assignments.isEmpty) return null;
    final first = assignments.first as Map<String, dynamic>;
    final driver = first['driver'] as Map<String, dynamic>?;
    if (driver == null) return null;
    return AssignedDriver.fromJson(driver);
  }

  static AssignedVehicle? _parseAssignedVehicle(dynamic assignments) {
    if (assignments is! List || assignments.isEmpty) return null;
    final first = assignments.first as Map<String, dynamic>;
    final vehicle = first['vehicle'] as Map<String, dynamic>?;
    if (vehicle == null) return null;
    return AssignedVehicle.fromJson(vehicle);
  }

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
        assignedDriver: _parseAssignedDriver(json['assignments']),
        assignedVehicle: _parseAssignedVehicle(json['assignments']),
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
        return 'Invoice Sent';
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
        return 'Driver Assigned';
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

class AssignedDriver {
  final String id;
  final String fullName;
  final String phone;

  const AssignedDriver({
    required this.id,
    required this.fullName,
    required this.phone,
  });

  factory AssignedDriver.fromJson(Map<String, dynamic> json) => AssignedDriver(
        id: json['id'] as String,
        fullName: (json['user'] as Map<String, dynamic>)['fullName'] as String,
        phone: (json['user'] as Map<String, dynamic>)['phone'] as String,
      );
}

class AssignedVehicle {
  final String id;
  final String make;
  final String model;
  final String plateNo;
  final String color;
  final int capacity;

  const AssignedVehicle({
    required this.id,
    required this.make,
    required this.model,
    required this.plateNo,
    required this.color,
    required this.capacity,
  });

  String get displayName => '$make $model';

  factory AssignedVehicle.fromJson(Map<String, dynamic> json) =>
      AssignedVehicle(
        id: json['id'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        plateNo: json['plateNo'] as String,
        color: json['color'] as String,
        capacity: json['capacity'] as int,
      );
}