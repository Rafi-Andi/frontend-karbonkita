import 'package:flutter/material.dart';

/// Dialog khusus tiap hasil verifikasi sampah yang bukan sukses.
///
/// Backend membedakan kasus lewat status HTTP + payload `data`:
/// - 409 duplicate → foto sudah pernah dipakai (anti-fraud).
/// - 409 daily-cap → misi sudah verified hari ini.
/// - 503 → AI down, foto masuk antrean pending.
/// - lainnya (422/401/jaringan) → failure umum dengan retry.
Future<void> showDuplicateWasteDialog(
  BuildContext context, {
  required String message,
  required VoidCallback onBackToMissions,
}) {
  return _showWasteDialog(
    context,
    icon: Icons.copy_all_outlined,
    iconColor: const Color(0xFFD97706),
    iconBg: const Color(0xFFFEF3C7),
    title: 'Foto Sudah Pernah Dipakai',
    body: message,
    hint:
        'Sistem anti-fraud menolak foto duplikat. '
        'Ambil foto baru yang berbeda untuk misi ini.',
    primaryLabel: 'Kembali ke Misi',
    onPrimary: onBackToMissions,
  );
}

Future<void> showDailyCappedWasteDialog(
  BuildContext context, {
  required String message,
  required VoidCallback onBackToMissions,
}) {
  return _showWasteDialog(
    context,
    icon: Icons.check_circle_outline,
    iconColor: const Color(0xFF2E9E4B),
    iconBg: const Color(0xFFE9F6EC),
    title: 'Misi Hari Ini Selesai',
    body: message,
    hint:
        'Setiap misi sampah hanya bisa diklaim 1x sehari. '
        'Kembali lagi besok untuk klaim lagi.',
    primaryLabel: 'Kembali ke Misi',
    onPrimary: onBackToMissions,
  );
}

Future<void> showPendingWasteDialog(
  BuildContext context, {
  required String message,
  required VoidCallback onRetry,
  required VoidCallback onBackToMissions,
}) {
  return _showWasteDialog(
    context,
    icon: Icons.hourglass_top_outlined,
    iconColor: const Color(0xFF1565C0),
    iconBg: const Color(0xFFE3F2FD),
    title: 'AI Sedang Sibuk',
    body: message,
    hint:
        'Foto sudah tersimpan dan masuk antrean. '
        'Coba kirim ulang dalam beberapa saat.',
    primaryLabel: 'Coba Lagi',
    onPrimary: onRetry,
    secondaryLabel: 'Kembali ke Misi',
    onSecondary: onBackToMissions,
  );
}

Future<void> showWasteFailureDialog(
  BuildContext context, {
  required String message,
  required VoidCallback onRetry,
  required VoidCallback onBackToMissions,
}) {
  return _showWasteDialog(
    context,
    icon: Icons.cloud_off_outlined,
    iconColor: const Color(0xFFD32F2F),
    iconBg: const Color(0xFFFFEBEE),
    title: 'Verifikasi Gagal',
    body: message,
    hint:
        'Periksa koneksi dan pastikan foto berekstensi JPG/PNG '
        'dengan ukuran maksimal 5MB.',
    primaryLabel: 'Coba Lagi',
    onPrimary: onRetry,
    secondaryLabel: 'Kembali ke Misi',
    onSecondary: onBackToMissions,
  );
}

Future<void> _showWasteDialog(
  BuildContext context, {
  required IconData icon,
  required Color iconColor,
  required Color iconBg,
  required String title,
  required String body,
  required String hint,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 34),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5A5A5A)),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF8A938F)),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (secondaryLabel != null && onSecondary != null)
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onSecondary();
            },
            child: Text(
              secondaryLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A938F),
              ),
            ),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            onPrimary();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B8039),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            primaryLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}
