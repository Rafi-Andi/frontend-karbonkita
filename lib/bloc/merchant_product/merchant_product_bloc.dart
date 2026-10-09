import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/network/voucher_exception.dart';
import '../../data/repositories/merchant_repository.dart';
import 'merchant_product_event.dart';
import 'merchant_product_state.dart';

/// BLoC CRUD produk mitra: list milik sendiri + create/update/delete.
/// Poin preview dihitung server (points_preview), BLoC hanya meneruskan.
class MerchantProductBloc
    extends Bloc<MerchantProductEvent, MerchantProductState> {
  MerchantProductBloc(this._repository) : super(const MerchantProductState()) {
    on<MerchantProductsLoaded>(_onLoaded);
    on<MerchantProductCreateSubmitted>(_onCreate);
    on<MerchantProductUpdateSubmitted>(_onUpdate);
    on<MerchantProductDeleted>(_onDelete);
    on<MerchantProductReset>(_onReset);
  }

  final MerchantRepository _repository;

  Future<void> _onLoaded(
    MerchantProductsLoaded event,
    Emitter<MerchantProductState> emit,
  ) async {
    emit(state.copyWith(status: MerchantProductStatus.loading));
    try {
      final products = await _repository.getProducts();
      emit(
        state.copyWith(
          status: MerchantProductStatus.loaded,
          products: products,
        ),
      );
    } on VoucherException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        emit(state.copyWith(isUnauthorized: true));
        return;
      }
      emit(
        state.copyWith(
          status: MerchantProductStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: MerchantProductStatus.error,
          errorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onCreate(
    MerchantProductCreateSubmitted event,
    Emitter<MerchantProductState> emit,
  ) async {
    if (state.submitStatus == MerchantProductSubmitStatus.submitting) return;
    emit(
      state.copyWith(
        submitStatus: MerchantProductSubmitStatus.submitting,
        clearSubmit: true,
      ),
    );
    try {
      await _repository.createProduct(event.fields, photo: event.photo);
      emit(state.copyWith(submitStatus: MerchantProductSubmitStatus.success));
      add(const MerchantProductsLoaded());
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            submitStatus: MerchantProductSubmitStatus.idle,
            clearSubmit: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submitStatus: MerchantProductSubmitStatus.failure,
          submitErrorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: MerchantProductSubmitStatus.failure,
          submitErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onUpdate(
    MerchantProductUpdateSubmitted event,
    Emitter<MerchantProductState> emit,
  ) async {
    if (state.submitStatus == MerchantProductSubmitStatus.submitting) return;
    emit(
      state.copyWith(
        submitStatus: MerchantProductSubmitStatus.submitting,
        clearSubmit: true,
      ),
    );
    try {
      await _repository.updateProduct(event.id, event.fields);
      // Foto diganti lewat endpoint khusus (PATCH JSON tidak bawa file).
      // Batch voucher lama tidak ikut berubah (snapshot).
      if (event.photo != null) {
        await _repository.uploadProductPhoto(event.id, event.photo!);
      }
      emit(state.copyWith(submitStatus: MerchantProductSubmitStatus.success));
      add(const MerchantProductsLoaded());
    } on VoucherException catch (e) {
      if (e.statusCode == 401) {
        emit(
          state.copyWith(
            submitStatus: MerchantProductSubmitStatus.idle,
            clearSubmit: true,
            isUnauthorized: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          submitStatus: MerchantProductSubmitStatus.failure,
          submitErrorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitStatus: MerchantProductSubmitStatus.failure,
          submitErrorMessage: 'Terjadi kesalahan: $e',
        ),
      );
    }
  }

  Future<void> _onDelete(
    MerchantProductDeleted event,
    Emitter<MerchantProductState> emit,
  ) async {
    try {
      await _repository.deleteProduct(event.id);
      add(const MerchantProductsLoaded());
    } on VoucherException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Terjadi kesalahan: $e'));
    }
  }

  void _onReset(
    MerchantProductReset event,
    Emitter<MerchantProductState> emit,
  ) {
    emit(state.copyWith(submitStatus: MerchantProductSubmitStatus.idle));
  }
}
