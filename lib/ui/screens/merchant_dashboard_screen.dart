import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/merchant/merchant_bloc.dart';
import '../../bloc/merchant/merchant_event.dart';
import '../../bloc/merchant/merchant_state.dart';
import '../../models/merchant_dashboard.dart';
import 'riwayat_pencairan_screen.dart';
import 'scan_voucher_screen.dart';

/// Dashboard merchant terintegrasi API.
///
/// - `GET /api/merchant/dashboard` via [MerchantBloc] (cache-first Hive).
/// - Toggle Buka/Tutup via `PATCH /merchant/status` (optimistic update).
/// - List transaksi dari `recent_disbursements` apa adanya (generik:
///   Klaim #id + nominal + status) karena backend belum join nama warga.
class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Muat sekali; BLoC tampilkan cache Hive instan lalu refresh online.
    Future.microtask(() {
      if (mounted) context.read<MerchantBloc>().add(const MerchantLoaded());
    });
  }

  Future<void> _onRefresh() async {
    context.read<MerchantBloc>().add(const MerchantRefreshed());
    // Tunggu hingga bukan loading agar RefreshIndicator berhenti wajar.
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: BlocConsumer<MerchantBloc, MerchantState>(
          listenWhen: (prev, curr) =>
              prev.toggleError != curr.toggleError && curr.toggleError != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.toggleError!)));
          },
          builder: (context, state) {
            if (state.isUnauthorized) {
              return _buildUnauthorized();
            }
            switch (state.status) {
              case MerchantStatus.initial:
              case MerchantStatus.loading:
                if (state.dashboard != null) {
                  return _buildBody(context, state, refreshing: true);
                }
                return const Center(child: CircularProgressIndicator());
              case MerchantStatus.error:
                return _buildError(
                  context,
                  state.errorMessage ?? 'Gagal memuat dashboard.',
                );
              case MerchantStatus.loaded:
                return _buildBody(context, state);
            }
          },
        ),
      ),
    );
  }

  Widget _buildUnauthorized() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              'Sesi berakhir. Silakan login ulang.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<AuthBloc>().add(const LoggedOut()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B8039),
                foregroundColor: Colors.white,
              ),
              child: const Text('Kembali ke Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
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
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () =>
                  context.read<MerchantBloc>().add(const MerchantRefreshed()),
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

  Widget _buildBody(
    BuildContext context,
    MerchantState state, {
    bool refreshing = false,
  }) {
    final dashboard = state.dashboard!;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFF1B8039),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopHeader(context, dashboard, state.isToggling),
            if (!dashboard.canRedeem) ...[
              const SizedBox(height: 12),
              _buildVerifyWarning(dashboard),
            ],
            if (state.isOffline) ...[
              const SizedBox(height: 12),
              _buildOfflineBanner(state),
            ],
            const SizedBox(height: 16),
            _buildRiwayatCard(context),
            const SizedBox(height: 16),
            _buildDarkTotalCard(dashboard),
            const SizedBox(height: 16),
            _buildScanCta(context, enabled: dashboard.canRedeem),
            const SizedBox(height: 20),
            _buildTransaksiSection(dashboard),
            const SizedBox(height: 20),
            _buildLogoutButton(context),
            if (refreshing) ...[
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text(
          'Keluar',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFC62828),
          side: const BorderSide(color: Color(0xFFC62828)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Sesi dan data offline Anda akan dihapus. Anda perlu login kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Keluar',
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
      // SessionGate otomatis berpindah ke LoginScreen saat state
      // unauthenticated — tidak perlu Navigator manual.
      context.read<AuthBloc>().add(const LoggedOut());
    }
  }

  Widget _buildVerifyWarning(MerchantDashboard dashboard) {
    final text = dashboard.isVerified
        ? 'Toko sedang tutup — redeem voucher dinonaktifkan sampai dibuka kembali.'
        : 'Akun toko ${dashboard.verificationStatus} — redeem voucher aktif setelah admin memverifikasi.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: Color(0xFFF57F17)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner(MerchantState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            'Mode offline — data terakhir ditampilkan',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(
    BuildContext context,
    MerchantDashboard dashboard,
    bool isToggling,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selamat datang kembali,',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      dashboard.storeName.isEmpty
                          ? 'Toko Saya'
                          : dashboard.storeName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: dashboard.isVerified
                          ? const Color(0xFF43A047)
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      dashboard.isVerified
                          ? Icons.check
                          : Icons.hourglass_empty,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: dashboard.isVerified
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1B8039).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      dashboard.isVerified
                          ? Icons.verified
                          : Icons.pending_outlined,
                      color: dashboard.isVerified
                          ? const Color(0xFF1B8039)
                          : const Color(0xFFE65100),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      dashboard.isVerified
                          ? 'Mitra UMKM Terverifikasi'
                          : 'Status: ${dashboard.verificationStatus}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: dashboard.isVerified
                            ? const Color(0xFF1B8039)
                            : const Color(0xFFE65100),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildStatusTokoCard(context, dashboard, isToggling),
      ],
    );
  }

  Widget _buildStatusTokoCard(
    BuildContext context,
    MerchantDashboard dashboard,
    bool isToggling,
  ) {
    return Container(
      width: 122,
      padding: const EdgeInsets.all(12),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Status Toko',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (isToggling)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: dashboard.isOpen,
              onChanged: (v) =>
                  context.read<MerchantBloc>().add(MerchantStatusToggled(v)),
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF43A047),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey.shade300,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dashboard.isOpen
                      ? const Color(0xFF43A047)
                      : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                dashboard.isOpen ? 'Toko Buka' : 'Toko Tutup',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: dashboard.isOpen
                      ? const Color(0xFF1B8039)
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RiwayatPencairanScreen()),
          );
        },
        child: Container(
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
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF1B8039),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Pencairan Dana',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Lihat semua riwayat pencairan dana ke rekening usaha Anda',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black38, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDarkTotalCard(MerchantDashboard dashboard) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF132A1E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Pencairan Dana Real-Time (via Xendit)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.white70,
                      size: 10,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'xendit',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _formatRp(dashboard.balance),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Total dana berhasil dicairkan ke rekening usaha Anda',
            style: TextStyle(fontSize: 11, color: Colors.white54),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _buildGlassStat(
                  icon: Icons.receipt_long,
                  label: 'Voucher Dicairkan',
                  value: '${dashboard.stats.totalRedeemed} Voucher',
                  sub: '${dashboard.stats.activeVouchers} voucher aktif',
                  subIcon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGlassStat(
                  icon: Icons.account_balance,
                  label: 'Total Dicairkan',
                  value: _formatRp(dashboard.stats.totalDisbursed),
                  sub: '${dashboard.stats.totalVouchers} katalog voucher',
                  isBank: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassStat({
    required IconData icon,
    required String label,
    required String value,
    String? sub,
    IconData? subIcon,
    bool isBank = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (subIcon != null && !isBank)
                const Icon(
                  Icons.trending_up,
                  color: Color(0xFF66BB6A),
                  size: 10,
                ),
              if (subIcon != null && !isBank) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  sub ?? '',
                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScanCta(BuildContext context, {required bool enabled}) {
    return Material(
      color: enabled ? const Color(0xFF1B8039) : Colors.grey.shade400,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanVoucherScreen()),
                );
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_alt_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan Voucher Warga',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled
                          ? 'Pindai QR atau input manual token voucher'
                          : 'Aktif setelah toko terverifikasi & buka',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransaksiSection(MerchantDashboard dashboard) {
    final items = dashboard.recent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Transaksi Terbaru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              '${items.length} pencairan',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1B8039),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Belum ada pencairan.\nScan voucher pertama untuk mulai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                )
              : Column(
                  children: List.generate(items.length, (index) {
                    final t = items[index];
                    final isLast = index == items.length - 1;
                    return Column(
                      children: [
                        _buildTransactionRow(t),
                        if (!isLast)
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: Colors.grey.shade100,
                            indent: 16,
                            endIndent: 16,
                          ),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionRow(MerchantDisbursement t) {
    final completed = t.isCompleted;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: completed
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0),
                child: Icon(
                  Icons.receipt_long,
                  color: completed
                      ? const Color(0xFF43A047)
                      : const Color(0xFFF57F17),
                  size: 24,
                ),
              ),
              if (completed)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF43A047),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Klaim #${t.voucherClaimId}',
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
                  t.referenceId.isEmpty ? 'Ref: -' : t.referenceId,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 11,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        t.processedAt.isEmpty ? '-' : t.processedAt,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatRp(t.amount),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B8039),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF1B8039).withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  completed ? 'Berhasil Dicairkan' : t.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: completed
                        ? const Color(0xFF1B8039)
                        : const Color(0xFFE65100),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format rupiah Indonesia: 1450000 -> "Rp 1.450.000".
  String _formatRp(double value) {
    final intPart = value.truncate().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      final rev = intPart.length - i;
      buffer.write(intPart[i]);
      if (rev > 1 && rev % 3 == 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }
}
