import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/donation_repository.dart';
import 'admin_campaign_event.dart';
import 'admin_campaign_state.dart';

/// BLoC kelola campaign donasi + voucher pendanaan (role:admin).
///
/// Sukses submit apa pun → muat ulang daftar agar angka available
/// dan status selalu sinkron dengan backend.
class AdminCampaignBloc extends Bloc<AdminCampaignEvent, AdminCampaignState> {
  AdminCampaignBloc(this._repository) : super(const AdminCampaignState()) {
    on<AdminCampaignsLoaded>(_onLoaded);
    on<AdminCampaignCreateSubmitted>(_onCreateSubmitted);
    on<AdminCampaignUpdateSubmitted>(_onUpdateSubmitted);
    on<AdminVoucherCreateSubmitted>(_onVoucherSubmitted);
    on<AdminCampaignSubmitReset>(_onSubmitReset);
    on<AdminMitraProductsLoaded>(_onProductsLoaded);
  }

  final DonationRepository _repository;

  Future<void> _onLoaded(
    AdminCampaignsLoaded event,
    Emitter<AdminCampaignState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminCampaignStatus.loading,
        errorMessage: null,
        isUnauthorized: false,
      ),
    );
    try {
      final campaigns = await _repository.getAdminCampaigns();
      emit(
        state.copyWith(
          status: AdminCampaignStatus.loaded,
          campaigns: campaigns,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          status: AdminCampaignStatus.error,
          errorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          status: AdminCampaignStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminCampaignStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onCreateSubmitted(
    AdminCampaignCreateSubmitted event,
    Emitter<AdminCampaignState> emit,
  ) async {
    await _submit(
      emit,
      () => _repository.createCampaign(event.fields),
      onOk: (data) => state.copyWith(
        submitStatus: AdminCampaignSubmitStatus.success,
        lastCampaign: data,
      ),
    );
  }

  Future<void> _onUpdateSubmitted(
    AdminCampaignUpdateSubmitted event,
    Emitter<AdminCampaignState> emit,
  ) async {
    await _submit(
      emit,
      () => _repository.updateCampaign(event.id, event.fields),
      onOk: (data) => state.copyWith(
        submitStatus: AdminCampaignSubmitStatus.success,
        lastCampaign: data,
      ),
    );
  }

  Future<void> _onVoucherSubmitted(
    AdminVoucherCreateSubmitted event,
    Emitter<AdminCampaignState> emit,
  ) async {
    if (state.submitStatus == AdminCampaignSubmitStatus.submitting) return;
    emit(
      state.copyWith(
        submitStatus: AdminCampaignSubmitStatus.submitting,
        clearSubmit: true,
        isUnauthorized: false,
      ),
    );
    try {
      final result = await _repository.createFundedVoucher(event.fields);
      emit(
        state.copyWith(
          submitStatus: AdminCampaignSubmitStatus.success,
          lastVoucher: result,
        ),
      );
      add(const AdminCampaignsLoaded());
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            submitStatus: AdminCampaignSubmitStatus.idle,
            clearSubmit: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submitStatus: AdminCampaignSubmitStatus.failure,
          submitErrorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            submitStatus: AdminCampaignSubmitStatus.idle,
            clearSubmit: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submitStatus: AdminCampaignSubmitStatus.failure,
          submitErrorMessage: _friendlyVoucherError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: AdminCampaignSubmitStatus.failure,
          submitErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _submit(
    Emitter<AdminCampaignState> emit,
    Future<Map<String, dynamic>> Function() call, {
    required AdminCampaignState Function(Map<String, dynamic>) onOk,
  }) async {
    if (state.submitStatus == AdminCampaignSubmitStatus.submitting) return;
    emit(
      state.copyWith(
        submitStatus: AdminCampaignSubmitStatus.submitting,
        clearSubmit: true,
        isUnauthorized: false,
      ),
    );
    try {
      final data = await call();
      emit(onOk(data));
      add(const AdminCampaignsLoaded());
    } on AuthException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            submitStatus: AdminCampaignSubmitStatus.idle,
            clearSubmit: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submitStatus: AdminCampaignSubmitStatus.failure,
          submitErrorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(
            submitStatus: AdminCampaignSubmitStatus.idle,
            clearSubmit: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submitStatus: AdminCampaignSubmitStatus.failure,
          submitErrorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: AdminCampaignSubmitStatus.failure,
          submitErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  void _onSubmitReset(
    AdminCampaignSubmitReset event,
    Emitter<AdminCampaignState> emit,
  ) {
    emit(
      state.copyWith(
        submitStatus: AdminCampaignSubmitStatus.idle,
        clearSubmit: true,
      ),
    );
  }

  Future<void> _onProductsLoaded(
    AdminMitraProductsLoaded event,
    Emitter<AdminCampaignState> emit,
  ) async {
    emit(state.copyWith(productsLoading: true));
    try {
      final products = await _repository.getAdminMitraProducts(
        mitraProfileId: event.mitraProfileId,
      );
      emit(state.copyWith(products: products, productsLoading: false));
    } on VoucherException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(
          state.copyWith(productsLoading: false, isUnauthorized: true),
        );
        return;
      }
      emit(state.copyWith(productsLoading: false));
    } catch (_) {
      emit(state.copyWith(productsLoading: false));
    }
  }

  /// Pesan buat-voucher ramah admin.
  /// 403 mitra belum verified, 422 dana kurang/validasi, 404 campaign hilang.
  String _friendlyVoucherError(VoucherException e) {
    switch (e.statusCode) {
      case 403:
        return 'Mitra belum terverifikasi atau nonaktif. '
            'Verifikasi mitra dulu.';
      case 404:
        return 'Campaign tidak ditemukan. Muat ulang daftar.';
      case 422:
        return _translateFundsError(e.message);
      default:
        return e.message.isNotEmpty ? e.message : 'Gagal membuat voucher.';
    }
  }

  /// Terjemahkan "Insufficient campaign funds. Needed A, available B."
  /// jadi Indonesia + format Rp (kebutuhan = stok x rupiah).
  /// Pola angka eksplisit agar titik akhir kalimat tidak ikut ter-parse.
  String _translateFundsError(String message) {
    final match = RegExp(
      r'Needed (\d+(?:\.\d+)?), available (\d+(?:\.\d+)?)',
    ).firstMatch(message);
    if (match != null) {
      final needed = double.tryParse(match.group(1)!) ?? 0;
      final available = double.tryParse(match.group(2)!) ?? 0;
      return 'Dana campaign kurang: butuh ${_rupiah(needed)}, '
          'tersedia ${_rupiah(available)}. '
          'Turunkan stok/nominal atau tambah donasi dulu.';
    }
    return message.isNotEmpty
        ? message
        : 'Dana campaign kurang atau data belum valid.';
  }

  String _rupiah(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }
}
