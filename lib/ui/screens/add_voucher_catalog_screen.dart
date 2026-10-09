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
import '../../core/network/api_endpoints.dart';
import '../../models/donation.dart';

class AddVoucherCatalogScreen extends StatefulWidget {
  const AddVoucherCatalogScreen({super.key});

  @override
  State<AddVoucherCatalogScreen> createState() =>
      _AddVoucherCatalogScreenState();
}

class _AddVoucherCatalogScreenState extends State<AddVoucherCatalogScreen> {
  static const _categories = [
    'kuliner',
    'sembako',
    'fashion',
    'jasa',
    'donasi',
    'transportasi',
  ];

  final _formKey = GlobalKey<FormState>();
  int? _selectedCampaignId;
  int? _selectedMitraId;
  String _selectedCategory = 'kuliner';
  final _namaController = TextEditingController(
    text: 'Voucher Potongan Rp 20.000',
  );
  final _syaratController = TextEditingController();
  final _diskonController = TextEditingController(text: '20000');
  final _pointsController = TextEditingController(text: '500');
  final _stokController = TextEditingController(text: '10');
  final _expiryController = TextEditingController(text: '31 Desember 2026');
  DateTime _selectedDate = DateTime(2026, 12, 31);
  final _imageUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AdminCampaignBloc>().add(const AdminCampaignsLoaded());
      context.read<AdminMerchantBloc>().add(
        const AdminMerchantsLoaded(status: 'verified'),
      );
    });
    // Ringkasan kebutuhan live mengikuti ketikan stok/nominal/URL gambar.
    _stokController.addListener(_refreshSummary);
    _diskonController.addListener(_refreshSummary);
    _imageUrlController.addListener(_refreshSummary);
  }

  void _refreshSummary() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _namaController.dispose();
    _syaratController.dispose();
    _diskonController.dispose();
    _pointsController.dispose();
    _stokController.dispose();
    _expiryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    const months = [
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2028, 12, 31),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B8039)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _expiryController.text = _formatDate(picked);
      });
    }
  }

  void _handleSimpan() {
    if (_selectedCampaignId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih campaign pendanaan dulu')),
      );
      return;
    }
    if (_selectedMitraId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mitra UMKM terlebih dahulu')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final rupiah =
        int.tryParse(
          _diskonController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final points =
        int.tryParse(
          _pointsController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final stock =
        int.tryParse(
          _stokController.text.trim().replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    if (rupiah < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nilai rupiah minimal Rp 1.000.')),
      );
      return;
    }
    if (stock < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stok minimal 1.')));
      return;
    }

    // Cek dini: kebutuhan vs sisa dana campaign (server tetap validasi).
    final campaignState = context.read<AdminCampaignBloc>().state;
    final campaign = campaignState.campaigns
        .where((c) => c.id == _selectedCampaignId)
        .cast<DonationCampaign?>();
    final selected = campaign.isEmpty ? null : campaign.first;
    final needed = stock * rupiah;
    if (selected != null && needed > selected.availableAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Dana campaign kurang (butuh ${_formatRupiah(needed)}, '
            'tersedia ${_formatRupiah(selected.availableAmount)}).',
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
    final imageUrl = _imageUrlController.text.trim();
    context.read<AdminCampaignBloc>().add(
      AdminVoucherCreateSubmitted({
        'campaign_id': _selectedCampaignId,
        'mitra_profile_id': _selectedMitraId,
        'title': _namaController.text.trim(),
        'description': _syaratController.text.trim().isEmpty
            ? _namaController.text.trim()
            : _syaratController.text.trim(),
        'category': _selectedCategory,
        if (imageUrl.isNotEmpty) 'image_url': imageUrl,
        'points_cost': points,
        'rupiah_value': rupiah,
        'stock': stock,
        'expired_at': expiry,
      }),
    );
  }

  String _formatRupiah(num value) {
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
                  '${_formatRupiah(result.allocatedAmount.round())}.',
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
                _buildHeader(),
                const SizedBox(height: 16),
                _buildCampaignPicker(),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _fieldLabel(Icons.storefront, 'Pilih Mitra UMKM'),
                        const SizedBox(height: 8),
                        _buildMitraDropdown(),
                        const SizedBox(height: 16),
                        _fieldLabel(Icons.category_outlined, 'Kategori'),
                        const SizedBox(height: 8),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 16),
                        _fieldLabel(
                          Icons.local_offer_outlined,
                          'Nama Voucher / Diskon',
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _namaController,
                          hint: 'Voucher Potongan Rp 20.000',
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Nama voucher wajib diisi';
                            }
                            if (v.trim().length < 5) {
                              return 'Minimal 5 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel(
                          Icons.description_outlined,
                          'Syarat & Ketentuan Berlaku',
                        ),
                        const SizedBox(height: 8),
                        _buildTextArea(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    Icons.sell_outlined,
                                    'Nilai Diskon (Rp)',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildNumberField(
                                    controller: _diskonController,
                                    hint: '20000',
                                    prefixText: 'Rp ',
                                    icon: Icons.sell_outlined,
                                    validator: (v) {
                                      final n = int.tryParse(v ?? '');
                                      if (n == null || n <= 0) {
                                        return 'Wajib angka >0';
                                      }
                                      if (n > 1000000) {
                                        return 'Max 1jt';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: _fieldLabel(
                                          Icons.eco,
                                          'Harga Penukaran',
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(Eco)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _pointsController.clear(),
                                        child: Icon(
                                          Icons.close,
                                          size: 14,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildEcoField(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    Icons.card_giftcard,
                                    'Kuota / Stok Voucher',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildNumberField(
                                    controller: _stokController,
                                    hint: '100',
                                    icon: Icons.inventory_2_outlined,
                                    validator: (v) {
                                      final n = int.tryParse(v ?? '');
                                      if (n == null || n < 1) return 'Min 1';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(
                                    Icons.calendar_today_outlined,
                                    'Masa Berlaku Hingga',
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDateField(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel(
                          Icons.image_outlined,
                          'Foto Brosur (URL, opsional)',
                        ),
                        const SizedBox(height: 8),
                        _buildImageUrlField(),
                        const SizedBox(height: 16),
                        _buildNeedSummary(),
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
                                icon: submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle, size: 18),
                                label: const Text(
                                  'Simpan Voucher',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B8039),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
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
                        Center(
                          child: Text(
                            'Voucher akan langsung muncul di Green Marketplace warga',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Picker campaign pendanaan (sisa dana ditampilkan agar admin tahu).
  Widget _buildCampaignPicker() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(Icons.volunteer_activism, 'Campaign Pendanaan (wajib)'),
          const SizedBox(height: 8),
          BlocBuilder<AdminCampaignBloc, AdminCampaignState>(
            builder: (context, state) {
              if (state.status == AdminCampaignStatus.loading &&
                  state.campaigns.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }
              if (state.campaigns.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    'Belum ada campaign. Buat dulu di Kelola Campaign.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                );
              }
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedCampaignId,
                    isExpanded: true,
                    hint: Text(
                      'Pilih campaign',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    items: state.campaigns
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(
                              '${c.title} — tersedia ${_formatRupiah(c.availableAmount.round())}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCampaignId = v),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 18, color: Colors.black87),
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
                'Tambah Katalog Voucher Baru',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Voucher yang ditambahkan akan langsung muncul di Green Marketplace warga',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.black54),
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF1B8039)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMitraDropdown() {
    return BlocBuilder<AdminMerchantBloc, AdminMerchantState>(
      builder: (context, state) {
        // Hanya mitra verified yang boleh menerima voucher (kontrak 403).
        final verified = state.items
            .where((e) => e.verificationStatus == 'verified')
            .toList();
        if (state.status == AdminMerchantStatus.loading && verified.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (verified.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Text(
              'Belum ada mitra terverifikasi.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          );
        }
        final validSelection = verified.any((e) => e.id == _selectedMitraId)
            ? _selectedMitraId
            : null;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: validSelection,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey.shade600,
                size: 20,
              ),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              hint: Text(
                'Pilih mitra',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
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
              onChanged: (v) => setState(() => _selectedMitraId = v),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade600,
            size: 20,
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          items: _categories
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedCategory = v ?? 'kuliner'),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(fontSize: 13, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTextArea() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextFormField(
            controller: _syaratController,
            maxLines: 4,
            minLines: 3,
            maxLength: 500,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
            decoration: InputDecoration(
              hintText:
                  'Berlaku untuk semua menu tanpa minimum belanja. Tidak dapat digabung dengan promo lain.',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(14),
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 8),
            child: Text(
              '${_syaratController.text.length} / 500',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String hint,
    String? prefixText,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: TextInputType.number,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(icon, size: 16, color: Colors.grey.shade600),
          prefixText: prefixText,
          prefixStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEcoField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        controller: _pointsController,
        keyboardType: TextInputType.number,
        validator: (v) {
          final n = int.tryParse(v ?? '');
          if (n == null || n < 50) return 'Min 50';
          if (n > 10000) return 'Max 10k';
          return null;
        },
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: '500',
          hintStyle: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              'assets/images/ecopoints.png',
              width: 18,
              height: 18,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.eco, color: Color(0xFF1B8039), size: 18),
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(Icons.cancel, size: 18, color: Colors.grey.shade400),
            onPressed: () => setState(() => _pointsController.clear()),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: _pickDate,
      child: AbsorbPointer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: _expiryController,
            readOnly: true,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: '31 Desember 2026',
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey.shade600,
              ),
              suffixIcon: Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: Colors.grey.shade600,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Wajib isi';
              }
              if (_selectedDate.isBefore(DateTime.now())) {
                return 'Harus masa depan';
              }
              return null;
            },
          ),
        ),
      ),
    );
  }

  /// Input URL brosur (kontrak backend: image_url string, opsional) +
  /// preview langsung. Tidak ada endpoint upload file voucher.
  Widget _buildImageUrlField() {
    final preview = ApiEndpoints.resolveImageUrl(
      _imageUrlController.text.trim(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _imageUrlController,
            keyboardType: TextInputType.url,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            decoration: InputDecoration(
              hintText: 'https://... (kosongkan bila tidak ada)',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              suffixIcon: _imageUrlController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _imageUrlController.clear(),
                    ),
            ),
          ),
        ),
        if (preview.isNotEmpty) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              preview,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 120,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.broken_image, color: Colors.black38),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Ringkasan live: kebutuhan (stok x rupiah) vs sisa dana campaign.
  /// Mencegah kaget 422 "Insufficient campaign funds" seperti stok 100 x
  /// Rp 20.000 = Rp 2 jt untuk campaign 100rb.
  Widget _buildNeedSummary() {
    final stock =
        int.tryParse(_stokController.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
        0;
    final rupiah =
        int.tryParse(
          _diskonController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    final needed = stock * rupiah;
    return BlocBuilder<AdminCampaignBloc, AdminCampaignState>(
      builder: (context, state) {
        final campaigns = state.campaigns
            .where((c) => c.id == _selectedCampaignId)
            .toList();
        final available = campaigns.isEmpty
            ? null
            : campaigns.first.availableAmount;
        final over = available != null && needed > 0 && needed > available;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: over ? const Color(0xFFFDECEA) : const Color(0xFFEAF5EB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: over
                  ? const Color(0xFFC62828).withValues(alpha: 0.3)
                  : const Color(0xFF1B8039).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                over ? Icons.warning_amber_outlined : Icons.info_outline,
                size: 18,
                color: over ? const Color(0xFFC62828) : const Color(0xFF1B8039),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedCampaignId == null
                      ? 'Pilih campaign untuk melihat sisa dananya.'
                      : 'Butuh ${_formatRupiah(needed)} '
                            '(stok $stock x ${_formatRupiah(rupiah)}) • '
                            'Tersedia ${available == null ? '-' : _formatRupiah(available.round())}'
                            '${over ? ' — KURANG, turunkan stok/nominal!' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: over ? const Color(0xFFC62828) : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
