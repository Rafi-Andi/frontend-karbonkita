import 'package:flutter/material.dart';

/// Tombol lingkaran progres melingkar 1/3 → 2/3 → penuh.
/// Halaman terakhir memakai ikon centang, lainnya panah.
class OnboardingProgressButton extends StatelessWidget {
  const OnboardingProgressButton({
    super.key,
    required this.currentPage,
    required this.pageCount,
    required this.onPressed,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onPressed;

  static const Color primaryColor = Color(0xFF32A231);

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == pageCount - 1;
    final progress = (currentPage + 1) / pageCount;
    final label = isLast ? 'Selesai dan mulai' : 'Lanjut ke halaman berikutnya';

    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onPressed,
        child: SizedBox(
          width: 76,
          height: 76,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 2.5,
                  backgroundColor: Colors.grey.withValues(alpha: 0.25),
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLast ? Icons.check : Icons.arrow_forward,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
