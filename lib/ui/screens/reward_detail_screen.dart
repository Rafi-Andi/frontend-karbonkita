import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/admin_reward/admin_reward_bloc.dart';
import '../../bloc/admin_reward/admin_reward_event.dart';
import '../../bloc/admin_reward/admin_reward_state.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/admin_reward.dart';

/// Detail satu reward: info lengkap, aksi ubah stok & tenggat,
/// aktif/nonaktif, dan daftar warga yang sudah menukarkan (paginasi
/// "Muat lebih banyak").
///
/// Feedback sukses/gagal submit ditangani listener RewardManageScreen
/// (layar induk tetap hidup di bawah route ini) — pola sama dengan
/// MissionFormScreen.
class RewardDetailScreen extends StatefulWidget {
  const RewardDetailScreen({super.key, required this.reward});

  /// Snapshot dari daftar; di-refresh dari state BLoC tiap build.
  final AdminReward reward;

  @override
  State<RewardDetailScreen> createState() => _RewardDetailScreenState();
}

class _RewardDetailScreenState extends State<RewardDetailScreen> {
  static const _green = Color(0xFF1B8039);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminRewardBloc>().add(
          AdminRewardClaimsLoaded(widget.reward.id),
        );
      }
    });
  }

  void _reload() {
    context.read<AdminRewardBloc>().add(const AdminRewardsLoaded());
    context.read<AdminRewardBloc>().add(
      AdminRewardClaimsLoaded(widget.reward.id),
    );
  }

  /// Ambil versi terbaru reward: hasil aksi terakhir / daftar terbaru,
  /// fallback snapshot saat layar dibuka.
  AdminReward _fresh(AdminRewardState state) {
    final last = state.lastReward;
    if (last != null && last.id == widget.reward.id) return last;
    for (final reward in state.rewards) {
      if (reward.id == widget.reward.id) return reward;
    }
    return widget.reward;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: BlocBuilder<AdminRewardBloc, AdminRewardState>(
          builder: (context, state) {
            final reward = _fresh(state);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const Text(
                        'Detail Reward',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Muat ulang',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        _infoCard(reward),
                        const SizedBox(height: 10),
                        _actions(reward),
                        const SizedBox(height: 18),
                        _claimsSection(state),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _infoCard(AdminReward reward) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(url: reward.imageUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reward.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reward.mitra.displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    if (reward.mitra.city.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        reward.mitra.city,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _StatusChip(
                label: reward.isActive ? 'Aktif' : 'Nonaktif',
                color: reward.isActive
                    ? const Color(0xFF1B8039)
                    : Colors.black54,
                background: reward.isActive
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFF5F5F5),
              ),
              if (reward.isExpired)
                const _StatusChip(
                  label: 'Kedaluwarsa',
                  color: Color(0xFFB71C1C),
                  background: Color(0xFFFFEBEE),
                ),
              if (!reward.isExpired && reward.isSoldOut)
                const _StatusChip(
                  label: 'Habis',
                  color: Color(0xFFE65100),
                  background: Color(0xFFFFF3E0),
                ),
            ],
          ),
          if (reward.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              reward.description,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ],
          const SizedBox(height: 10),
          _infoRow('Poin', '${reward.pointsCost} poin'),
          _infoRow('Nilai', _rupiah(reward.rupiahValue)),
          _infoRow('Stok tersisa', '${reward.stock}'),
          _infoRow(
            'Ditukar',
            '${reward.claimsCount} • ${reward.usedClaimsCount} sudah dipakai',
          ),
          _infoRow('Tenggat', reward.expiredAtLabel),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(AdminReward reward) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _openEditSheet(reward),
            icon: const Icon(Icons.edit_note, size: 16),
            label: const Text('Ubah Stok & Tenggat'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.read<AdminRewardBloc>().add(
              AdminRewardStatusSubmitted(
                id: reward.id,
                isActive: !reward.isActive,
              ),
            ),
            icon: Icon(
              reward.isActive ? Icons.power_settings_new : Icons.play_arrow,
              size: 16,
            ),
            label: Text(reward.isActive ? 'Nonaktifkan' : 'Aktifkan'),
          ),
        ),
      ],
    );
  }

  Future<void> _openEditSheet(AdminReward reward) async {
    final bloc = context.read<AdminRewardBloc>();
    final stockController = TextEditingController(text: '${reward.stock}');
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var selectedDate = DateTime.tryParse(reward.expiredAt) ?? today;
    if (selectedDate.isBefore(today)) selectedDate = today;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        String? stockError;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                20 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Ubah Stok & Tenggat',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stok tersisa',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0–10000',
                      errorText: stockError,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Berlaku hingga',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: sheetContext,
                        initialDate: selectedDate,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: DateTime(2028, 12, 31),
                      );
                      if (picked != null) {
                        setSheetState(() => selectedDate = picked);
                      }
                    },
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
                              _formatDay(selectedDate),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: _green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final stock = int.tryParse(stockController.text.trim());
                        if (stock == null || stock < 0 || stock > 10000) {
                          setSheetState(
                            () => stockError = 'Stok harus angka 0–10000.',
                          );
                          return;
                        }
                        bloc.add(
                          AdminRewardUpdateSubmitted(
                            id: reward.id,
                            stock: stock,
                            expiredAt: _formatYmd(selectedDate),
                          ),
                        );
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Simpan'),
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
                ],
              ),
            );
          },
        );
      },
    );
    stockController.dispose();
  }

  Widget _claimsSection(AdminRewardState state) {
    final claims = state.claims;
    final loading = state.claimsStatus == AdminRewardClaimsStatus.loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daftar Penukar (${state.claimsTotal})',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (loading && claims.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.claimsStatus == AdminRewardClaimsStatus.error &&
            claims.isEmpty)
          Column(
            children: [
              Text(
                state.claimsError ?? 'Gagal memuat daftar penukar.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => context.read<AdminRewardBloc>().add(
                  AdminRewardClaimsLoaded(widget.reward.id),
                ),
                child: const Text('Coba lagi'),
              ),
            ],
          )
        else if (claims.isEmpty)
          const Text(
            'Belum ada warga yang menukar reward ini.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          )
        else ...[
          for (final claim in claims)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ClaimTile(claim: claim),
            ),
          if (state.claimsStatus == AdminRewardClaimsStatus.error)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                state.claimsError ?? 'Gagal memuat halaman berikutnya.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          if (state.hasMoreClaims)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: loading
                    ? null
                    : () => context.read<AdminRewardBloc>().add(
                        const AdminRewardClaimsNextPage(),
                      ),
                child: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Muat lebih banyak'),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                'Semua penukar sudah ditampilkan.',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
        ],
      ],
    );
  }
}

class _ClaimTile extends StatelessWidget {
  const _ClaimTile({required this.claim});

  final AdminRewardClaim claim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE8F5E9),
                child: Text(
                  claim.user.name.isEmpty
                      ? '?'
                      : claim.user.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B8039),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.user.name.isEmpty ? '-' : claim.user.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${claim.user.phone.isEmpty ? '-' : claim.user.phone}'
                      ' • ${claim.user.regionLabel}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: claim.statusLabel,
                color: switch (claim.status) {
                  'used' => const Color(0xFF1B8039),
                  'expired' => const Color(0xFFB71C1C),
                  _ => const Color(0xFFE65100),
                },
                background: switch (claim.status) {
                  'used' => const Color(0xFFE8F5E9),
                  'expired' => const Color(0xFFFFEBEE),
                  _ => const Color(0xFFFFF3E0),
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Ditukar: ${claim.claimedAtLabel}',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          if (claim.usedAtLabel != null)
            Text(
              'Dipakai: ${claim.usedAtLabel}',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiEndpoints.resolveImageUrl(url);
    return Container(
      width: 64,
      height: 64,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: resolved.isEmpty
          ? const Icon(Icons.card_giftcard, color: Color(0xFF1B8039))
          : Image.network(
              resolved,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const Icon(Icons.card_giftcard, color: Color(0xFF1B8039)),
            ),
    );
  }
}

const _monthsShort = [
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

String _formatDay(DateTime date) =>
    '${date.day} ${_monthsShort[date.month - 1]} ${date.year}';

String _formatYmd(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

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
