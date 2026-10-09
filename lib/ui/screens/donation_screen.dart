import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/donation/donation_bloc.dart';
import '../../bloc/donation/donation_event.dart';
import '../../bloc/donation/donation_state.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/donation.dart';
import 'campaign_detail_screen.dart';

/// Donasi Hijau: katalog campaign + riwayat donasi sendiri.
///
/// - Tab Campaign: `GET /donation-campaigns` (publik).
/// - Tab Donasi Saya: `GET /user/my-donations` + batal pending.
/// Gaya mengikuti DompetVoucherScreen (header + tab + kartu).
class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  static const _green = Color(0xFF1B8039);
  int _selectedTab = 0;

  final List<String> _tabLabels = ['Campaign', 'Donasi Saya'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DonationBloc>().add(const DonationCampaignsLoaded());
      context.read<DonationBloc>().add(const MyDonationsLoaded());
    });
  }

  /// Format rupiah: 15000 -> "Rp 15.000".
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
        backgroundColor: const Color(0xFFF5F9F6),
        body: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _selectedTab == 0 ? _buildCampaigns() : _buildMine(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFFEAF5EB)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF2D3436),
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Kembali',
                      style: TextStyle(
                        color: Color(0xFF2D3436),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Text(
                  'Donasi Hijau',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFFEAF5EB),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: List.generate(_tabLabels.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? _green : Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: selected ? _green : const Color(0xFFD6E2D9),
                  ),
                ),
                child: Text(
                  _tabLabels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF4A5A50),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCampaigns() {
    return BlocBuilder<DonationBloc, DonationState>(
      builder: (context, state) {
        if (state.status == DonationStatus.loading && state.campaigns.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == DonationStatus.error && state.campaigns.isEmpty) {
          return _buildRetry(
            state.errorMessage ?? 'Gagal memuat campaign.',
            () => context.read<DonationBloc>().add(
              const DonationCampaignsLoaded(),
            ),
          );
        }
        if (state.campaigns.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada campaign terbuka saat ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => context.read<DonationBloc>().add(
            const DonationCampaignsLoaded(force: true),
          ),
          color: _green,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: state.campaigns.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final campaign = state.campaigns[index];
              return _CampaignCard(
                campaign: campaign,
                formatRupiah: _formatRupiah,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CampaignDetailScreen(slug: campaign.slug),
                    ),
                  ).then((_) {
                    // Kembali dari detail (habis donasi/bayar): paksa refresh
                    // agar angka terkumpul terbaru, bukan snapshot lama.
                    if (context.mounted) {
                      context.read<DonationBloc>().add(
                        const DonationCampaignsLoaded(force: true),
                      );
                    }
                  });
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMine() {
    return BlocBuilder<DonationBloc, DonationState>(
      builder: (context, state) {
        if (state.inventoryStatus == DonationStatus.loading &&
            state.inventory == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.inventoryStatus == DonationStatus.error &&
            state.inventory == null) {
          return _buildRetry(
            state.inventoryError ?? 'Gagal memuat riwayat.',
            () => context.read<DonationBloc>().add(
              const MyDonationsLoaded(force: true),
            ),
          );
        }
        final inventory = state.inventory;
        if (inventory == null || inventory.donations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada donasi. Yuk mulai dari campaign terbuka!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => context.read<DonationBloc>().add(
            const MyDonationsLoaded(force: true),
          ),
          color: _green,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _TierCard(
                lifetimeTotal: inventory.lifetimeTotal,
                tier: inventory.tier,
                formatRupiah: _formatRupiah,
              ),
              const SizedBox(height: 10),
              for (final donation in inventory.donations) ...[
                _MyDonationCard(
                  donation: donation,
                  formatRupiah: _formatRupiah,
                  cancelling:
                      state.cancelStatus == DonationCancelStatus.cancelling &&
                      state.cancellingId == donation.id,
                  onCancel: donation.isPending
                      ? () => _confirmCancel(context, donation)
                      : null,
                  onPay: donation.isPending && donation.invoiceUrl.isNotEmpty
                      ? () => _openInvoice(context, donation.invoiceUrl)
                      : null,
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Buka halaman bayar Xendit di browser eksternal.
  /// Setelah bayar, user kembali manual lalu pull-to-refresh
  /// (status lunas via webhook backend, bukan callback aplikasi).
  Future<void> _openInvoice(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link pembayaran tidak valid.')),
      );
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka pembayaran.')),
      );
    }
  }

  Future<void> _confirmCancel(BuildContext context, MyDonation donation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan donasi?'),
        content: Text(
          'Donasi ${_formatRupiah(donation.amount)} ke '
          '"${donation.campaignTitle}" akan dibatalkan dan '
          'invoice kedaluwarsa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Ya, batalkan',
              style: TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<DonationBloc>().add(DonationCancelSubmitted(donation.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Membatalkan donasi...')));
    }
  }

  Widget _buildRetry(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
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
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.campaign,
    required this.formatRupiah,
    required this.onTap,
  });

  final DonationCampaign campaign;
  final String Function(double) formatRupiah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = (campaign.progressPercent.clamp(0, 100)) / 100;
    final imageUrl = ApiEndpoints.resolveImageUrl(campaign.imageUrl);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
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
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEAF5EB),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF1B8039),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${formatRupiah(campaign.collectedAmount)} terkumpul',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1B8039),
                          ),
                        ),
                      ),
                      Text(
                        'dari ${formatRupiah(campaign.targetAmount)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${campaign.progressPercent.toStringAsFixed(1)}% • Tersedia ${formatRupiah(campaign.availableAmount)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.lifetimeTotal,
    required this.tier,
    required this.formatRupiah,
  });

  final double lifetimeTotal;
  final String tier;
  final String Function(double) formatRupiah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF132A1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volunteer_activism,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total donasi seumur hidup',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                Text(
                  formatRupiah(lifetimeTotal),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                if (tier.isNotEmpty)
                  Text(
                    tier,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFD54F),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MyDonationCard extends StatelessWidget {
  const _MyDonationCard({
    required this.donation,
    required this.formatRupiah,
    required this.cancelling,
    this.onCancel,
    this.onPay,
  });

  final MyDonation donation;
  final String Function(double) formatRupiah;
  final bool cancelling;
  final VoidCallback? onCancel;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final style = _donationStatusStyle(donation.status);
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donation.campaignTitle.isEmpty
                          ? 'Campaign #${donation.campaignId}'
                          : donation.campaignTitle,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(donation.amount),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1B8039),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  style.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: style.fg,
                  ),
                ),
              ),
            ],
          ),
          if (donation.isPending) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (onPay != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onPay,
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text(
                        'Lanjut Bayar',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1B8039),
                        side: const BorderSide(color: Color(0xFF1B8039)),
                      ),
                    ),
                  ),
                if (onPay != null && onCancel != null) const SizedBox(width: 8),
                if (onCancel != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: cancelling ? null : onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFC62828),
                        side: const BorderSide(color: Color(0xFFC62828)),
                      ),
                      child: cancelling
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Batalkan',
                              style: TextStyle(fontSize: 12),
                            ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  _DonationStatusStyle _donationStatusStyle(String status) {
    switch (status) {
      case 'paid':
        return const _DonationStatusStyle(
          label: 'Lunas',
          bg: Color(0xFFE8F5E9),
          fg: Color(0xFF1B8039),
        );
      case 'pending':
        return const _DonationStatusStyle(
          label: 'Menunggu Bayar',
          bg: Color(0xFFFFF3E0),
          fg: Color(0xFFE65100),
        );
      case 'expired':
        return const _DonationStatusStyle(
          label: 'Kedaluwarsa',
          bg: Color(0xFFEEEEEE),
          fg: Color(0xFF616161),
        );
      default:
        return _DonationStatusStyle(
          label: status.isEmpty ? '-' : status,
          bg: const Color(0xFFFDECEA),
          fg: const Color(0xFFC62828),
        );
    }
  }
}

class _DonationStatusStyle {
  const _DonationStatusStyle({
    required this.label,
    required this.bg,
    required this.fg,
  });

  final String label;
  final Color bg;
  final Color fg;
}
