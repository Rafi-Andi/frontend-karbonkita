import 'package:flutter/material.dart';

/// Satu langkah penyelesaian misi (statis per kategori).
///
/// Sumber tunggal konten langkah agar [MisiScreen] dan
/// [MissionDetailScreen] selalu konsisten. Tanpa backend: langkah
/// dibedakan per `category` saja (`mobility` / `waste`), target jarak
/// misi disisipkan ke teks langkah mobilitas.
class MissionStep {
  const MissionStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

/// Kembalikan langkah penyelesaian untuk kategori misi.
///
/// [targetDistanceKm] hanya dipakai kategori `mobility` untuk
/// menginterpolasi teks target (fallback 0,1 KM mengikuti backend).
List<MissionStep> getMissionSteps({
  required String category,
  double? targetDistanceKm,
}) {
  switch (category) {
    case 'mobility':
      final target = (targetDistanceKm ?? 0.1).toStringAsFixed(1);
      return [
        const MissionStep(
          icon: Icons.gps_fixed,
          title: 'Aktifkan GPS & koneksi',
          subtitle: 'Pastikan layanan lokasi menyala sebelum mulai tracking.',
        ),
        const MissionStep(
          icon: Icons.play_circle_outline,
          title: 'Tekan "Mulai Tracker"',
          subtitle: 'Pilih mode jalan kaki atau bersepeda sesuai misi.',
        ),
        MissionStep(
          icon: Icons.flag_outlined,
          title: 'Capai target $target KM',
          subtitle:
              'Selesaikan dalam satu sesi tracking hingga jarak terpenuhi.',
        ),
        const MissionStep(
          icon: Icons.speed_outlined,
          title: 'Jaga kecepatan wajar',
          subtitle:
              'Aktivitas jalan/sepeda di bawah 30 km/jam agar tidak ditolak.',
        ),
        const MissionStep(
          icon: Icons.cloud_done_outlined,
          title: 'Selesaikan & sinkronkan',
          subtitle:
              'Akhiri sesi untuk sinkron otomatis. Reward masuk 1x per misi per hari.',
        ),
      ];
    case 'waste':
      return const [
        MissionStep(
          icon: Icons.recycling_outlined,
          title: 'Pilah sampah sesuai misi',
          subtitle:
              'Pisahkan jenis sampah yang diminta (mis. plastik/elektronik), jangan tercampur.',
        ),
        MissionStep(
          icon: Icons.inventory_2_outlined,
          title: 'Tata agar terlihat jelas',
          subtitle:
              'Letakkan di wadah atau kantong terpisah dengan pencahayaan cukup.',
        ),
        MissionStep(
          icon: Icons.photo_camera_outlined,
          title: 'Tekan "Upload Foto" & foto',
          subtitle: 'Ambil foto di dalam bingkai kamera hingga fokus.',
        ),
        MissionStep(
          icon: Icons.smart_toy_outlined,
          title: 'Tunggu validasi AI',
          subtitle:
              'Analisis AI sekitar 20 detik. Jika ditolak, foto ulang lebih jelas.',
        ),
        MissionStep(
          icon: Icons.no_photography_outlined,
          title: 'Pakai foto baru setiap kirim',
          subtitle:
              'Foto duplikat otomatis ditolak. Berlaku 1x per misi per hari.',
        ),
      ];
    default:
      return const [
        MissionStep(
          icon: Icons.play_arrow_outlined,
          title: 'Mulai misi',
          subtitle: 'Ikuti instruksi pada halaman misi ini.',
        ),
      ];
  }
}

/// Tips singkat per kategori untuk [MissionDetailScreen].
List<String> getMissionTips(String category) {
  switch (category) {
    case 'mobility':
      return const [
        'Baterai cukup & GPS akurat mempercepat penguncian titik start.',
        'Satu misi hanya bisa diselesaikan sekali sehari (reset besok).',
      ];
    case 'waste':
      return const [
        'Hindari bayangan menutupi sampah dan foto buram.',
        'Sampah tercampur atau bukan jenis yang diminta pasti ditolak AI.',
      ];
    default:
      return const [];
  }
}

/// Tebak mode tracker dari judul misi mobilitas.
/// `cycling` bila menyebut sepeda, selain itu `walking`.
String activityTypeFromTitle(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('sepeda') ||
      lower.contains('cycling') ||
      lower.contains('pedal') ||
      lower.contains('kayuh')) {
    return 'cycling';
  }
  return 'walking';
}
