import 'package:flutter/material.dart';

import '../../../models/verify_waste_result.dart';

/// Isi bottom sheet hasil validasi AI dari backend.
///
/// Menampilkan data asli `POST /api/missions/verify-waste`:
/// kategori + confidence, XP/points, streak/level.
/// Disize dari konten ([mainAxisSize.min]) agar ~setengah layar.
class ValidationResultSheet extends StatelessWidget {
  const ValidationResultSheet({
    super.key,
    required this.result,
    required this.onContinue,
    this.onRetry,
  });

  final VerifyWasteResult result;
  final VoidCallback onContinue;

  /// Dipakai saat AI menolak foto (tombol "Coba Foto Lain").
  /// Null = sheet hanya punya satu CTA lanjut.
  final VoidCallback? onRetry;

  bool get _verified => result.verified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewPadding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildInfoCards(),
          const SizedBox(height: 12),
          _buildAntiFraudBanner(),
          const SizedBox(height: 14),
          _buildCtaButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final accent = _verified
        ? const Color(0xFF2E9E4B)
        : const Color(0xFFD32F2F);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/robot.png',
          width: 72,
          height: 72,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.smart_toy_outlined, color: accent, size: 36),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Validasi AI Gemini',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _verified ? 'Sukses!' : 'Ditolak AI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _verified
                    ? 'Sampahmu sudah terverifikasi AI'
                    : (result.rejectionReason ??
                          'Foto tidak sesuai misi. Coba foto lain.'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF8A938F)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    final accent = _verified
        ? const Color(0xFF2E9E4B)
        : const Color(0xFF8A938F);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _infoCard(
          label: 'Kategori',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.recycling, color: accent, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  result.categoryLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F6EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${result.confidence.toStringAsFixed(0)}% yakin',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _infoCard(
                label: 'Eco Points',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/ecopoints.png',
                      width: 22,
                      height: 22,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFF9A825),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${result.pointsEarned}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _infoCard(
                label: 'XP Didapatkan',
                child: Text(
                  '+${result.xpEarned} XP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_verified &&
            (result.streakDays != null || result.newLevel != null)) ...[
          const SizedBox(height: 10),
          _infoCard(
            label: 'Progresmu',
            child: Text(
              _progressText(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E7D32),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _progressText() {
    final parts = <String>[];
    if (result.streakDays != null) {
      parts.add('Streak ${result.streakDays} hari');
    }
    if (result.newLevel != null && result.newLevel!.isNotEmpty) {
      parts.add('Level ${result.newLevel}');
    }
    if (parts.isEmpty) return 'Mantap! 🌿';
    return '${parts.join(' • ')} 🔥';
  }

  Widget _infoCard({required String label, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E6E2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF8A938F)),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _buildAntiFraudBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F6EC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 18, color: Color(0xFF2E9E4B)),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sistem Anti-Fraud Aktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E6C46),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Foto dianalisis AI untuk memastikan keaslian dan mendukung lingkungan yang lebih bersih.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.check_circle, size: 18, color: Color(0xFF2E9E4B)),
        ],
      ),
    );
  }

  Widget _buildCtaButton() {
    final retry = onRetry;
    if (!_verified && retry != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B8039),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Coba Foto Lain',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onContinue,
              child: const Text(
                'Kembali ke Misi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A938F),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B8039),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lanjutkan Misi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 10),
            Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
