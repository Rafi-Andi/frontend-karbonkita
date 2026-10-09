import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/region_repository.dart';
import '../../models/region.dart';
import 'register_region_state.dart';

export 'register_region_state.dart';

/// Cascading dropdown wilayah untuk form register.
///
/// Nasional, tapi default ter-preselect rantai Surabaya
/// (Jawa Timur → Surabaya → Gubeng → Mojo) via pencocokan nama.
/// Ganti parent selalu me-reset anaknya agar tidak ada kombinasi basi
/// seperti `Gubeng + Kelurahan milik Jakarta`.
///
/// Bila API tidak terjangkau, repository memberi fallback rantai Surabaya
/// dan [RegisterRegionState.isOffline] menjadi true agar UI menampilkan
/// notice + tombol muat ulang (bukan diam-diam 1 item seperti sebelumnya).
class RegisterRegionCubit extends Cubit<RegisterRegionState> {
  RegisterRegionCubit(this._repository) : super(const RegisterRegionState());

  final RegionRepository _repository;

  static const _defaultProvince = ['jawa timur'];
  static const _defaultRegency = ['surabaya', 'kota surabaya'];
  static const _defaultDistrict = ['gubeng'];
  static const _defaultVillage = ['mojo'];

  Region? _match(List<Region> list, List<String> candidates) {
    for (final c in candidates) {
      for (final r in list) {
        if (r.name.toLowerCase() == c) return r;
      }
    }
    return null;
  }

  Region? _byCode(List<Region> list, String? code) {
    if (code == null || code.isEmpty) return null;
    for (final r in list) {
      if (r.code == code) return r;
    }
    return null;
  }

  Future<void> loadProvinces() async {
    emit(
      state.copyWith(
        loadingLevel: () => RegionLevel.province,
        error: () => null,
        offlineReason: () => null,
      ),
    );
    try {
      final res = await _repository.getProvinces();
      final pre = _match(res.regions, _defaultProvince);
      emit(
        state.copyWith(
          provinces: res.regions,
          loadingLevel: () => null,
          error: () => null,
          isOffline: res.fallback,
          offlineReason: () => res.reason,
        ),
      );
      if (pre != null) {
        await selectProvince(pre);
      } else if (res.regions.isEmpty) {
        emit(
          state.copyWith(
            error: () => 'Gagal memuat provinsi. Periksa koneksi.',
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          loadingLevel: () => null,
          error: () => 'Gagal memuat provinsi. Periksa koneksi.',
          isOffline: true,
        ),
      );
    }
  }

  /// Muat ulang seluruh rantai dengan mempertahankan pilihan user
  /// (dipakai tombol refresh saat notice offline tampil).
  Future<void> retry() async {
    final keepP = state.province?.code;
    final keepR = state.regency?.code;
    final keepD = state.district?.code;
    final keepV = state.village?.code;
    emit(
      state.copyWith(
        loadingLevel: () => RegionLevel.province,
        error: () => null,
        offlineReason: () => null,
      ),
    );
    try {
      final res = await _repository.getProvinces();
      final p =
          _byCode(res.regions, keepP) ?? _match(res.regions, _defaultProvince);
      emit(
        state.copyWith(
          provinces: res.regions,
          province: () => p,
          regencies: const [],
          districts: const [],
          villages: const [],
          regency: () => null,
          district: () => null,
          village: () => null,
          loadingLevel: () => p == null ? null : RegionLevel.regency,
          isOffline: res.fallback,
          offlineReason: () => res.reason,
        ),
      );
      if (p == null) return;
      await _loadRegencies(p, keepCode: keepR ?? _defaultRegencyCode(keepP));
      if (state.regency == null) return;
      await _loadDistricts(
        state.regency!,
        keepCode: keepD,
        useDefault: keepR == null,
      );
      if (state.district == null) return;
      await _loadVillages(
        state.district!,
        keepCode: keepV,
        useDefault: keepR == null && keepD == null,
      );
    } catch (_) {
      emit(
        state.copyWith(
          loadingLevel: () => null,
          error: () => 'Gagal memuat ulang. Periksa koneksi.',
          isOffline: true,
        ),
      );
    }
  }

  /// Code default rantai Surabaya bila user belum pernah memilih (retry
  /// pertama kali dari fallback). Null bila user sudah memilih sendiri.
  String? _defaultRegencyCode(String? keepProvince) =>
      keepProvince == null ? '35.78' : null;

  Future<void> selectProvince(Region? province) async {
    emit(
      state.copyWith(
        province: () => province,
        regencies: const [],
        districts: const [],
        villages: const [],
        regency: () => null,
        district: () => null,
        village: () => null,
        loadingLevel: () => province == null ? null : RegionLevel.regency,
        error: () => null,
      ),
    );
    if (province == null) return;
    await _loadRegencies(province);
  }

  Future<void> _loadRegencies(Region province, {String? keepCode}) async {
    try {
      final res = await _repository.getRegencies(province.code);
      final pre = keepCode != null
          ? _byCode(res.regions, keepCode)
          : _match(res.regions, _defaultRegency);
      emit(
        state.copyWith(
          regencies: res.regions,
          regency: () => pre,
          loadingLevel: () => null,
          isOffline: res.fallback ? true : state.isOffline,
          offlineReason: () => res.reason ?? state.offlineReason,
        ),
      );
      if (pre != null) await _loadDistricts(pre);
    } catch (_) {
      emit(
        state.copyWith(
          loadingLevel: () => null,
          error: () => 'Gagal memuat kota/kabupaten.',
          isOffline: true,
        ),
      );
    }
  }

  Future<void> selectRegency(Region? regency) async {
    emit(
      state.copyWith(
        regency: () => regency,
        districts: const [],
        villages: const [],
        district: () => null,
        village: () => null,
        loadingLevel: () => regency == null ? null : RegionLevel.district,
        error: () => null,
      ),
    );
    if (regency == null) return;
    await _loadDistricts(regency);
  }

  Future<void> _loadDistricts(
    Region regency, {
    String? keepCode,
    bool useDefault = true,
  }) async {
    try {
      final res = await _repository.getDistricts(regency.code);
      final pre = keepCode != null
          ? _byCode(res.regions, keepCode)
          : (useDefault ? _match(res.regions, _defaultDistrict) : null);
      emit(
        state.copyWith(
          districts: res.regions,
          district: () => pre,
          loadingLevel: () => null,
          isOffline: res.fallback ? true : state.isOffline,
          offlineReason: () => res.reason ?? state.offlineReason,
        ),
      );
      if (pre != null) await _loadVillages(pre);
    } catch (_) {
      emit(
        state.copyWith(
          loadingLevel: () => null,
          error: () => 'Gagal memuat kecamatan.',
          isOffline: true,
        ),
      );
    }
  }

  Future<void> selectDistrict(Region? district) async {
    emit(
      state.copyWith(
        district: () => district,
        villages: const [],
        village: () => null,
        loadingLevel: () => district == null ? null : RegionLevel.village,
        error: () => null,
      ),
    );
    if (district == null) return;
    await _loadVillages(district);
  }

  Future<void> _loadVillages(
    Region district, {
    String? keepCode,
    bool useDefault = true,
  }) async {
    try {
      final res = await _repository.getVillages(district.code);
      final pre = keepCode != null
          ? _byCode(res.regions, keepCode)
          : (useDefault ? _match(res.regions, _defaultVillage) : null);
      emit(
        state.copyWith(
          villages: res.regions,
          village: () => pre,
          loadingLevel: () => null,
          isOffline: res.fallback ? true : state.isOffline,
          offlineReason: () => res.reason ?? state.offlineReason,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loadingLevel: () => null,
          error: () => 'Gagal memuat kelurahan.',
          isOffline: true,
        ),
      );
    }
  }

  void selectVillage(Region? village) {
    emit(state.copyWith(village: () => village));
  }
}
