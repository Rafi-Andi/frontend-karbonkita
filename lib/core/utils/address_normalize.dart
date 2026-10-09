/// Normalisasi input register di sisi client.
///
/// Backend yang sudah deploy hanya menerima string bebas untuk
/// `city/district/sub_district/rt/rw`, jadi konsistensi data (mis.
/// `Surabaya` vs `Sby`, `5` vs `005`) harus dijamin Flutter sebelum POST.
/// Payload yang dikirim ke backend tidak berubah bentuk.
library;

/// Rapikan nama wilayah: pangkas spasi tepi + padatkan spasi ganda.
/// Nama dari API wilayah dipakai apa adanya (jangan diubah case-nya).
String canonicalName(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Ambil digit saja dari input RT lalu pad ke 3 digit (`5` → `005`).
/// Return '' bila tidak ada digit (dianggap invalid oleh [isValidRt]).
String normalizeRt(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final trimmed = digits.length > 3
      ? digits.substring(digits.length - 3)
      : digits;
  return trimmed.padLeft(3, '0');
}

/// Sama seperti [normalizeRt] tapi pad ke 2 digit (`2` → `02`).
String normalizeRw(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final trimmed = digits.length > 2
      ? digits.substring(digits.length - 2)
      : digits;
  return trimmed.padLeft(2, '0');
}

bool isValidRt(String value) => RegExp(r'^\d{1,3}$').hasMatch(value.trim());

bool isValidRw(String value) => RegExp(r'^\d{1,2}$').hasMatch(value.trim());

/// Normalisasi ke format internasional backend (`^\+[0-9]{10,15}$`).
/// Terima `08…`, `628…`, `+628…`, `8…` (UI menampilkan prefix +62).
String normalizePhone(String value) {
  var v = value.trim().replaceAll(RegExp(r'[\s\-.]'), '');
  if (v.startsWith('+62')) {
    final rest = v.substring(3).replaceAll(RegExp(r'\D'), '');
    final clean = rest.startsWith('0') ? rest.substring(1) : rest;
    return '+62$clean';
  }
  final digits = v.startsWith('+') ? v.substring(1) : v;
  final clean = digits.replaceAll(RegExp(r'\D'), '');
  if (clean.startsWith('62')) return '+$clean';
  if (clean.startsWith('0')) return '+62${clean.substring(1)}';
  return '+62$clean';
}

bool isValidPhone(String value) =>
    RegExp(r'^\+[0-9]{10,15}$').hasMatch(normalizePhone(value));

bool isValidEmail(String value) {
  final v = value.trim();
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
}
