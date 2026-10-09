import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/merchant/merchant_bloc.dart';
import '../../bloc/merchant/merchant_event.dart';
import '../../bloc/merchant/merchant_state.dart';
import '../../models/merchant_dashboard.dart';

/// Riwayat Pencairan Dana — daftar lengkap payout Xendit toko sendiri.
///
/// Mengikuti gaya layar lain (background #F7F9FA, card putih radius 14,
/// header hijau #1B8039) dan memakai [MerchantBloc] yang sama dengan
/// dashboard lewat `GET /api/merchant/disbursements`.
class RiwayatPencairanScreen extends StatefulWidget {
  const RiwayatPencairanScreen({super.key});

  @override
  State<RiwayatPencairanScreen> createState() => _RiwayatPencairanScreenState();
}

class _RiwayatPencairanScreenState extends State<RiwayatPencairanScreen> {
  static const _filters = <String, String>{
    'all': 'Semua',
    'completed': 'Berhasil',
    'pending': 'Diproses',
    'failed': 'Gagal',
  };

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MerchantBloc>().add(const MerchantDisbursementsLoaded());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      final state = context.read<MerchantBloc>().state;
      if (state.historyStatus == DisbursementHistoryStatus.loaded &&
          state.historyPage < state.historyLastPage) {
        context.read<MerchantBloc>().add(
          MerchantDisbursementsLoaded(
            status: state.historyStatusFilter,
            loadMore: true,
          ),
        );
      }
    }
  }

  void _selectFilter(String status) {
    final current = context.read<MerchantBloc>().state.historyStatusFilter;
    if (current == status) return;
    context.read<MerchantBloc>().add(
      MerchantDisbursementsLoaded(status: status),
    );
  }

  Future<void> _refresh() async {
    final status = context.read<MerchantBloc>().state.historyStatusFilter;
    context.read<MerchantBloc>().add(
      MerchantDisbursementsLoaded(status: status),
    );
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            Expanded(
              child: BlocBuilder<MerchantBloc, MerchantState>(
                builder: (context, state) {
                  if (state.historyStatus ==
                          DisbursementHistoryStatus.loading &&
                      state.historyItems.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.historyStatus == DisbursementHistoryStatus.error &&
                      state.historyItems.isEmpty) {
                    return _buildError(state.historyError);
                  }
                  if (state.historyItems.isEmpty) {
                    return _buildEmpty();
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    color: const Color(0xFF1B8039),
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount:
                          state.historyItems.length +
                          (state.historyStatus ==
                                  DisbursementHistoryStatus.loadingMore
                              ? 1
                              : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        if (index >= state.historyItems.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        return _DisbursementCard(
                          item: state.historyItems[index],
                        );
                      },
                    ),
                  );
                },
              ),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              behavior: HitTestBehavior.opaque,
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
                    'Kembali ke Dashboard',
                    style: TextStyle(color: Color(0xFF2D3436), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Riwayat Pencairan Dana',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Semua pencairan ke rekening usaha Anda via Xendit',
              style: TextStyle(fontSize: 12, color: Color(0xFF5A6B60)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return BlocBuilder<MerchantBloc, MerchantState>(
      buildWhen: (prev, curr) =>
          prev.historyStatusFilter != curr.historyStatusFilter,
      builder: (context, state) {
        return Container(
          width: double.infinity,
          color: const Color(0xFFEAF5EB),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.entries.map((entry) {
                final selected = state.historyStatusFilter == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _selectFilter(entry.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF1B8039)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF1B8039)
                              : const Color(0xFFD6E2D9),
                        ),
                      ),
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : const Color(0xFF4A5A50),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada riwayat pencairan untuk filter ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              message ?? 'Gagal memuat riwayat pencairan.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.read<MerchantBloc>().add(
                const MerchantDisbursementsLoaded(),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B8039),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisbursementCard extends StatelessWidget {
  const _DisbursementCard({required this.item});

  final DisbursementHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final style = _StatusStyle.of(item.status);
    final warga = item.wargaName.isEmpty
        ? 'Warga'
        : '${item.wargaName} (RT ${item.wargaRt}/RW ${item.wargaRw})';

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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(style.icon, color: style.fg, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.voucherTitle.isEmpty
                          ? 'Klaim #${item.voucherClaimId}'
                          : item.voucherTitle,
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
                      warga,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatRp(item.amount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B8039),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFEFF2EF)),
          const SizedBox(height: 10),
          _buildMeta(Icons.access_time, _formatDate(item.processedAt)),
          if (item.referenceId.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildMeta(Icons.confirmation_number_outlined, item.referenceId),
          ],
          if (item.bankName.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildMeta(
              Icons.account_balance,
              '${item.bankName} • ${_maskAccount(item.bankAccountNumber)}',
            ),
          ],
          if (item.failureCode.isNotEmpty || item.failureReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.failureReason.isNotEmpty
                    ? item.failureReason
                    : 'Kode kegagalan: ${item.failureCode}',
                style: const TextStyle(fontSize: 11, color: Color(0xFFB71C1C)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static String _maskAccount(String number) {
    final clean = number.replaceAll(RegExp(r'\s+'), '');
    if (clean.length <= 4) return clean;
    return '${'*' * (clean.length - 4)}${clean.substring(clean.length - 4)}';
  }

  static String _formatRp(double value) {
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

  static const _months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  /// Backend kirim "Y-m-dTH:i:s" → "28 Jun 2026, 10:24".
  static String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final normalized = raw.replaceFirst('T', ' ').split('.').first;
      final parts = normalized.split(' ');
      final date = parts[0].split('-');
      final time = parts.length > 1 ? parts[1] : '';
      if (date.length != 3) return raw;
      final day = int.parse(date[2]);
      final month = int.parse(date[1]);
      final year = date[0];
      final hm = time.length >= 5 ? time.substring(0, 5) : '';
      final label = '$day ${_months[month]} $year';
      return hm.isEmpty ? label : '$label, $hm';
    } catch (_) {
      return raw;
    }
  }
}

/// Warna/ikon per status disbursement (completed/pending/failed/dst).
class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;

  static _StatusStyle of(String status) {
    switch (status) {
      case 'completed':
        return const _StatusStyle(
          label: 'Berhasil Dicairkan',
          bg: Color(0xFFE8F5E9),
          fg: Color(0xFF1B8039),
          icon: Icons.check_circle,
        );
      case 'pending':
        return const _StatusStyle(
          label: 'Diproses',
          bg: Color(0xFFFFF3E0),
          fg: Color(0xFFE65100),
          icon: Icons.hourglass_empty,
        );
      case 'failed':
      case 'rejected':
      case 'cancelled':
      case 'expired':
        return const _StatusStyle(
          label: 'Gagal',
          bg: Color(0xFFFDECEA),
          fg: Color(0xFFC62828),
          icon: Icons.error_outline,
        );
      case 'reversed':
        return const _StatusStyle(
          label: 'Dikembalikan',
          bg: Color(0xFFF3E5F5),
          fg: Color(0xFF6A1B9A),
          icon: Icons.undo,
        );
      default:
        return _StatusStyle(
          label: status.isEmpty ? 'Tidak diketahui' : status,
          bg: const Color(0xFFEEEEEE),
          fg: const Color(0xFF616161),
          icon: Icons.receipt_long,
        );
    }
  }
}
