class User {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String role;
  final String status;
  final String timezone;
  final String currency;
  final String locale;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.status,
    required this.timezone,
    required this.currency,
    required this.locale,
  });

    Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'role': role,
        'status': status,
        'timezone': timezone,
        'currency': currency,
        'locale': locale,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        phone: json['phone'] as String,
        role: json['role'] as String,
        status: json['status'] as String,
        timezone: json['timezone'] as String? ?? 'UTC',
        currency: json['currency'] as String? ?? 'USD',
        locale: json['locale'] as String? ?? 'en',
      );
}