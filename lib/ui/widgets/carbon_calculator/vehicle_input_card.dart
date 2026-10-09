import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/carbon_calculator/carbon_calculator_cubit.dart';
import 'emission_slider_row.dart';
import 'vehicle_type_selector.dart';

class VehicleInputCard extends StatelessWidget {
  const VehicleInputCard({super.key});

  void _showGuide(BuildContext context, VehicleType type) {
    final consumption = type.consumptionKmPerLiter;
    final typeLabel = type.label;
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panduan Pengisian',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '• Jarak tempuh: total kilometer $typeLabel Anda selama 1 bulan (0–1000 km).\n'
              '• Konsumsi BBM: total liter yang dibeli selama 1 bulan (0–50 L).\n'
              '• Bila konsumsi 0 tapi jarak diisi, emisi diestimasi dari jarak ÷ $consumption km/L.\n'
              '• Emisi = liter × faktor emisi (Bensin 2,31 / Solar 2,68 kg CO₂e/L).',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
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
                      Icons.directions_bike,
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
                          'Penggunaan Kendaraan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Masukkan data penggunaan kendaraanmu per bulan.',
                          style: TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showGuide(context, state.vehicleType),
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
              VehicleTypeSelector(
                selected: state.vehicleType,
                onSelected: cubit.updateVehicleType,
              ),
              const SizedBox(height: 16),
              EmissionSliderRow(
                icon: Icons.two_wheeler,
                label: state.vehicleType == VehicleType.motor
                    ? 'Jarak Tempuh Motor'
                    : 'Jarak Tempuh Mobil',
                value: state.jarakKm,
                min: 0,
                max: 1000,
                minLabel: '0 km',
                maxLabel: '1000 km',
                displayValue: '${state.jarakKm.round()} km',
                onChanged: cubit.updateJarak,
              ),
              const SizedBox(height: 12),
              EmissionSliderRow(
                icon: Icons.water_drop_outlined,
                label: 'Konsumsi Bahan Bakar',
                value: state.bbmLiter,
                min: 0,
                max: 50,
                minLabel: '0 L',
                maxLabel: '50 L',
                displayValue: state.bbmLiter % 1 == 0
                    ? '${state.bbmLiter.round()} Liter'
                    : '${state.bbmLiter.toStringAsFixed(1)} Liter',
                onChanged: cubit.updateBbm,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.local_gas_station_outlined,
                    color: Color(0xFF43A047),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Jenis Bahan Bakar',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<FuelType>(
                // Pakai key agar dropdown me-reset saat tipe kendaraan berubah
                // dan BBM lama tak lagi valid (mis. Solar untuk Motor).
                key: ValueKey(state.vehicleType),
                initialValue: state.fuelType,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: state.vehicleType.allowedFuels
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(
                          f.label,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) cubit.updateFuelType(v);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
