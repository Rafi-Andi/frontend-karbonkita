/// Error terstandarisasi dari API Voucher/Marketplace.
///
/// Backend selalu membungkus response {success, message, data[, errors]}.
/// 422 membawa `errors` per-field dari Laravel FormRequest.
class VoucherException implements Exception {
  const VoucherException(
    this.message, {
    this.errors = const {},
    this.statusCode,
  });

  final String message;
  final Map<String, List<String>> errors;
  final int? statusCode;

  /// Ambil pesan error pertama untuk field tertentu (untuk errorText).
  String? fieldError(String field) {
    final list = errors[field];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }
}
