import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/donation/donation_bloc.dart';
import '../../bloc/donation/donation_event.dart';
import '../../bloc/donation/donation_state.dart';
import '../../core/network/api_endpoints.dart';

/// Detail campaign donasi: progress, deskripsi, leaderboard donatur,
/// riwayat donasi, dan tombol Donasi Sekarang.
///
/// Alur bayar: sheet nominal → `POST /api/donations` → buka invoice Xendit
/// di browser → user kembali manual → pull-to-refresh (status lunas masuk
/// via webhook backend).
class CampaignDetailScreen extends StatefulWidget {
  const CampaignDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  static const _green = Color(0xFF1B8039);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DonationBloc>().add(DonationDetailLoaded(widget.slug));
      }
    });
  }

  String _formatRupiah(double value) {
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
    return BlocListener<DonationBloc, DonationState>(
      listenWhen: (prev, curr) => !prev.isUnauthorized && curr.isUnauthorized,
      listener: (context, state) {
        context.read<AuthBloc>().add(const LoggedOut());
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FA),
        body: BlocBuilder<DonationBloc, DonationState>(
          builder: (context, state) {
            if (state.detailStatus == DonationStatus.loading &&
                state.detail == null) {
              return const SafeArea(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.detailStatus == DonationStatus.error &&
                state.detail == null) {
              return SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.detailError ?? 'Gagal memuat detail.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => context.read<DonationBloc>().add(
                            DonationDetailLoaded(widget.slug),
                          ),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final detail = state.detail;
            if (detail == null) return const SizedBox.shrink();
            return _buildContent(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DonationState state) {
    final detail = state.detail!;
    final imageUrl = ApiEndpoints.resolveImageUrl(detail.imageUrl);
    final progress = (detail.progressPercent.clamp(0, 100)) / 100;
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => context.read<DonationBloc>().add(
                DonationDetailLoaded(widget.slug),
              ),
              color: _green,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        if (imageUrl.isNotEmpty)
                          Image.network(
                            imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              height: 200,
                              color: const Color(0xFFEAF5EB),
                              child: const Icon(
                                Icons.volunteer_activism,
                                size: 48,
                                color: Color(0xFF1B8039),
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 200,
                            width: double.infinity,
                            color: const Color(0xFFEAF5EB),
                            child: const Icon(
                              Icons.volunteer_activism,
                              size: 48,
                              color: Color(0xFF1B8039),
                            ),
                          ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detail.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFEAF5EB),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF1B8039),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_formatRupiah(detail.collectedAmount)} terkumpul dari ${_formatRupiah(detail.targetAmount)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1B8039),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${detail.progressPercent.toStringAsFixed(1)}% • ${detail.donorCount} donatur',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (detail.description.isNotEmpty) ...[
                            const Text(
                              'Tentang campaign',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              detail.description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (detail.topDonors.isNotEmpty) ...[
                            const Text(
                              'Donatur Teratas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final donor in detail.topDonors)
                              _DonorRow(
                                name: donor.payerName,
                                right: _formatRupiah(donor.total),
                                sub: donor.tier.isEmpty ? null : donor.tier,
                              ),
                            const SizedBox(height: 16),
                          ],
                          if (detail.recentDonations.isNotEmpty) ...[
                            const Text(
                              'Donasi Terbaru',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final donation in detail.recentDonations)
                              _DonorRow(
                                name: donation.payerName,
                                right: _formatRupiah(donation.amount),
                                sub: null,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (detail.isOpen)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDonateSheet(context),
                    icon: const Icon(Icons.volunteer_activism, size: 18),
                    label: const Text(
                      'Donasi Sekarang',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: const Color(0xFFFFF3E0),
              child: const Text(
                'Campaign sudah ditutup — terima kasih atas dukungannya.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
              ),
            ),
        ],
      ),
    );
  }

  void _showDonateSheet(BuildContext context) {
    final detail = context.read<DonationBloc>().state.detail;
    if (detail == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<DonationBloc>(),
        child: _DonateSheet(
          campaignId: detail.id,
          campaignTitle: detail.title,
          slug: detail.slug,
        ),
      ),
    );
  }
}

class _DonorRow extends StatelessWidget {
  const _DonorRow({required this.name, required this.right, this.sub});

  final String name;
  final String right;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFEAF5EB),
            child: Icon(Icons.person, size: 18, color: Color(0xFF1B8039)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null && sub!.isNotEmpty)
                  Text(
                    sub!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB7791F),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B8039),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet nominal donasi → invoice Xendit.
class _DonateSheet extends StatefulWidget {
  const _DonateSheet({
    required this.campaignId,
    required this.campaignTitle,
    required this.slug,
  });

  final int campaignId;
  final String campaignTitle;
  final String slug;

  @override
  State<_DonateSheet> createState() => _DonateSheetState();
}

class _DonateSheetState extends State<_DonateSheet> {
  static const _green = Color(0xFF1B8039);
  static const _presets = [10000, 25000, 50000, 100000, 250000];

  int? _selectedAmount = 50000;
  final _customController = TextEditingController();
  final _nameController = TextEditingController();
  bool _invoiceOpened = false;

  @override
  void dispose() {
    _customController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  int? get _effectiveAmount {
    final custom = _customController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (custom.isNotEmpty) {
      final parsed = int.tryParse(custom);
      if (parsed != null && parsed > 0) return parsed;
    }
    return _selectedAmount;
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString().split('').reversed.join()}';
  }

  void _submit() {
    final amount = _effectiveAmount;
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih atau isi nominal donasi.')),
      );
      return;
    }
    if (amount < 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal donasi minimal Rp 10.000.')),
      );
      return;
    }
    context.read<DonationBloc>().add(
      DonationCreateSubmitted(
        campaignId: widget.campaignId,
        amount: amount,
        payerName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
      ),
    );
  }

  Future<void> _openInvoice(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link pembayaran tidak valid.')),
      );
      return;
    }
    setState(() => _invoiceOpened = true);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      setState(() => _invoiceOpened = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka pembayaran.')),
      );
    }
    // Status lunas masuk via webhook; refresh saat user kembali.
    if (mounted) {
      context.read<DonationBloc>().add(DonationDetailLoaded(widget.slug));
      context.read<DonationBloc>().add(const MyDonationsLoaded(force: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DonationBloc, DonationState>(
      listenWhen: (prev, curr) => prev.createStatus != curr.createStatus,
      listener: (context, state) {
        if (state.createStatus == DonationCreateStatus.failure &&
            state.createErrorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.createErrorMessage!),
                backgroundColor: const Color(0xFFB71C1C),
              ),
            );
        }
      },
      child: Container(
        margin: EdgeInsets.only(
          top: 80,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: BlocBuilder<DonationBloc, DonationState>(
            builder: (context, state) {
              if (state.createStatus == DonationCreateStatus.success &&
                  state.lastCreate != null) {
                return _buildInvoiceReady(context, state);
              }
              return _buildForm(context, state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, DonationState state) {
    final creating = state.createStatus == DonationCreateStatus.creating;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Donasi ke "${widget.campaignTitle}"',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Pilih nominal',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presets.map((amount) {
            final selected =
                _selectedAmount == amount && _customController.text.isEmpty;
            return GestureDetector(
              onTap: creating
                  ? null
                  : () => setState(() {
                      _selectedAmount = amount;
                      _customController.clear();
                    }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? _green : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: selected ? _green : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  _formatRupiah(amount),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _customController,
          enabled: !creating,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Atau isi nominal lain (min Rp 10.000)',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            prefixText: 'Rp ',
            filled: true,
            fillColor: const Color(0xFFF4FAF5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _nameController,
          enabled: !creating,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Nama donatur (opsional, tampil di leaderboard)',
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            filled: true,
            fillColor: const Color(0xFFF4FAF5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: creating ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              elevation: 0,
            ),
            child: creating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Donasi ${_formatRupiah(_effectiveAmount ?? 0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Pembayaran aman via Xendit (VA, e-wallet, QRIS, dll.)',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceReady(BuildContext context, DonationState state) {
    final result = state.lastCreate!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFF1B8039),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.receipt_long, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 16),
        const Text(
          'Invoice pembayaran dibuat!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Selesaikan pembayaran sebelum kedaluwarsa agar donasi tercatat.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _invoiceOpened
                ? null
                : () => _openInvoice(result.invoiceUrl),
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(
              _invoiceOpened ? 'Invoice sudah dibuka' : 'Bayar Sekarang',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              context.read<DonationBloc>().add(const DonationCreateReset());
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            child: const Text('Tutup'),
          ),
        ),
      ],
    );
  }
}
