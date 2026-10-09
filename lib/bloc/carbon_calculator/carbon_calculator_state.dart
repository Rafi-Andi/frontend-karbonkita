enum CarbonCategory { listrik, kendaraan, gas }

enum FuelType { pertalite, pertamax, pertamaxTurbo, solar, dexlite }

enum VehicleType { motor, mobilBensin, mobilDiesel }

extension FuelTypeX on FuelType {
  String get label {
    switch (this) {
      case FuelType.pertalite:
        return 'Pertalite (RON 90)';
      case FuelType.pertamax:
        return 'Pertamax (RON 92)';
      case FuelType.pertamaxTurbo:
        return 'Pertamax Turbo (RON 98)';
      case FuelType.solar:
        return 'Solar / Biosolar';
      case FuelType.dexlite:
        return 'Dexlite / Pertamina Dex';
    }
  }

  /// Faktor emisi standar IPCC default (kg CO2e per liter).
  double get emissionFactor {
    switch (this) {
      case FuelType.pertalite:
      case FuelType.pertamax:
      case FuelType.pertamaxTurbo:
        return 2.31;
      case FuelType.solar:
      case FuelType.dexlite:
        return 2.68;
    }
  }

  bool get isDiesel {
    switch (this) {
      case FuelType.solar:
      case FuelType.dexlite:
        return true;
      case FuelType.pertalite:
      case FuelType.pertamax:
      case FuelType.pertamaxTurbo:
        return false;
    }
  }
}

extension VehicleTypeX on VehicleType {
  String get label {
    switch (this) {
      case VehicleType.motor:
        return 'Motor';
      case VehicleType.mobilBensin:
        return 'Mobil Bensin';
      case VehicleType.mobilDiesel:
        return 'Mobil Diesel';
    }
  }

  /// Konsumsi rata-rata (km per liter) untuk fallback saat liter == 0.
  double get consumptionKmPerLiter {
    switch (this) {
      case VehicleType.motor:
        return 40;
      case VehicleType.mobilBensin:
        return 12;
      case VehicleType.mobilDiesel:
        return 14;
    }
  }

  /// Daftar BBM yang masuk akal untuk tipe kendaraan ini.
  List<FuelType> get allowedFuels {
    switch (this) {
      case VehicleType.motor:
      case VehicleType.mobilBensin:
        return const [
          FuelType.pertalite,
          FuelType.pertamax,
          FuelType.pertamaxTurbo,
        ];
      case VehicleType.mobilDiesel:
        return const [FuelType.solar, FuelType.dexlite];
    }
  }
}

class CarbonCalculatorState {
  const CarbonCalculatorState({
    this.category = CarbonCategory.kendaraan,
    this.vehicleType = VehicleType.motor,
    this.jarakKm = 150,
    this.bbmLiter = 8,
    this.fuelType = FuelType.pertalite,
    this.listrikKwh = 150,
    this.gasTabung3kg = 1,
    this.gasTabung12kg = 0,
  });

  final CarbonCategory category;
  final VehicleType vehicleType;
  final double jarakKm;
  final double bbmLiter;
  final FuelType fuelType;
  final double listrikKwh;
  final int gasTabung3kg;
  final int gasTabung12kg;

  /// Faktor emisi grid Jawa-Madura-Bali PLN (kg CO2e per kWh).
  /// Nilai umum RUPTL ~0.87; kalibrasi ke angka resmi KLHK bila tersedia.
  static const double listrikEmissionFactor = 0.87;

  /// Faktor emisi LPG IPCC (kg CO2e per kg LPG).
  static const double lpgEmissionFactor = 2.98;

  /// Estimasi CO2 yang dihemat per km bersepeda/jalan kaki (kg/km),
  /// selaras dengan backend mobility-sync (210 g/km).
  static const double mobilitySavedPerKm = 0.21;

  /// Total kg LPG per bulan dari jumlah tabung.
  double get gasLpgKg => gasTabung3kg * 3.0 + gasTabung12kg * 12.0;

  double get _vehicleEmissionKg {
    final factor = fuelType.emissionFactor;
    if (bbmLiter > 0) return bbmLiter * factor;
    if (jarakKm > 0) {
      return (jarakKm / vehicleType.consumptionKmPerLiter) * factor;
    }
    return 0;
  }

  /// Rumus per kategori (per bulan):
  /// - kendaraan: liter x faktor emisi, fallback (jarak / konsumsi) x faktor.
  /// - listrik: kWh x 0.87.
  /// - gas: kg LPG x 2.98.
  double get emissionKg {
    switch (category) {
      case CarbonCategory.kendaraan:
        return _vehicleEmissionKg;
      case CarbonCategory.listrik:
        return listrikKwh * listrikEmissionFactor;
      case CarbonCategory.gas:
        return gasLpgKg * lpgEmissionFactor;
    }
  }

  /// Skala maksimum gauge (kg CO2e / bulan) per kategori.
  double get gaugeMax {
    switch (category) {
      case CarbonCategory.kendaraan:
        return 200;
      case CarbonCategory.listrik:
        return 400;
      case CarbonCategory.gas:
        return 150;
    }
  }

  double get gaugeProgress =>
      (emissionKg / gaugeMax).clamp(0.0, 1.0).toDouble();

  /// Rekomendasi dinamis sederhana berbasis ambang per kategori.
  bool get isHighEmission {
    switch (category) {
      case CarbonCategory.kendaraan:
        return emissionKg > 100;
      case CarbonCategory.listrik:
        return emissionKg > 200;
      case CarbonCategory.gas:
        return emissionKg > 60;
    }
  }

  /// Estimasi km sepeda/jalan kaki untuk mengimbangi emisi ini.
  double get offsetKm => emissionKg / mobilitySavedPerKm;

  CarbonCalculatorState copyWith({
    CarbonCategory? category,
    VehicleType? vehicleType,
    double? jarakKm,
    double? bbmLiter,
    FuelType? fuelType,
    double? listrikKwh,
    int? gasTabung3kg,
    int? gasTabung12kg,
  }) {
    return CarbonCalculatorState(
      category: category ?? this.category,
      vehicleType: vehicleType ?? this.vehicleType,
      jarakKm: jarakKm ?? this.jarakKm,
      bbmLiter: bbmLiter ?? this.bbmLiter,
      fuelType: fuelType ?? this.fuelType,
      listrikKwh: listrikKwh ?? this.listrikKwh,
      gasTabung3kg: gasTabung3kg ?? this.gasTabung3kg,
      gasTabung12kg: gasTabung12kg ?? this.gasTabung12kg,
    );
  }
}
