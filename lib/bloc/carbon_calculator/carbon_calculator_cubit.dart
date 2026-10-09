import 'package:flutter_bloc/flutter_bloc.dart';
import 'carbon_calculator_state.dart';

export 'carbon_calculator_state.dart';

class CarbonCalculatorCubit extends Cubit<CarbonCalculatorState> {
  CarbonCalculatorCubit() : super(const CarbonCalculatorState());

  void updateJarak(double value) => emit(state.copyWith(jarakKm: value));

  void updateBbm(double value) => emit(state.copyWith(bbmLiter: value));

  void updateFuelType(FuelType value) => emit(state.copyWith(fuelType: value));

  void updateVehicleType(VehicleType value) {
    // Jaga konsistensi: bila BBM saat ini tak cocok untuk tipe baru,
    // reset ke BBM pertama yang valid agar faktor emisi tetap benar.
    final allowed = value.allowedFuels;
    final fuel = allowed.contains(state.fuelType)
        ? state.fuelType
        : allowed.first;
    emit(state.copyWith(vehicleType: value, fuelType: fuel));
  }

  void updateListrikKwh(double value) =>
      emit(state.copyWith(listrikKwh: value));

  void updateGasTabung3kg(int value) =>
      emit(state.copyWith(gasTabung3kg: value.clamp(0, 8)));

  void updateGasTabung12kg(int value) =>
      emit(state.copyWith(gasTabung12kg: value.clamp(0, 4)));

  void switchCategory(CarbonCategory value) =>
      emit(state.copyWith(category: value));
}
