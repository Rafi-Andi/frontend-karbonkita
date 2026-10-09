import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/carbon_calculator/carbon_calculator_cubit.dart';
import '../widgets/carbon_calculator/category_tab_bar.dart';
import '../widgets/carbon_calculator/emission_gauge_card.dart';
import '../widgets/carbon_calculator/gas_input_card.dart';
import '../widgets/carbon_calculator/listrik_input_card.dart';
import '../widgets/carbon_calculator/recommendation_card.dart';
import '../widgets/carbon_calculator/vehicle_input_card.dart';

class CarbonCalculatorScreen extends StatelessWidget {
  const CarbonCalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CarbonCalculatorCubit(),
      child: const _CarbonCalculatorView(),
    );
  }
}

class _CarbonCalculatorView extends StatelessWidget {
  const _CarbonCalculatorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Kalkulator Jejak Karbon',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, color: Color(0xFF43A047), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Hitung, pahami, dan kurangi jejak karbonmu.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<CarbonCalculatorCubit, CarbonCalculatorState>(
                buildWhen: (p, c) => p.category != c.category,
                builder: (context, state) {
                  final cubit = context.read<CarbonCalculatorCubit>();
                  return CategoryTabBar(
                    selected: state.category,
                    onSelected: cubit.switchCategory,
                  );
                },
              ),
              const SizedBox(height: 12),
              BlocBuilder<CarbonCalculatorCubit, CarbonCalculatorState>(
                buildWhen: (p, c) =>
                    p.category != c.category ||
                    p.emissionKg != c.emissionKg ||
                    p.jarakKm != c.jarakKm ||
                    p.bbmLiter != c.bbmLiter ||
                    p.fuelType != c.fuelType ||
                    p.vehicleType != c.vehicleType ||
                    p.listrikKwh != c.listrikKwh ||
                    p.gasTabung3kg != c.gasTabung3kg ||
                    p.gasTabung12kg != c.gasTabung12kg,
                builder: (context, state) {
                  return Column(
                    children: [
                      switch (state.category) {
                        CarbonCategory.kendaraan => const VehicleInputCard(),
                        CarbonCategory.listrik => const ListrikInputCard(),
                        CarbonCategory.gas => const GasInputCard(),
                      },
                      const SizedBox(height: 16),
                      EmissionGaugeCard(
                        emissionKg: state.emissionKg,
                        progress: state.gaugeProgress,
                        category: state.category,
                        offsetKm: state.offsetKm,
                      ),
                      const SizedBox(height: 16),
                      RecommendationCard(
                        isHighEmission: state.isHighEmission,
                        category: state.category,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
