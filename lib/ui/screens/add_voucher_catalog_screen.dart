import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/admin_campaign/admin_campaign_bloc.dart';
import '../../bloc/admin_campaign/admin_campaign_event.dart';
import '../../bloc/admin_campaign/admin_campaign_state.dart';
import '../../bloc/admin_merchant/admin_merchant_bloc.dart';
import '../../bloc/admin_merchant/admin_merchant_event.dart';
import '../../bloc/admin_merchant/admin_merchant_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../models/donation.dart';
import '../../models/mitra_product.dart';

/// Tambah katalog voucher dari PRODUK mitra (alur baru).
///
/// Admin pilih: campaign pendanaan -> mitra verified -> produk mitra
/// (harga fix dari mitra) -> jumlah/stok -> tanggal kedaluwarsa.
/// Harga snapshot dari produk, poin otomatis server `ceil(rupiah/40)`.
class AddVoucherCatalogScreen extends StatefulWidget {
  const AddVoucherCatalogScreen({super.key});

  @override
  State<AddVoucherCatalogScreen> createState() =>
      _AddVoucherCatalogScreenState();
}

class _AddVoucherCatalogScreenState extends State<AddVoucherCatalogScreen> {
  int? _selectedCampaignId;
  int? _selectedMitraId;
  int? _selectedProductId;
  final _stokController = TextEditingController(text: '10');
  final _expiryController = TextEditingController(text: '31 Desember 2026');
  DateTime _selectedDate = DateTime(2026, 12, 31);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminCampaignBloc>().add(const AdminCampaignsLoaded());
      context.read<AdminMerchantBloc>().add(
        const AdminMerchantsLoaded(status: 'verified'),
      );
      context.read<AdminCampaignBloc>().add(const AdminMitraProductsLoaded());
    });
    _stokController.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _stokController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  MitraProduct? _selectedProduct(List<MitraProduct> products) {
    for (final p in products) {
      if (p.id == _selectedProductId) return p;
    }
    return null;
  }

  DonationCampaign? _selectedCampaign(List<DonationCampaign> campaigns) {
    for (final c in campaigns) {
      if (c.id == _selectedCampaignId) return c;
    }
    return null;
  }

  int _stock() =>
      int.tryParse(
        _stokController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
      ) ??
      0;

  int _pointsFor(double rupiah) => (rupiah / 40).ceil();

  void _handleSimpan() {
    if (_selectedCampaignId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih campaign pendanaan dulu')),
      );
      return;
    }
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk mitra terlebih dahulu')),
      );
      return;
    }
    final stock = _stock();
    if (stock < 1 || stock > 10000) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stok 1–10000.')));
      return;
    }
    final products = context.read<AdminCampaignBloc>().state.products;
    final product = _selectedProduct(products);
    if (product == null || !product.fundable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Produk tidak fundable (nonaktif / mitra belum verified).',
          ),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
      return;
    }
    final campaigns = context.read<AdminCampaignBloc>().state.campaigns;
    final campaign = _selectedCampaign(campaigns);
    final needed = stock * product.rupiahValue.round();
    if (campaign != null && needed > campaign.availableAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dana campaign kurang (butuh ${_rupiah(needed)}, '
            'tersedia ${_rupiah(campaign.availableAmount)}).',
          ),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
      return;
    }

    final expiry =
        '${_selectedDate.year.toString().padLeft(4, '0')}-'
        '${_selectedDate.month.toString().padLeft(2, '0')}-'
        '${_selectedDate.day.toString().padLeft(2, '0')}';
    context.read<AdminCampaignBloc>().add(
      AdminVoucherCreateSubmitted({
        'campaign_id': _selectedCampaignId,
        'mitra_product_id': _selectedProductId,
        'stock': stock,
        'expired_at': expiry,
      }),
    );
  }

  String _rupiah(num value) {
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2028, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _expiryController.text =
            '${picked.day} ${_bulan(picked.month)} ${picked.year}';
      });
    }
  }

  String _bulan(int m) {
    const names = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminCampaignBloc, AdminCampaignState>(
      listenWhen: (prev, curr) =>
          (!prev.isUnauthorized && curr.isUnauthorized) ||
          (prev.submitStatus != curr.submitStatus &&
              (curr.submitStatus == AdminCampaignSubmitStatus.success ||
                  curr.submitStatus == AdminCampaignSubmitStatus.failure)),
      listener: (context, state) {
        if (state.isUnauthorized) {
          context.read<AuthBloc>().add(const LoggedOut());
          return;
        }
        if (state.submitStatus == AdminCampaignSubmitStatus.success &&
            state.lastVoucher != null) {
          final result = state.lastVoucher!;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  'Voucher #${result.voucherId} dibuat, dana terkunci '
                  '${_rupiah(result.allocatedAmount.round())}.',
                ),
              ),
            );
          context.read<AdminCampaignBloc>().add(
            const AdminCampaignSubmitReset(),
          );
          Navigator.pop(context);
        } else if (state.submitStatus == AdminCampaignSubmitStatus.failure &&
            state.submitErrorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.submitErrorMessage!),
                backgroundColor: const Color(0xFFB71C1C),
              ),
            );
          context.read<AdminCampaignBloc>().add(
            const AdminCampaignSubmitReset(),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FA),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 16),
                _campaignPicker(),
                const SizedBox(height: 16),
                _mitraPicker(),
                const SizedBox(height: 16),
                _productPicker(),
                const SizedBox(height: 16),
                _stockAndDate(),
                const SizedBox(height: 16),
                _summary(),
                const SizedBox(height: 24),
                BlocBuilder<AdminCampaignBloc, AdminCampaignState>(
                  builder: (context, state) {
                    final submitting =
                        state.submitStatus ==
                        AdminCampaignSubmitStatus.submitting;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: submitting ? null : _handleSimpan,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Simpan Voucher'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8039),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 0,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Harga & poin mengikuti produk mitra (poin = ceil(harga/40))',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 18),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buat Voucher dari Produk',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              Text(
                'Pilih produk mitra + jumlah, harga & poin otomatis',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _campaignPicker() {
    return _card(
      'Campaign Pendanaan (wajib)',
      BlocBuilder<AdminCampaignBloc, AdminCampaignState>(
        builder: (context, state) {
          if (state.campaigns.isEmpty) {
            return const Text(
              'Belum ada campaign. Buat dulu di Kelola Campaign.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            );
          }
          return DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedCampaignId,
              isExpanded: true,
              hint: const Text('Pilih campaign'),
              items: state.campaigns
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        '${c.title} — tersedia ${_rupiah(c.availableAmount.round())}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedCampaignId = v),
            ),
          );
        },
      ),
    );
  }

  Widget _mitraPicker() {
    return _card(
      'Mitra UMKM (verified)',
      BlocBuilder<AdminMerchantBloc, AdminMerchantState>(
        builder: (context, state) {
          final verified = state.items
              .where((e) => e.verificationStatus == 'verified')
              .toList();
          if (verified.isEmpty) {
            return const Text(
              'Belum ada mitra terverifikasi.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            );
          }
          return DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedMitraId,
              isExpanded: true,
              hint: const Text('Pilih mitra'),
              items: verified
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.id,
                      child: Text(
                        '${e.storeName} (${e.ownerName})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedMitraId = v;
                  _selectedProductId = null;
                });
                context.read<AdminCampaignBloc>().add(
                  AdminMitraProductsLoaded(mitraProfileId: v),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _productPicker() {
    return _card(
      'Produk Mitra (harga fix)',
      BlocBuilder<AdminCampaignBloc, AdminCampaignState>(
        builder: (context, state) {
          var list = state.products;
          if (_selectedMitraId != null) {
            list = list
                .where((p) => p.mitraProfileId == _selectedMitraId)
                .toList();
          }
          final fundable = list.where((p) => p.fundable).toList();
          if (state.productsLoading) {
            return const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          if (fundable.isEmpty) {
            return const Text(
              'Belum ada produk fundable. Minta mitra tambah produk dulu.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            );
          }
          return DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _selectedProductId,
              isExpanded: true,
              hint: const Text('Pilih produk'),
              items: fundable
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(
                        '${p.title} — ${_rupiah(p.rupiahValue)} • ${_pointsFor(p.rupiahValue)} poin',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedProductId = v),
            ),
          );
        },
      ),
    );
  }

  Widget _stockAndDate() {
    return Row(
      children: [
        Expanded(
          child: _card(
            'Jumlah (stok)',
            TextField(
              controller: _stokController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '10',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _card(
            'Berlaku hingga',
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _expiryController.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFF1B8039),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _summary() {
    return BlocBuilder<AdminCampaignBloc, AdminCampaignState>(
      builder: (context, state) {
        final product = _selectedProduct(state.products);
        final campaign = _selectedCampaign(state.campaigns);
        if (product == null) {
          return _card(
            'Ringkasan',
            const Text(
              'Pilih produk untuk melihat harga, poin, dan kebutuhan dana.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          );
        }
        final stock = _stock();
        final rupiah = product.rupiahValue.round();
        final points = _pointsFor(product.rupiahValue);
        final needed = stock * rupiah;
        return _card(
          'Ringkasan',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Harga/produk: ${_rupiah(rupiah)}'),
              Text('Poin/woucher: $points poin (ceil($rupiah/40))'),
              Text('Stok: $stock → kebutuhan ${_rupiah(needed)}'),
              if (campaign != null)
                Text(
                  'Sisa campaign: ${_rupiah(campaign.availableAmount.round())}'
                  '${needed > campaign.availableAmount ? ' (KURANG!)' : ''}',
                  style: TextStyle(
                    color: needed > campaign.availableAmount
                        ? Colors.red.shade700
                        : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _card(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
