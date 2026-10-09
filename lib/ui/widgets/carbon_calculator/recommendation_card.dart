import 'package:flutter/material.dart';
import '../../../bloc/carbon_calculator/carbon_calculator_cubit.dart';

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({
    super.key,
    required this.isHighEmission,
    required this.category,
  });

  final bool isHighEmission;
  final CarbonCategory category;

  String get _title {
    switch (category) {
      case CarbonCategory.kendaraan:
        return isHighEmission
            ? 'Bersepeda atau jalan kaki 20 km'
            : 'Servis rutin + naik transportasi umum 1× seminggu';
      case CarbonCategory.listrik:
        return isHighEmission
            ? 'Ganti 5 lampu ke LED + cabut standby elektronik'
            : 'Matikan AC 1 jam lebih awal tiap hari';
      case CarbonCategory.gas:
        return isHighEmission
            ? 'Tutup panci saat memasak + kecilkan api bila mendidih'
            : 'Cek selang regulator agar tak ada kebocoran gas';
    }
  }

  String get _subtitle {
    switch (category) {
      case CarbonCategory.kendaraan:
        return isHighEmission
            ? 'Bisa mengurangi sekitar 20 kg CO₂e!'
            : 'Bisa mengurangi sekitar 10 kg CO₂e!';
      case CarbonCategory.listrik:
        return isHighEmission
            ? 'Bisa menghemat sekitar 30 kWh (~26 kg CO₂e)!'
            : 'Bisa menghemat sekitar 15 kWh (~13 kg CO₂e)!';
      case CarbonCategory.gas:
        return isHighEmission
            ? 'Bisa menghemat sekitar 3 kg LPG (~9 kg CO₂e)!'
            : 'Bisa menghemat sekitar 1,5 kg LPG (~4,5 kg CO₂e)!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _title;
    final subtitle = _subtitle;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF43A047).withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.eco,
                  color: Color(0xFF43A047),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rekomendasi untuk Kamu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Langkah kecil hari ini, dampak besar untuk bumi.',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TARGET BULAN DEPAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Image.asset(
                'assets/images/cycling.png',
                width: 90,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 90,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pedal_bike,
                    color: Color(0xFF43A047),
                    size: 48,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
