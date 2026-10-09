import 'package:flutter_test/flutter_test.dart';
import 'package:karbon_kita_app/bloc/carbon_calculator/carbon_calculator_cubit.dart';

void main() {
  group('CarbonCalculatorState', () {
    test('default: 8 L Pertalite = 18.48 kg', () {
      const state = CarbonCalculatorState();
      expect(state.jarakKm, 150);
      expect(state.bbmLiter, 8);
      expect(state.emissionKg, closeTo(8 * 2.31, 0.001));
      expect(state.isHighEmission, isFalse);
    });

    test('fallback jarak saat liter 0: (150/40) x 2.31', () {
      const state = CarbonCalculatorState(jarakKm: 150, bbmLiter: 0);
      expect(state.emissionKg, closeTo((150 / 40) * 2.31, 0.001));
    });

    test('solar memakai faktor 2.68', () {
      const state = CarbonCalculatorState(
        bbmLiter: 10,
        fuelType: FuelType.solar,
      );
      expect(state.emissionKg, closeTo(10 * 2.68, 0.001));
    });

    test('dexlite juga memakai faktor diesel 2.68', () {
      const state = CarbonCalculatorState(
        bbmLiter: 10,
        fuelType: FuelType.dexlite,
      );
      expect(state.emissionKg, closeTo(10 * 2.68, 0.001));
    });

    test('fallback mobil bensin: (150/12) x 2.31', () {
      const state = CarbonCalculatorState(
        vehicleType: VehicleType.mobilBensin,
        jarakKm: 150,
        bbmLiter: 0,
      );
      expect(state.emissionKg, closeTo((150 / 12) * 2.31, 0.001));
    });

    test('fallback mobil diesel: (140/14) x 2.68', () {
      const state = CarbonCalculatorState(
        vehicleType: VehicleType.mobilDiesel,
        jarakKm: 140,
        bbmLiter: 0,
        fuelType: FuelType.solar,
      );
      expect(state.emissionKg, closeTo((140 / 14) * 2.68, 0.001));
    });

    test('listrik: 150 kWh x 0.87', () {
      const state = CarbonCalculatorState(
        category: CarbonCategory.listrik,
        listrikKwh: 150,
      );
      expect(state.emissionKg, closeTo(150 * 0.87, 0.001));
      expect(state.gaugeMax, 400);
      expect(state.isHighEmission, isFalse);
    });

    test('listrik tinggi > 200 kg memicu rekomendasi', () {
      const state = CarbonCalculatorState(
        category: CarbonCategory.listrik,
        listrikKwh: 300,
      );
      expect(state.emissionKg, closeTo(300 * 0.87, 0.001));
      expect(state.isHighEmission, isTrue);
    });

    test('gas: 1 tabung 3kg = 3 kg x 2.98', () {
      const state = CarbonCalculatorState(
        category: CarbonCategory.gas,
        gasTabung3kg: 1,
        gasTabung12kg: 0,
      );
      expect(state.gasLpgKg, 3.0);
      expect(state.emissionKg, closeTo(3 * 2.98, 0.001));
      expect(state.gaugeMax, 150);
      expect(state.isHighEmission, isFalse);
    });

    test('gas campuran 2x3kg + 1x12kg = 18 kg', () {
      const state = CarbonCalculatorState(
        category: CarbonCategory.gas,
        gasTabung3kg: 2,
        gasTabung12kg: 1,
      );
      expect(state.gasLpgKg, 18.0);
      expect(state.emissionKg, closeTo(18 * 2.98, 0.001));
    });

    test('offsetKm memakai faktor mobility 0.21 kg/km', () {
      const state = CarbonCalculatorState(
        category: CarbonCategory.listrik,
        listrikKwh: 100,
      );
      expect(state.offsetKm, closeTo((100 * 0.87) / 0.21, 0.001));
    });

    test('emisi > 100 kg memicu rekomendasi tinggi', () {
      const state = CarbonCalculatorState(bbmLiter: 50);
      expect(state.isHighEmission, isTrue);
      expect(state.gaugeProgress, lessThanOrEqualTo(1.0));
    });
  });

  group('CarbonCalculatorCubit', () {
    test('updateJarak/updateBbm/updateFuelType mengubah state', () {
      final cubit = CarbonCalculatorCubit();
      cubit.updateJarak(500);
      expect(cubit.state.jarakKm, 500);
      cubit.updateBbm(20);
      expect(cubit.state.bbmLiter, 20);
      cubit.updateFuelType(FuelType.solar);
      expect(cubit.state.fuelType, FuelType.solar);
      expect(cubit.state.emissionKg, closeTo(20 * 2.68, 0.001));
      cubit.switchCategory(CarbonCategory.listrik);
      expect(cubit.state.category, CarbonCategory.listrik);
      cubit.close();
    });

    test('updateVehicleType ke diesel mereset BBM bensin ke solar', () {
      final cubit = CarbonCalculatorCubit();
      expect(cubit.state.fuelType, FuelType.pertalite);
      cubit.updateVehicleType(VehicleType.mobilDiesel);
      expect(cubit.state.vehicleType, VehicleType.mobilDiesel);
      expect(cubit.state.fuelType, FuelType.solar);
      cubit.close();
    });

    test('updateVehicleType ke mobil bensin mempertahankan BBM bensin', () {
      final cubit = CarbonCalculatorCubit();
      cubit.updateVehicleType(VehicleType.mobilBensin);
      expect(cubit.state.fuelType, FuelType.pertalite);
      cubit.close();
    });

    test('updateListrik dan gas mengubah emisi per kategori', () {
      final cubit = CarbonCalculatorCubit();
      cubit.updateListrikKwh(200);
      cubit.switchCategory(CarbonCategory.listrik);
      expect(cubit.state.emissionKg, closeTo(200 * 0.87, 0.001));
      cubit.updateGasTabung3kg(2);
      cubit.updateGasTabung12kg(1);
      cubit.switchCategory(CarbonCategory.gas);
      expect(cubit.state.gasLpgKg, 18.0);
      expect(cubit.state.emissionKg, closeTo(18 * 2.98, 0.001));
      cubit.close();
    });

    test('clamp tabung gas pada batas 0-8 dan 0-4', () {
      final cubit = CarbonCalculatorCubit();
      cubit.updateGasTabung3kg(99);
      cubit.updateGasTabung12kg(-5);
      expect(cubit.state.gasTabung3kg, 8);
      expect(cubit.state.gasTabung12kg, 0);
      cubit.close();
    });
  });
}
