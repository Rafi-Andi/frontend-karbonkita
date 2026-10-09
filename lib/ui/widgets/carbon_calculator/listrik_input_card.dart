import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/carbon_calculator/carbon_calculator_cubit.dart';
import 'emission_slider_row.dart';

class ListrikInputCard extends StatelessWidget {
  const ListrikInputCard({super.key});

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
              '• Masukkan total pemakaian listrik rumah selama 1 bulan (0–600 kWh).\n'
              '• Lihat struk PLN / aplikasi PLN Mobile untuk angka pastinya.\n'
              '• Rata-rata rumah tangga Indonesia sekitar 100–200 kWh per bulan.\n'
              '• Emisi = kWh × 0,87 kg CO₂e (grid Jawa-Madura-Bali).',
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
                      Icons.bolt_outlined,
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
                          'Pemakaian Listrik',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Masukkan total kWh listrik rumahmu per bulan.',
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
                icon: Icons.electric_meter_outlined,
                label: 'Konsumsi Listrik',
                value: state.listrikKwh,
                min: 0,
                max: 600,
                minLabel: '0 kWh',
                maxLabel: '600 kWh',
                displayValue: '${state.listrikKwh.round()} kWh',
                onChanged: cubit.updateListrikKwh,
              ),
            ],
          ),
        );
      },
    );
  }
}
