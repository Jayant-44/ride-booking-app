class InvoiceRide {
  final String id;
  final String pickupAddress;
  final String dropoffAddress;
  final DateTime scheduledAt;
  final String status;

  const InvoiceRide({
    required this.id,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.scheduledAt,
    required this.status,
  });

  factory InvoiceRide.fromJson(Map<String, dynamic> json) => InvoiceRide(
        id: json['id'] as String,
        pickupAddress: json['pickupAddress'] as String,
        dropoffAddress: json['dropoffAddress'] as String,
        scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
        status: json['status'] as String,
      );
}

class Invoice {
  final String id;
  final String invoiceNo;
  final int subtotalCents;
  final int taxCents;
  final int totalCents;
  final String currencyCode;
  final String status; // DRAFT, SENT, PAID, OVERDUE, CANCELLED
  final DateTime? dueAt;
  final DateTime? sentAt;
  final DateTime? paidAt;
  final DateTime createdAt;
  final InvoiceRide? ride;

  const Invoice({
    required this.id,
    required this.invoiceNo,
    required this.subtotalCents,
    required this.taxCents,
    required this.totalCents,
    required this.currencyCode,
    required this.status,
    required this.dueAt,
    required this.sentAt,
    required this.paidAt,
    required this.createdAt,
    required this.ride,
  });

  bool get isPaid => status == 'PAID';
  bool get isPayable => status == 'SENT' || status == 'OVERDUE';

  String get subtotalFormatted => _formatCents(subtotalCents);
  String get taxFormatted => _formatCents(taxCents);
  String get totalFormatted => _formatCents(totalCents);

  String _formatCents(int cents) {
    final rupees = cents / 100;
    final symbol = _currencySymbol(currencyCode);
    return '$symbol${rupees.toStringAsFixed(2)}';
  }

  String _currencySymbol(String code) {
    switch (code) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '$code ';
    }
  }

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as String,
        invoiceNo: json['invoiceNo'] as String,
        subtotalCents: json['subtotalCents'] as int,
        taxCents: json['taxCents'] as int,
        totalCents: json['totalCents'] as int,
        currencyCode: json['currencyCode'] as String,
        status: json['status'] as String,
        dueAt: json['dueAt'] != null
            ? DateTime.parse(json['dueAt'] as String).toLocal()
            : null,
        sentAt: json['sentAt'] != null
            ? DateTime.parse(json['sentAt'] as String).toLocal()
            : null,
        paidAt: json['paidAt'] != null
            ? DateTime.parse(json['paidAt'] as String).toLocal()
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        ride: json['ride'] != null
            ? InvoiceRide.fromJson(json['ride'] as Map<String, dynamic>)
            : null,
      );
}