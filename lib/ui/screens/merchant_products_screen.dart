import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/merchant_product/merchant_product_bloc.dart';
import '../../bloc/merchant_product/merchant_product_event.dart';
import '../../bloc/merchant_product/merchant_product_state.dart';
import '../../core/network/api_endpoints.dart';

/// Katalog produk toko mitra: input produk + harga fix.
///
/// Harga menentukan poin otomatis server (`ceil(rupiah/40)`).
/// Admin memakai produk ini saat funding voucher (snapshot).
class MerchantProductsScreen extends StatefulWidget {
  const MerchantProductsScreen({super.key});

  @override
  State<MerchantProductsScreen> createState() => _MerchantProductsScreenState();
}

class _MerchantProductsScreenState extends State<MerchantProductsScreen> {
  static const _green = Color(0xFF1B8039);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MerchantProductBloc>().add(const MerchantProductsLoaded());
    });
  }

  Future<void> _pickPhoto(ValueSetter<XFile?> onPicked) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file != null) onPicked(file);
  }

  void _openForm({
    int? id,
    String? title,
    String? desc,
    int? rupiah,
    String? imageUrl,
  }) {
    final titleC = TextEditingController(text: title ?? '');
    final descC = TextEditingController(text: desc ?? '');
    final rupiahC = TextEditingController(
      text: rupiah != null ? rupiah.toString() : '',
    );
    XFile? photo;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  id == null ? 'Tambah Produk' : 'Ubah Produk',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                _photoPicker(
                  photo: photo,
                  imageUrl: imageUrl,
                  onPick: () => _pickPhoto((f) => setSheet(() => photo = f)),
                  onClear: photo == null
                      ? null
                      : () => setSheet(() => photo = null),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(
                    labelText: 'Nama produk',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descC,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: rupiahC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga (Rp, min 1000)',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                    helperText: 'Poin otomatis: ceil(harga / 40)',
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _green),
                  onPressed: () {
                    final t = titleC.text.trim();
                    final d = descC.text.trim();
                    final r =
                        int.tryParse(
                          rupiahC.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ??
                        0;
                    if (t.isEmpty || d.isEmpty || r < 1000) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Lengkapi nama, deskripsi, harga >= 1000.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (id == null) {
                      context.read<MerchantProductBloc>().add(
                        MerchantProductCreateSubmitted({
                          'title': t,
                          'description': d,
                          'category': 'kuliner',
                          'rupiah_value': r,
                        }, photo: photo),
                      );
                    } else {
                      context.read<MerchantProductBloc>().add(
                        MerchantProductUpdateSubmitted(
                          id: id,
                          fields: {
                            'title': t,
                            'description': d,
                            'rupiah_value': r,
                          },
                          photo: photo,
                        ),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Text(
                    id == null ? 'Simpan' : 'Perbarui',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pratinjau + tombol pilih foto produk. Foto ini otomatis jadi foto
  /// voucher saat produk didanai admin (snapshot, bukan live-follow).
  Widget _photoPicker({
    required XFile? photo,
    required String? imageUrl,
    required VoidCallback onPick,
    required VoidCallback? onClear,
  }) {
    final resolved = ApiEndpoints.resolveImageUrl(imageUrl);
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: photo != null
              ? FutureBuilder(
                  future: photo.readAsBytes(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return Image.memory(snap.data!, fit: BoxFit.cover);
                  },
                )
              : resolved.isEmpty
              ? const Icon(Icons.image_outlined, color: Colors.grey)
              : Image.network(
                  resolved,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.image_outlined, color: Colors.grey),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Foto produk (opsional)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              const Text(
                'Otomatis jadi foto voucher saat didanai.',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.upload_outlined, size: 16),
                    label: Text(photo == null ? 'Pilih' : 'Ganti'),
                  ),
                  if (onClear != null) ...[
                    const SizedBox(width: 8),
                    TextButton(onPressed: onClear, child: const Text('Batal')),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MerchantProductBloc, MerchantProductState>(
      listenWhen: (p, c) =>
          (!p.isUnauthorized && c.isUnauthorized) ||
          (p.submitStatus != c.submitStatus &&
              (c.submitStatus == MerchantProductSubmitStatus.success ||
                  c.submitStatus == MerchantProductSubmitStatus.failure)),
      listener: (context, state) {
        if (state.isUnauthorized) {
          context.read<AuthBloc>().add(const LoggedOut());
          return;
        }
        if (state.submitStatus == MerchantProductSubmitStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Produk tersimpan.')));
          context.read<MerchantProductBloc>().add(const MerchantProductReset());
        } else if (state.submitStatus == MerchantProductSubmitStatus.failure &&
            state.submitErrorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.submitErrorMessage!),
                backgroundColor: const Color(0xFFB71C1C),
              ),
            );
          context.read<MerchantProductBloc>().add(const MerchantProductReset());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Produk Toko')),
        floatingActionButton: FloatingActionButton(
          backgroundColor: _green,
          onPressed: () => _openForm(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: BlocBuilder<MerchantProductBloc, MerchantProductState>(
          builder: (context, state) {
            if (state.status == MerchantProductStatus.loading &&
                state.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == MerchantProductStatus.error &&
                state.products.isEmpty) {
              return Center(child: Text(state.errorMessage ?? 'Gagal memuat.'));
            }
            if (state.products.isEmpty) {
              return const Center(
                child: Text('Belum ada produk. Tambah dulu.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.products.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = state.products[i];
                final thumb = ApiEndpoints.resolveImageUrl(p.imageUrl);
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: thumb.isEmpty
                          ? const Icon(
                              Icons.storefront_outlined,
                              color: Colors.grey,
                            )
                          : Image.network(
                              thumb,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.storefront_outlined,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    title: Text(p.title),
                    subtitle: Text(
                      'Rp ${p.rupiahValue.round()} • ${p.pointsPreview} poin'
                      '${p.isActive ? '' : ' • nonaktif'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') {
                          _openForm(
                            id: p.id,
                            title: p.title,
                            desc: p.description,
                            rupiah: p.rupiahValue.round(),
                            imageUrl: p.imageUrl,
                          );
                        } else if (v == 'delete') {
                          context.read<MerchantProductBloc>().add(
                            MerchantProductDeleted(p.id),
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Ubah')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
