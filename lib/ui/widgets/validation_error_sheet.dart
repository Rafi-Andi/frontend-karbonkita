import 'package:flutter/material.dart';

/// Satu baris error validasi: label Indonesia + pesan ramah.
class ValidationErrorItem {
  const ValidationErrorItem({required this.label, required this.message});

  final String label;
  final String message;
}

/// Label Indonesia untuk field backend (register mitra + umum).
const Map<String, String> kValidationFieldLabels = {
  'name': 'Nama lengkap',
  'email': 'Email',
  'phone': 'No HP',
  'phone_or_email': 'No HP/Email',
  'password': 'Kata sandi',
  'password_confirmation': 'Konfirmasi kata sandi',
  'city': 'Kota domisili',
  'district': 'Kecamatan domisili',
  'sub_district': 'Kelurahan domisili',
  'rt': 'RT domisili',
  'rw': 'RW domisili',
  'nama_usaha': 'Nama usaha',
  'jenis_usaha': 'Jenis usaha',
  'alamat_usaha': 'Alamat usaha',
  'usaha_kelurahan': 'Kelurahan usaha',
  'usaha_kecamatan': 'Kecamatan usaha',
  'usaha_kota': 'Kota usaha',
  'usaha_provinsi': 'Provinsi usaha',
  'usaha_kode_pos': 'Kode pos usaha',
  'nomor_ktp': 'Nomor KTP',
  'nomor_nib': 'Nomor NIB',
  'foto_ktp': 'Foto KTP',
  'foto_nib': 'Foto NIB',
  'foto_toko': 'Foto depan toko',
  'foto_toko_2': 'Foto toko 2',
  'foto_toko_3': 'Foto toko 3',
  'nama_bank': 'Nama bank',
  'nomor_rekening': 'Nomor rekening',
  'nama_pemilik_rekening': 'Nama pemilik rekening',
  'unique_code': 'Kode voucher',
  'is_open': 'Status toko',
  'action': 'Aksi verifikasi',
  'reason': 'Alasan',
  'title': 'Judul misi',
  'description': 'Deskripsi misi',
  'category': 'Kategori misi',
  'xp_reward': 'XP reward',
  'points_reward': 'Poin reward',
  'icon': 'Ikon misi',
  'activity_type': 'Aktivitas misi',
  'target_distance_km': 'Target jarak',
  'validation_prompt': 'Kriteria foto',
  'is_active': 'Status misi',
  'max_participants': 'Maksimal peserta',
};

/// Ubah pesan validasi mentah Laravel (Inggris) jadi Indonesia yang ramah.
/// Pesan yang sudah Indonesia (custom messages backend) diteruskan apa adanya.
String friendlyValidationMessage(String field, String raw) {
  final msg = raw.trim();
  if (msg.isEmpty) return 'Tidak valid.';

  var m = RegExp(r'must not be greater than (\d+) kilobytes').firstMatch(msg);
  if (m != null) {
    final kb = int.tryParse(m.group(1)!) ?? 0;
    final mb = kb >= 1024
        ? '${(kb / 1024).toStringAsFixed(kb % 1024 == 0 ? 0 : 1)} MB'
        : '$kb KB';
    return 'Ukuran file maksimal $mb.';
  }
  if (RegExp(r'must be a file of type').hasMatch(msg)) {
    final types = RegExp(r'type:\s*(.+)').firstMatch(msg)?.group(1);
    return types != null && types.isNotEmpty
        ? 'Format file harus $types.'
        : 'Format file tidak didukung (pakai JPG/PNG).';
  }
  if (msg.contains('has already been taken')) {
    return 'Sudah terdaftar, gunakan yang lain.';
  }
  m = RegExp(r'must be (\d+) digits').firstMatch(msg);
  if (m != null) return 'Harus tepat ${m.group(1)} digit angka.';
  if (RegExp(r'must be a valid email address').hasMatch(msg)) {
    return 'Format email tidak valid.';
  }
  if (msg.contains('confirmation') && msg.contains('match')) {
    return 'Konfirmasi tidak cocok.';
  }
  m = RegExp(r'must be at least (\d+) characters').firstMatch(msg);
  if (m != null) return 'Minimal ${m.group(1)} karakter.';
  m = RegExp(r'may not be greater than (\d+) characters').firstMatch(msg);
  if (m != null) return 'Maksimal ${m.group(1)} karakter.';
  if (RegExp(r'must be (a number|an integer|numeric)').hasMatch(msg)) {
    return 'Harus berupa angka.';
  }
  if (RegExp(r'must be a valid date|must be a date after').hasMatch(msg)) {
    return 'Tanggal tidak valid.';
  }
  if (msg.contains('does not exist') || msg.contains('not found')) {
    return 'Data tidak ditemukan.';
  }
  if (RegExp(r'(field is required|is required\.)').hasMatch(msg)) {
    return 'Wajib diisi.';
  }
  if (msg.contains('must be a string')) return 'Wajib diisi teks.';
  if (msg.contains('must be true') || msg.contains('must be accepted')) {
    return 'Harus disetujui.';
  }
  return msg;
}

/// Ratakan map `errors` backend {field: [pesan..]} jadi daftar item tampil.
/// Semua pesan per field ikut (bukan cuma yang pertama).
List<ValidationErrorItem> collectValidationErrors(
  Map<String, List<String>> errors, {
  Map<String, String> labels = kValidationFieldLabels,
}) {
  final items = <ValidationErrorItem>[];
  errors.forEach((field, messages) {
    final label = labels[field] ?? _prettyField(field);
    for (final raw in messages) {
      final text = raw.trim();
      if (text.isEmpty) continue;
      items.add(
        ValidationErrorItem(
          label: label,
          message: friendlyValidationMessage(field, text),
        ),
      );
    }
  });
  return items;
}

String _prettyField(String field) {
  if (field.isEmpty) return 'Data';
  final words = field.replaceAll('_', ' ').split(' ');
  return words
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

/// Bottom sheet daftar rincian error validasi.
class ValidationErrorSheet extends StatelessWidget {
  const ValidationErrorSheet({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<ValidationErrorItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: 80,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDECEA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Color(0xFFC62828),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${items.length} masalah perlu diperbaiki',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in items) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFE65100),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8039),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Perbaiki Form',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilkan bottom sheet rincian error; return langsung bila kosong.
void showValidationErrorSheet(
  BuildContext context, {
  required String title,
  required Map<String, List<String>> errors,
  Map<String, String> labels = kValidationFieldLabels,
}) {
  final items = collectValidationErrors(errors, labels: labels);
  if (items.isEmpty) return;
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ValidationErrorSheet(title: title, items: items),
  );
}
