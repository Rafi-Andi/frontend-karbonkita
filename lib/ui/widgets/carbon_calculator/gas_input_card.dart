import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/carbon_calculator/carbon_calculator_cubit.dart';
import 'emission_slider_row.dart';

class GasInputCard extends StatelessWidget {
  const GasInputCard({super.key});

  void _showGuide(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panduan Pengisian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '• Hitung berapa tabung LPG yang habis selama 1 bulan.\n'
              '• Tabung melon hijau = 3 kg, tabung biru/pink = 12 kg.\n'
              '• Emisi = total kg LPG × 2,98 kg CO₂e (standar IPCC).\n'
              '• Contoh: 2 tabung melon = 6 kg ≈ 17,9 kg CO₂e.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarbonCalculatorCubit, CarbonCalculatorState>(
      builder: (context, state) {
        final cubit = context.read<CarbonCalculatorCubit>();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department_outlined,
                      color: Color(0xFF43A047),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pemakaian Gas LPG',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Masukkan jumlah tabung LPG per bulan.',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showGuide(context),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 14,
                          color: Colors.black45,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Panduan',
                          style: TextStyle(fontSize: 11, color: Colors.black45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              EmissionSliderRow(
                icon: Icons.propane_outlined,
                label: 'Tabung Melon 3 kg',
                value: state.gasTabung3kg.toDouble(),
                min: 0,
                max: 8,
                minLabel: '0',
                maxLabel: '8',
                displayValue: '${state.gasTabung3kg} tbng',
                onChanged: (v) => cubit.updateGasTabung3kg(v.round()),
              ),
              const SizedBox(height: 12),
              EmissionSliderRow(
                icon: Icons.propane_tank_outlined,
                label: 'Tabung 12 kg',
                value: state.gasTabung12kg.toDouble(),
                min: 0,
                max: 4,
                minLabel: '0',
                maxLabel: '4',
                displayValue: '${state.gasTabung12kg} tbng',
                onChanged: (v) => cubit.updateGasTabung12kg(v.round()),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Total: ${state.gasLpgKg.toStringAsFixed(state.gasLpgKg % 1 == 0 ? 0 : 1)} kg LPG / bulan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
