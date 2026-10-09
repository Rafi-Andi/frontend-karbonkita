import '../../models/mitra_product.dart';

enum MerchantProductStatus { initial, loading, loaded, error }

enum MerchantProductSubmitStatus { idle, submitting, success, failure }

class MerchantProductState {
  const MerchantProductState({
    this.status = MerchantProductStatus.initial,
    this.products = const [],
    this.errorMessage,
    this.submitStatus = MerchantProductSubmitStatus.idle,
    this.submitErrorMessage,
    this.isUnauthorized = false,
  });

  final MerchantProductStatus status;
  final List<MitraProduct> products;
  final String? errorMessage;
  final MerchantProductSubmitStatus submitStatus;
  final String? submitErrorMessage;
  final bool isUnauthorized;

  MerchantProductState copyWith({
    MerchantProductStatus? status,
    List<MitraProduct>? products,
    String? errorMessage,
    MerchantProductSubmitStatus? submitStatus,
    String? submitErrorMessage,
    bool? isUnauthorized,
    bool clearSubmit = false,
  }) {
    return MerchantProductState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: errorMessage,
      submitStatus: submitStatus ?? this.submitStatus,
      submitErrorMessage: clearSubmit
          ? null
          : submitErrorMessage ?? this.submitErrorMessage,
      isUnauthorized: isUnauthorized ?? this.isUnauthorized,
    );
  }
}
