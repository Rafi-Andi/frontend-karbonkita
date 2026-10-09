import '../../models/region.dart';

/// Level yang sedang dimuat dari API wilayah (untuk spinner per dropdown).
enum RegionLevel { province, regency, district, village }

class RegisterRegionState {
  const RegisterRegionState({
    this.provinces = const [],
    this.regencies = const [],
    this.districts = const [],
    this.villages = const [],
    this.province,
    this.regency,
    this.district,
    this.village,
    this.loadingLevel,
    this.error,
    this.isOffline = false,
    this.offlineReason,
  });

  final List<Region> provinces;
  final List<Region> regencies;
  final List<Region> districts;
  final List<Region> villages;

  final Region? province;
  final Region? regency;
  final Region? district;
  final Region? village;

  final RegionLevel? loadingLevel;
  final String? error;

  /// True bila level mana pun sedang disajikan dari fallback offline
  /// (dropdown terlihat hanya berisi rantai Surabaya).
  final bool isOffline;

  /// Penyebab singkat fallback (mis. CORS/timeout), tampil di notice.
  final String? offlineReason;

  /// Lengkap bila 4 level terpilih — syarat tombol register aktif.
  bool get isComplete =>
      province != null &&
      regency != null &&
      district != null &&
      village != null;

  RegisterRegionState copyWith({
    List<Region>? provinces,
    List<Region>? regencies,
    List<Region>? districts,
    List<Region>? villages,
    Region? Function()? province,
    Region? Function()? regency,
    Region? Function()? district,
    Region? Function()? village,
    RegionLevel? Function()? loadingLevel,
    String? Function()? error,
    bool? isOffline,
    String? Function()? offlineReason,
  }) {
    return RegisterRegionState(
      provinces: provinces ?? this.provinces,
      regencies: regencies ?? this.regencies,
      districts: districts ?? this.districts,
      villages: villages ?? this.villages,
      province: province != null ? province() : this.province,
      regency: regency != null ? regency() : this.regency,
      district: district != null ? district() : this.district,
      village: village != null ? village() : this.village,
      loadingLevel: loadingLevel != null ? loadingLevel() : this.loadingLevel,
      error: error != null ? error() : this.error,
      isOffline: isOffline ?? this.isOffline,
      offlineReason: offlineReason != null
          ? offlineReason()
          : this.offlineReason,
    );
  }
}
