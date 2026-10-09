/// Error terstandarisasi dari API Mission.
///
/// Backend selalu membungkus response {success, message, data[, errors]}.
/// 422 membawa `errors` per-field dari Laravel FormRequest.
class MissionException implements Exception {
  const MissionException(
    this.message, {
    this.errors = const {},
    this.statusCode,
    this.data,
  });

  final String message;
  final Map<String, List<String>> errors;
  final int? statusCode;

  /// Payload `data` dari envelope backend (untuk bedakan 409
  /// duplicate vs daily-cap, 503 pending, dll).
  final Map<String, dynamic>? data;

  /// Ambil pesan error pertama untuk field tertentu (untuk errorText).
  String? fieldError(String field) {
    final list = errors[field];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }
}
