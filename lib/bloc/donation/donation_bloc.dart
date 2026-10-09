import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/auth_exception.dart';
import '../../core/network/voucher_exception.dart';
import '../../data/repositories/donation_repository.dart';
import 'donation_event.dart';
import 'donation_state.dart';

/// BLoC donasi sisi warga/donatur.
///
/// Tanpa cache: nominal, status invoice, dan tier harus fresh (uang asli).
/// Setelah pembayaran di browser Xendit, UI memicu refresh manual
/// (kembali dari browser / tarik untuk muat ulang).
class DonationBloc extends Bloc<DonationEvent, DonationState> {
  DonationBloc(this._repository) : super(const DonationState()) {
    on<DonationCampaignsLoaded>(_onCampaignsLoaded);
    on<DonationDetailLoaded>(_onDetailLoaded);
    on<DonationCreateSubmitted>(_onCreateSubmitted);
    on<DonationCreateReset>(_onCreateReset);
    on<MyDonationsLoaded>(_onMyLoaded);
    on<DonationCancelSubmitted>(_onCancelSubmitted);
  }

  final DonationRepository _repository;

  Future<void> _onCampaignsLoaded(
    DonationCampaignsLoaded event,
    Emitter<DonationState> emit,
  ) async {
    // Tanpa force: sekali tampil jangan timpa (hemat request).
    // Dengan force (refresh / kembali dari detail): muat ulang beneran.
    if (!event.force &&
        state.status == DonationStatus.loaded &&
        state.campaigns.isNotEmpty) {
      return;
    }
    emit(
      state.copyWith(
        status: DonationStatus.loading,
        errorMessage: null,
        isUnauthorized: false,
      ),
    );
    try {
      final campaigns = await _repository.getCampaigns();
      emit(state.copyWith(status: DonationStatus.loaded, campaigns: campaigns));
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(status: DonationStatus.error, errorMessage: e.message),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(status: DonationStatus.error, errorMessage: e.message),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DonationStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onDetailLoaded(
    DonationDetailLoaded event,
    Emitter<DonationState> emit,
  ) async {
    emit(
      state.copyWith(
        detailStatus: DonationStatus.loading,
        detailError: null,
        isUnauthorized: false,
      ),
    );
    try {
      final detail = await _repository.getCampaignDetail(event.slug);
      emit(state.copyWith(detailStatus: DonationStatus.loaded, detail: detail));
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          detailStatus: DonationStatus.error,
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
          detailStatus: DonationStatus.error,
          detailError: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          detailStatus: DonationStatus.error,
          detailError: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onCreateSubmitted(
    DonationCreateSubmitted event,
    Emitter<DonationState> emit,
  ) async {
    if (state.createStatus == DonationCreateStatus.creating) return;
    emit(
      state.copyWith(
        createStatus: DonationCreateStatus.creating,
        clearCreate: true,
        isUnauthorized: false,
      ),
    );
    try {
      final result = await _repository.createDonation(
        campaignId: event.campaignId,
        amount: event.amount,
        payerName: event.payerName,
      );
      emit(
        state.copyWith(
          createStatus: DonationCreateStatus.success,
          lastCreate: result,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            createStatus: DonationCreateStatus.idle,
            clearCreate: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          createStatus: DonationCreateStatus.failure,
          createErrorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            createStatus: DonationCreateStatus.idle,
            clearCreate: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          createStatus: DonationCreateStatus.failure,
          createErrorMessage: _friendlyCreateError(e),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          createStatus: DonationCreateStatus.failure,
          createErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  void _onCreateReset(DonationCreateReset event, Emitter<DonationState> emit) {
    emit(
      state.copyWith(
        createStatus: DonationCreateStatus.idle,
        clearCreate: true,
      ),
    );
  }

  Future<void> _onMyLoaded(
    MyDonationsLoaded event,
    Emitter<DonationState> emit,
  ) async {
    if (!event.force && state.inventoryStatus == DonationStatus.loaded) return;
    emit(
      state.copyWith(
        inventoryStatus: DonationStatus.loading,
        inventoryError: null,
        isUnauthorized: false,
      ),
    );
    try {
      final inventory = await _repository.getMyDonations();
      emit(
        state.copyWith(
          inventoryStatus: DonationStatus.loaded,
          inventory: inventory,
        ),
      );
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          inventoryStatus: DonationStatus.error,
          inventoryError: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          inventoryStatus: DonationStatus.error,
          inventoryError: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          inventoryStatus: DonationStatus.error,
          inventoryError: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onCancelSubmitted(
    DonationCancelSubmitted event,
    Emitter<DonationState> emit,
  ) async {
    if (state.cancelStatus == DonationCancelStatus.cancelling) return;
    emit(
      state.copyWith(
        cancelStatus: DonationCancelStatus.cancelling,
        cancellingId: event.id,
        cancelErrorMessage: null,
        isUnauthorized: false,
      ),
    );
    try {
      await _repository.cancelDonation(event.id);
      emit(state.copyWith(cancelStatus: DonationCancelStatus.success));
      // Status berubah → muat ulang riwayat.
      add(const MyDonationsLoaded(force: true));
    } on AuthException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            cancelStatus: DonationCancelStatus.idle,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          cancelStatus: DonationCancelStatus.failure,
          cancelErrorMessage: e.message,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            cancelStatus: DonationCancelStatus.idle,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          cancelStatus: DonationCancelStatus.failure,
          cancelErrorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          cancelStatus: DonationCancelStatus.failure,
          cancelErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  /// Pesan buat-donasi ramah donatur berdasarkan status backend.
  /// 422 campaign tutup/nominal kurang, 429 throttle 10/menit,
  /// 502 Xendit/invoice gagal.
  String _friendlyCreateError(VoucherException e) {
    switch (e.statusCode) {
      case 404:
        return 'Campaign tidak ditemukan.';
      case 409:
        return 'Donasi ini sudah tidak bisa diproses.';
      case 422:
        return e.message.isNotEmpty
            ? e.message
            : 'Campaign tutup atau nominal belum valid (min Rp 10.000).';
      case 429:
        return 'Terlalu sering mencoba. Tunggu sebentar lalu coba lagi.';
      case 502:
        return 'Gagal membuat pembayaran. Coba lagi.';
      default:
        return e.message.isNotEmpty ? e.message : 'Gagal membuat donasi.';
    }
  }
}
