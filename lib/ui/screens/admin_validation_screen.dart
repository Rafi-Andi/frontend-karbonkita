import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../bloc/admin_merchant/admin_merchant_bloc.dart';
import '../../bloc/admin_merchant/admin_merchant_event.dart';
import '../../bloc/admin_merchant/admin_merchant_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/merchant_application.dart';
import '../widgets/fullscreen_image_viewer.dart';
import 'add_voucher_catalog_screen.dart';
import 'campaign_manage_screen.dart';
import 'mission_manage_screen.dart';

/// Validasi Mitra UMKM — antrean pengajuan terintegrasi API.
///
/// - Tab Menunggu/Diverifikasi/Ditolak dari `summary` backend.
/// - Search = filter client-side di halaman aktif (backend belum sediakan
///   `?search=`).
/// - Detail + approve/reject via `AdminMerchantBloc`; reject wajib alasan.
class AdminValidationScreen extends StatefulWidget {
  const AdminValidationScreen({super.key});

  @override
  State<AdminValidationScreen> createState() => _AdminValidationScreenState();
}

class _AdminValidationScreenState extends State<AdminValidationScreen> {
  static const _green = Color(0xFF1B8039);
  static const _tabs = ['pending', 'verified', 'rejected'];
  static const _tabLabels = ['Menunggu', 'Diverifikasi', 'Ditolak'];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminMerchantBloc>().add(
          const AdminMerchantsLoaded(status: 'pending'),
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectTab(int index) {
    context.read<AdminMerchantBloc>().add(
      AdminMerchantsLoaded(status: _tabs[index]),
    );
  }

  void _openDetail(int id) {
    context.read<AdminMerchantBloc>().add(AdminMerchantDetailLoaded(id));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DetailSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminMerchantBloc, AdminMerchantState>(
      listenWhen: (prev, curr) =>
          (!prev.isUnauthorized && curr.isUnauthorized) ||
          (prev.verifyStatus != curr.verifyStatus &&
              (curr.verifyStatus == AdminMerchantVerifyStatus.success ||
                  curr.verifyStatus == AdminMerchantVerifyStatus.failure)),
      listener: (context, state) {
        if (state.isUnauthorized) {
          context.read<AuthBloc>().add(const LoggedOut());
          return;
        }
        if (state.verifyStatus == AdminMerchantVerifyStatus.success &&
            state.lastResult != null) {
          final r = state.lastResult!;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  r.approved
                      ? '${r.storeName} diverifikasi & diaktifkan.'
                      : '${r.storeName} ditolak.',
                ),
              ),
            );
          context.read<AdminMerchantBloc>().add(
            const AdminMerchantVerifyReset(),
          );
        } else if (state.verifyStatus == AdminMerchantVerifyStatus.failure &&
            state.verifyErrorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.verifyErrorMessage!),
                backgroundColor: const Color(0xFFB71C1C),
              ),
            );
          context.read<AdminMerchantBloc>().add(
            const AdminMerchantVerifyReset(),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FA),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppBar(),
                    const SizedBox(height: 14),
                    _buildBreadcrumb(),
                    const SizedBox(height: 10),
                    _buildTitle(),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddVoucherCatalogScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_card, size: 16),
                        label: const Text(
                          'Tambah Katalog Voucher Baru (Superadmin)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CampaignManageScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.volunteer_activism, size: 16),
                        label: const Text(
                          'Kelola Campaign Donasi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _green,
                          side: const BorderSide(color: _green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MissionManageScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.assignment, size: 16),
                        label: const Text(
                          'Kelola Misi Mobilitas & Sampah',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _green,
                          side: const BorderSide(color: _green),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 14),
                    _buildTabs(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              Expanded(child: _buildList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.menu, color: Colors.black87, size: 20),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.eco, color: Color(0xFF3BC83A), size: 28),
        const SizedBox(width: 6),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'KarbonKita',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                height: 1,
              ),
            ),
            Text(
              'Admin Panel',
              style: TextStyle(fontSize: 11, color: Colors.black54, height: 1),
            ),
          ],
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
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
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none,
                color: Colors.black87,
                size: 20,
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: BlocBuilder<AdminMerchantBloc, AdminMerchantState>(
                buildWhen: (p, c) => p.summary.pending != c.summary.pending,
                builder: (context, state) {
                  if (state.summary.pending == 0) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFFFFE0B2),
          child: Text('👨‍💼', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 6),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _confirmLogout(context),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFDECEA),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout, color: Color(0xFFC62828), size: 18),
          ),
        ),
      ],
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
      context.read<AuthBloc>().add(const LoggedOut());
    }
  }

  Widget _buildBreadcrumb() {
    return Row(
      children: [
        Text(
          'Dashboard',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 6),
        Icon(Icons.chevron_right, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        const Text(
          'Validasi Toko',
          style: TextStyle(
            fontSize: 12,
            color: _green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Validasi Mitra UMKM',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Tinjau dan verifikasi pengajuan mitra toko UMKM baru.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13),
        onChanged: (v) => context.read<AdminMerchantBloc>().add(
          AdminMerchantSearchChanged(v),
        ),
        decoration: InputDecoration(
          hintText: 'Cari nama toko atau owner...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
          suffixIcon: BlocBuilder<AdminMerchantBloc, AdminMerchantState>(
            buildWhen: (p, c) => p.searchQuery != c.searchQuery,
            builder: (context, state) {
              if (state.searchQuery.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  _searchController.clear();
                  context.read<AdminMerchantBloc>().add(
                    const AdminMerchantSearchChanged(''),
                  );
                },
              );
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return BlocBuilder<AdminMerchantBloc, AdminMerchantState>(
      buildWhen: (p, c) =>
          p.filter != c.filter ||
          p.summary.pending != c.summary.pending ||
          p.summary.verified != c.summary.verified ||
          p.summary.rejected != c.summary.rejected,
      builder: (context, state) {
        final counts = [
          state.summary.pending,
          state.summary.verified,
          state.summary.rejected,
        ];
        return Row(
          children: List.generate(3, (i) {
            final selected = state.filter == _tabs[i];
            return Expanded(
              child: GestureDetector(
                onTap: () => _selectTab(i),
                child: Container(
                  margin: EdgeInsets.only(
                    left: i == 0 ? 0 : 6,
                    right: i == 2 ? 0 : 0,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? _green : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? _green : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${counts[i]}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _tabLabels[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildList() {
    return BlocBuilder<AdminMerchantBloc, AdminMerchantState>(
      builder: (context, state) {
        if (state.status == AdminMerchantStatus.loading &&
            state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminMerchantStatus.error && state.items.isEmpty) {
          return Center(
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
                    state.errorMessage ?? 'Gagal memuat antrean.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<AdminMerchantBloc>().add(
                      AdminMerchantsLoaded(status: state.filter),
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
          );
        }
        final items = state.filteredItems;
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                state.searchQuery.isNotEmpty
                    ? 'Tidak ada hasil untuk "${state.searchQuery}".'
                    : 'Belum ada pengajuan pada tab ini.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => context.read<AdminMerchantBloc>().add(
            AdminMerchantsLoaded(status: state.filter),
          ),
          color: _green,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ApplicationCard(
                item: item,
                showActions: item.verificationStatus == 'pending',
                onTap: () => _openDetail(item.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.item,
    required this.showActions,
    required this.onTap,
  });

  final MerchantApplicationItem item;
  final bool showActions;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(item.verificationStatus);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront,
                    color: Color(0xFF1B8039),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.storeName.isEmpty
                            ? '(Tanpa nama toko)'
                            : item.storeName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.ownerName} • ${item.ownerPhone}',
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
            if (showActions) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    size: 12,
                    color: Colors.black38,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Ketuk untuk tinjau dokumen & verifikasi',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  _StatusChip _statusStyle(String status) {
    switch (status) {
      case 'verified':
        return const _StatusChip(
          label: 'Terverifikasi',
          bg: Color(0xFFE8F5E9),
          fg: Color(0xFF1B8039),
        );
      case 'rejected':
        return const _StatusChip(
          label: 'Ditolak',
          bg: Color(0xFFFDECEA),
          fg: Color(0xFFC62828),
        );
      default:
        return const _StatusChip(
          label: 'Menunggu',
          bg: Color(0xFFFFF3E0),
          fg: Color(0xFFE65100),
        );
    }
  }
}

class _StatusChip {
  const _StatusChip({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;
}

/// Bottom sheet detail + aksi approve/reject.
class _DetailSheet extends StatefulWidget {
  const _DetailSheet();

  @override
  State<_DetailSheet> createState() => _DetailSheetState();
}

class _DetailSheetState extends State<_DetailSheet> {
  static const _green = Color(0xFF1B8039);
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, int id, bool approve) {
    final reason = _reasonController.text.trim();
    if (!approve && reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan penolakan wajib diisi.')),
      );
      return;
    }
    context.read<AdminMerchantBloc>().add(
      AdminMerchantVerifySubmitted(
        id: id,
        approve: approve,
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminMerchantBloc, AdminMerchantState>(
      listenWhen: (p, c) =>
          p.verifyStatus != c.verifyStatus &&
          c.verifyStatus == AdminMerchantVerifyStatus.success,
      listener: (context, _) => Navigator.pop(context),
      child: Container(
        margin: EdgeInsets.only(
          top: 60,
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: BlocBuilder<AdminMerchantBloc, AdminMerchantState>(
          builder: (context, state) {
            if (state.detailStatus == AdminMerchantDetailStatus.loading ||
                state.detailStatus == AdminMerchantDetailStatus.initial) {
              return const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (state.detailStatus == AdminMerchantDetailStatus.error ||
                state.detail == null) {
              return SizedBox(
                height: 240,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.detailError ?? 'Gagal memuat detail.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              );
            }
            final d = state.detail!;
            final submitting =
                state.verifyStatus == AdminMerchantVerifyStatus.submitting;
            final pending = d.verificationStatus == 'pending';
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
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
                    d.storeName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${d.businessType} • ${d.ownerName} (${d.ownerPhone})',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  if (d.ownerEmail.isNotEmpty)
                    Text(
                      d.ownerEmail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  if (d.ownerDomisili.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      d.ownerDomisili,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _infoRow('Alamat usaha', d.businessAddress),
                  _infoRow('KTP', d.ktpNumber.isEmpty ? '-' : d.ktpNumber),
                  _infoRow('NIB', d.nibNumber.isEmpty ? '-' : d.nibNumber),
                  _infoRow(
                    'Bank',
                    '${d.bankName} • ${d.bankAccountNumber} a.n. ${d.bankAccountHolder}',
                  ),
                  _infoRow('Status bank', _bankStatusLabel(d)),
                  if (d.bankValidationNote.isNotEmpty)
                    _infoRow('Catatan bank', d.bankValidationNote),
                  if (d.verificationNote.isNotEmpty)
                    _infoRow('Catatan verifikasi', d.verificationNote),
                  const SizedBox(height: 12),
                  const Text(
                    'Foto & Dokumen',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  _photoRow('Toko', d.storePhotos),
                  _photoRow('KTP/NIB', [d.ktpPhoto, d.nibPhoto]),
                  if (pending) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _reasonController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText:
                            'Alasan (wajib bila menolak, opsional bila menyetujui)',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF4FAF5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: submitting
                                ? null
                                : () => _submit(context, d.id, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC62828),
                              side: const BorderSide(color: Color(0xFFC62828)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: const Text('Tolak Pengajuan'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: submitting
                                ? null
                                : () => _submit(context, d.id, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                              elevation: 0,
                            ),
                            child: submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Verifikasi & Aktifkan'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      d.verificationStatus == 'verified'
                          ? 'Pengajuan ini sudah disetujui.'
                          : 'Pengajuan ini sudah ditolak.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _bankStatusLabel(MerchantApplicationDetail d) {
    switch (d.bankValidationStatus) {
      case 'format_valid':
        return 'Format valid (cek otomatis lolos)';
      case 'manual_review':
        return 'Perlu review manual';
      case 'verified':
        return 'Valid / Ready';
      default:
        return d.bankValidationStatus.isEmpty ? '-' : d.bankValidationStatus;
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoRow(String label, List<String?> urls) {
    // Normalisasi host (APP_URL backend bisa beda dengan baseUrl aplikasi).
    final available = urls
        .map(ApiEndpoints.resolveImageUrl)
        .where((u) => u.isNotEmpty)
        .toList();
    if (kDebugMode && available.isNotEmpty) {
      debugPrint('[admin-detail] $label -> ${available.join(', ')}');
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          if (available.isEmpty)
            const Text(
              'Tidak ada foto.',
              style: TextStyle(fontSize: 11, color: Colors.black45),
            )
          else
            Row(
              children: [
                for (var i = 0; i < available.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => FullscreenImageViewer.open(
                        context,
                        urls: available,
                        initialIndex: i,
                        title: label,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              available[i],
                              height: 90,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 90,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.black38,
                                ),
                              ),
                            ),
                            const Positioned(
                              right: 6,
                              bottom: 6,
                              child: Icon(
                                Icons.zoom_in,
                                size: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
