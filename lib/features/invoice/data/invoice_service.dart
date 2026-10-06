import 'package:dio/dio.dart';

import '../../../core/config/api_client.dart';
import 'invoice_model.dart';

class InvoiceListResult {
  final bool success;
  final List<Invoice>? invoices;
  final String? error;

  InvoiceListResult.success(this.invoices)
      : success = true,
        error = null;

  InvoiceListResult.failure(this.error)
      : success = false,
        invoices = null;
}

class InvoiceActionResult {
  final bool success;
  final Invoice? invoice;
  final String? error;

  InvoiceActionResult.success(this.invoice)
      : success = true,
        error = null;

  InvoiceActionResult.failure(this.error)
      : success = false,
        invoice = null;
}

class InvoiceService {
  final Dio _dio = ApiClient().dio;

  Future<InvoiceListResult> getMyInvoices() async {
    try {
      final response = await _dio.get('/invoices/my');
      final data = response.data['data'] as List<dynamic>;
      final invoices = data
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList();
      return InvoiceListResult.success(invoices);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString() ??
          'Unable to load invoices';
      return InvoiceListResult.failure(message);
    } catch (e) {
      return InvoiceListResult.failure('Unexpected error: $e');
    }
  }

  Future<InvoiceActionResult> getInvoiceById(String invoiceId) async {
    try {
      final response = await _dio.get('/invoices/$invoiceId');
      final invoice = Invoice.fromJson(response.data['data']);
      return InvoiceActionResult.success(invoice);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString() ??
          'Unable to load invoice';
      return InvoiceActionResult.failure(message);
    } catch (e) {
      return InvoiceActionResult.failure('Unexpected error: $e');
    }
  }

  Future<InvoiceActionResult> payInvoice(String invoiceId) async {
    try {
      final response = await _dio.post(
        '/invoices/$invoiceId/pay',
        data: {'paymentMethod': 'manual'},
      );
      final invoice = Invoice.fromJson(response.data['data']);
      return InvoiceActionResult.success(invoice);
    } on DioException catch (e) {
      final message = e.response?.data?['message']?.toString() ??
          'Payment failed';
      return InvoiceActionResult.failure(message);
    } catch (e) {
      return InvoiceActionResult.failure('Unexpected error: $e');
    }
  }
}