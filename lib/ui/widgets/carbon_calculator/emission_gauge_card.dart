import 'package:flutter/material.dart';
import '../../../bloc/carbon_calculator/carbon_calculator_cubit.dart';
import 'emission_gauge_painter.dart';

class EmissionGaugeCard extends StatelessWidget {
  const EmissionGaugeCard({
    super.key,
    required this.emissionKg,
    required this.progress,
    required this.category,
    required this.offsetKm,
  });

  final double emissionKg;
  final double progress;
  final CarbonCategory category;
  final double offsetKm;

  String get _meaningText {
    switch (category) {
      case CarbonCategory.kendaraan:
        return 'Emisi ini berasal dari penggunaan kendaraan bermotor Anda selama 1 bulan.';
      case CarbonCategory.listrik:
        return 'Emisi ini berasal dari pemakaian listrik rumah Anda selama 1 bulan.';
      case CarbonCategory.gas:
        return 'Emisi ini berasal dari pemakaian gas LPG Anda selama 1 bulan.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Perkiraan Emisi Anda',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 350),
                      builder: (context, animated, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 110,
                          child: CustomPaint(
                            painter: EmissionGaugePainter(progress: animated),
                          ),
                        );
                      },
                    ),
                    Transform.translate(
                      offset: const Offset(0, -52),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.eco,
                            color: Color(0xFF43A047),
                            size: 14,
                          ),
                          Text(
                            emissionKg.toStringAsFixed(
                              emissionKg >= 100 ? 0 : 1,
                            ),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              height: 1.1,
                            ),
                          ),
                          const Text(
                            'kg CO₂e / bulan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.eco, color: Color(0xFF43A047), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Artinya',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _meaningText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Setara ${offsetKm.toStringAsFixed(offsetKm >= 100 ? 0 : 1)} km bersepeda untuk mengimbanginya.',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
