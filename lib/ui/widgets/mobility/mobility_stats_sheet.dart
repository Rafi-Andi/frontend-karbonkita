import 'package:flutter/material.dart';

/// Bottom sheet statistik tracker (Durasi / Jarak / tombol).
///
/// Aktivitas TERKUNCI mengikuti misi yang dipilih (tanpa toggle).
/// Ukuran kartu mengikuti konten (tanpa `height` hardcoded) agar teks
/// panjang tidak overflow di layar kecil. Estimasi karbon dihitung lokal
/// (210 g/km, sama dengan konstanta backend) — angka resmi tetap dari backend.
class MobilityStatsSheet extends StatelessWidget {
  const MobilityStatsSheet({
    super.key,
    required this.durationText,
    required this.distanceText,
    required this.targetProgress,
    required this.targetText,
    required this.co2Text,
    required this.activityType,
    required this.isPaused,
    required this.isSyncing,
    required this.onPauseResume,
    required this.onFinish,
    this.isSimulating = false,
  });

  final String durationText;
  final String distanceText;

  /// Progres 0..1 menuju target + label target ("Target 2.00 KM").
  final double targetProgress;
  final String targetText;
  final String co2Text;
  final String
  activityType; // 'cycling' | 'walking' | 'running' — terkunci dari misi
  final bool isPaused;
  final bool isSyncing;
  final VoidCallback onPauseResume;
  final VoidCallback onFinish;

  /// True saat rute berasal dari simulator demo (tetap divalidasi server).
  final bool isSimulating;

  @override
  Widget build(BuildContext context) {
    final activityLabel = switch (activityType) {
      'walking' => 'Jalan Kaki',
      'running' => 'Lari',
      _ => 'Bersepeda',
    };
    final activityIcon = switch (activityType) {
      'walking' => Icons.directions_walk,
      'running' => Icons.directions_run,
      _ => Icons.pedal_bike,
    };
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      activityIcon,
                      size: 18,
                      color: const Color(0xFF1B8039),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      activityLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B8039),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.lock, size: 14, color: Color(0xFF1B8039)),
                    const SizedBox(width: 4),
                    const Text(
                      'Terkunci misi',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    if (isSimulating) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9A825),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Demo',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(label: 'Durasi', value: durationText),
                  ),
                  Expanded(
                    child: _StatItem(label: 'Jarak', value: distanceText),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.flag, size: 14, color: Color(0xFF1B8039)),
                  const SizedBox(width: 4),
                  Text(
                    targetText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B8039),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: targetProgress.clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE8F5E9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1B8039),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(targetProgress.clamp(0.0, 1.0) * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B8039),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Karbon Hemat (estimasi)',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        co2Text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF43A047),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF43A047)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activityLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF43A047),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSyncing ? null : onPauseResume,
                      icon: Icon(
                        isPaused ? Icons.play_arrow : Icons.pause,
                        size: 18,
                      ),
                      label: Text(isPaused ? 'Lanjut' : 'Jeda'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF9A825),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isSyncing ? null : onFinish,
                      icon: isSyncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.stop, size: 18),
                      label: Text(isSyncing ? 'Mengirim...' : 'Selesai'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
