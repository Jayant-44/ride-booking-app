class DriverAssignment {
  final String id;
  final String status;
  final DateTime offeredAt;
  final DateTime? respondedAt;
  final DriverRideInfo ride;
  final DriverVehicleInfo vehicle;

  const DriverAssignment({
    required this.id,
    required this.status,
    required this.offeredAt,
    required this.respondedAt,
    required this.ride,
    required this.vehicle,
  });

  bool get isOffered => status == 'OFFERED';
  bool get isAccepted => status == 'ACCEPTED';

  factory DriverAssignment.fromJson(Map<String, dynamic> json) =>
      DriverAssignment(
        id: json['id'] as String,
        status: json['status'] as String,
        offeredAt: DateTime.parse(json['offeredAt'] as String).toLocal(),
        respondedAt: json['respondedAt'] != null
            ? DateTime.parse(json['respondedAt'] as String).toLocal()
            : null,
        ride: DriverRideInfo.fromJson(json['ride'] as Map<String, dynamic>),
        vehicle:
            DriverVehicleInfo.fromJson(json['vehicle'] as Map<String, dynamic>),
      );
}

class DriverRideInfo {
  final String id;
  final String status;
  final String pickupAddress;
  final String dropoffAddress;
  final DateTime scheduledAt;
  final int passengers;
  final int luggageCount;
  final String? vehicleType;
  final String? notes;
  final DriverCustomerInfo customer;

  const DriverRideInfo({
    required this.id,
    required this.status,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.scheduledAt,
    required this.passengers,
    required this.luggageCount,
    required this.customer,
    this.vehicleType,
    this.notes,
  });

  factory DriverRideInfo.fromJson(Map<String, dynamic> json) => DriverRideInfo(
        id: json['id'] as String,
        status: json['status'] as String,
        pickupAddress: json['pickupAddress'] as String,
        dropoffAddress: json['dropoffAddress'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
        passengers: json['passengers'] as int,
        luggageCount: json['luggageCount'] as int,
        vehicleType: json['vehicleType'] as String?,
        notes: json['notes'] as String?,
        customer: DriverCustomerInfo.fromJson(
          json['customer'] as Map<String, dynamic>,
        ),
      );

  String get statusLabel {
    switch (status) {
      case 'DRIVER_OFFERED':
        return 'Offer Sent';
      case 'DRIVER_ASSIGNED':
        return 'Ready to Go';
      case 'EN_ROUTE':
        return 'Driver Assigned';
      case 'ARRIVED':
        return 'Arrived';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status;
    }
  }
}

class DriverCustomerInfo {
  final String fullName;
  final String? phone;
  final String? email;

  const DriverCustomerInfo({
    required this.fullName,
    this.phone,
    this.email,
  });

  bool get hasContact => phone != null && phone!.isNotEmpty;

  factory DriverCustomerInfo.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return DriverCustomerInfo(
      fullName: user['fullName'] as String,
      phone: user['phone'] as String?,
      email: user['email'] as String?,
    );
  }
}

class DriverVehicleInfo {
  final String id;
  final String make;
  final String model;
  final String plateNo;
  final String color;
  final int capacity;
  final int luggageCapacity;

  const DriverVehicleInfo({
    required this.id,
    required this.make,
    required this.model,
    required this.plateNo,
    required this.color,
    required this.capacity,
    required this.luggageCapacity,
  });

  String get displayName => '$make $model';

  factory DriverVehicleInfo.fromJson(Map<String, dynamic> json) =>
      DriverVehicleInfo(
        id: json['id'] as String,
        make: json['make'] as String,
        model: json['model'] as String,
        plateNo: json['plateNo'] as String,
        color: json['color'] as String,
        capacity: json['capacity'] as int,
        luggageCapacity: json['luggageCapacity'] as int? ?? 0,
      );
}