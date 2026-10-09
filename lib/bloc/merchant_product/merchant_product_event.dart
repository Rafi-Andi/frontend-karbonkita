/// Event MerchantProductBloc (CRUD produk toko sendiri).
///
/// [photo] = foto produk (opsional). Bila ada, diunggah multipart dan
/// otomatis jadi foto voucher saat produk didanai admin (snapshot).
library;

import 'package:image_picker/image_picker.dart';

sealed class MerchantProductEvent {
  const MerchantProductEvent();
}

class MerchantProductsLoaded extends MerchantProductEvent {
  const MerchantProductsLoaded();
}

class MerchantProductCreateSubmitted extends MerchantProductEvent {
  const MerchantProductCreateSubmitted(this.fields, {this.photo});

  final Map<String, dynamic> fields;
  final XFile? photo;
}

class MerchantProductUpdateSubmitted extends MerchantProductEvent {
  const MerchantProductUpdateSubmitted({
    required this.id,
    required this.fields,
    this.photo,
  });

  final int id;
  final Map<String, dynamic> fields;
  final XFile? photo;
}

class MerchantProductDeleted extends MerchantProductEvent {
  const MerchantProductDeleted(this.id);

  final int id;
}

class MerchantProductReset extends MerchantProductEvent {
  const MerchantProductReset();
}
