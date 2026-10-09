import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/admin_merchant_repository.dart';
import 'admin_merchant_event.dart';
import 'admin_merchant_state.dart';

/// BLoC antrean validasi mitra (admin). Tanpa cache: selalu fresh.
///
/// - `AdminMerchantsLoaded`: daftar per tab + summary badge.
/// - `AdminMerchantVerifySubmitted`: approve/reject, sukses → muat ulang
///   tab aktif agar item pindah tab + badge counts sinkron.
class AdminMerchantBloc extends Bloc<AdminMerchantEvent, AdminMerchantState> {
  AdminMerchantBloc(this._repository) : super(const AdminMerchantState()) {
    on<AdminMerchantsLoaded>(_onLoaded);
    on<AdminMerchantSearchChanged>(_onSearchChanged);
    on<AdminMerchantDetailLoaded>(_onDetailLoaded);
    on<AdminMerchantVerifySubmitted>(_onVerifySubmitted);
    on<AdminMerchantVerifyReset>(_onVerifyReset);
  }

  final AdminMerchantRepository _repository;

  Future<void> _onLoaded(
    AdminMerchantsLoaded event,
    Emitter<AdminMerchantState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AdminMerchantStatus.loading,
        filter: event.status,
        searchQuery: '',
        errorMessage: null,
        isUnauthorized: false,
      ),
    );
    try {
      final page = await _repository.getApplications(status: event.status);
      emit(
        state.copyWith(
          status: AdminMerchantStatus.loaded,
          items: page.items,
          summary: page.summary,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          status: AdminMerchantStatus.error,
          errorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          status: AdminMerchantStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AdminMerchantStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  void _onSearchChanged(
    AdminMerchantSearchChanged event,
    Emitter<AdminMerchantState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  Future<void> _onDetailLoaded(
    AdminMerchantDetailLoaded event,
    Emitter<AdminMerchantState> emit,
  ) async {
    emit(
      state.copyWith(
        detailStatus: AdminMerchantDetailStatus.loading,
        clearDetail: true,
        detailError: null,
        isUnauthorized: false,
      ),
    );
    try {
      final detail = await _repository.getDetail(event.id);
      emit(
        state.copyWith(
          detailStatus: AdminMerchantDetailStatus.loaded,
          detail: detail,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          detailStatus: AdminMerchantDetailStatus.error,
          detailError: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          detailStatus: AdminMerchantDetailStatus.error,
          detailError: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          detailStatus: AdminMerchantDetailStatus.error,
          detailError: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onVerifySubmitted(
    AdminMerchantVerifySubmitted event,
    Emitter<AdminMerchantState> emit,
  ) async {
    if (state.verifyStatus == AdminMerchantVerifyStatus.submitting) return;
    emit(
      state.copyWith(
        verifyStatus: AdminMerchantVerifyStatus.submitting,
        clearVerify: true,
        isUnauthorized: false,
      ),
    );
    try {
      final result = await _repository.verify(
        id: event.id,
        approve: event.approve,
        reason: event.reason,
      );
      emit(
        state.copyWith(
          verifyStatus: AdminMerchantVerifyStatus.success,
          lastResult: result,
        ),
      );
      // Item pindah tab → muat ulang tab aktif + badge counts.
      add(AdminMerchantsLoaded(status: state.filter));
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            verifyStatus: AdminMerchantVerifyStatus.idle,
            clearVerify: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          verifyStatus: AdminMerchantVerifyStatus.failure,
          verifyErrorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            verifyStatus: AdminMerchantVerifyStatus.idle,
            clearVerify: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          verifyStatus: AdminMerchantVerifyStatus.failure,
          verifyErrorMessage: _friendlyVerifyError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          verifyStatus: AdminMerchantVerifyStatus.failure,
          verifyErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  void _onVerifyReset(
    AdminMerchantVerifyReset event,
    Emitter<AdminMerchantState> emit,
  ) {
    emit(
      state.copyWith(
        verifyStatus: AdminMerchantVerifyStatus.idle,
        clearVerify: true,
      ),
    );
  }

  /// Pesan verifikasi ramah admin berdasarkan status backend.
  /// 404 toko hilang, 409 sudah direview orang/tim lain, 422 validasi.
  String _friendlyVerifyError(VoucherException e) {
    switch (e.statusCode) {
      case 404:
        return 'Pengajuan tidak ditemukan. Muat ulang antrean.';
      case 409:
        return 'Sudah direview sebelumnya. Muat ulang antrean.';
      case 422:
        return e.message.isNotEmpty
            ? e.message
            : 'Data verifikasi belum valid. Periksa kembali.';
      default:
        return e.message.isNotEmpty ? e.message : 'Gagal memverifikasi.';
    }
  }
}
