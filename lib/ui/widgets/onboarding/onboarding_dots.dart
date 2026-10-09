import 'package:flutter/material.dart';

/// Indikator titik 3 halaman. Aktif hijau #32A231 dan lebih lebar.
class OnboardingDots extends StatelessWidget {
  const OnboardingDots({super.key, required this.currentPage, this.count = 3});

  final int currentPage;
  final int count;

  static const Color activeColor = Color(0xFF32A231);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
