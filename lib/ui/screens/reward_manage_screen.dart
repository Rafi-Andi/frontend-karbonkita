import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/admin_reward/admin_reward_bloc.dart';
import '../../bloc/admin_reward/admin_reward_event.dart';
import '../../bloc/admin_reward/admin_reward_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/admin_reward.dart';
import '../widgets/validation_error_sheet.dart';
import 'reward_detail_screen.dart';

/// Kelola reward marketplace (role:admin): daftar semua reward termasuk
/// nonaktif & kedaluwarsa, tenggat, jumlah penukar, aktif/nonaktif, dan
/// jalan ke detail (penukar + ubah tenggat — stok terkunci dana campaign).
class RewardManageScreen extends StatefulWidget {
  const RewardManageScreen({super.key});

  @override
  State<RewardManageScreen> createState() => _RewardManageScreenState();
}

class _RewardManageScreenState extends State<RewardManageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminRewardBloc>().add(const AdminRewardsLoaded());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminRewardBloc, AdminRewardState>(
      listenWhen: (prev, curr) =>
          (!prev.isUnauthorized && curr.isUnauthorized) ||
          (prev.submitStatus != curr.submitStatus &&
              (curr.submitStatus == AdminRewardSubmitStatus.success ||
                  curr.submitStatus == AdminRewardSubmitStatus.failure)),
      listener: (context, state) {
        if (state.isUnauthorized) {
          context.read<AuthBloc>().add(const LoggedOut());
          return;
        }
        if (state.submitStatus == AdminRewardSubmitStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.submitMessage ?? 'Reward tersimpan.'),
              ),
            );
          context.read<AdminRewardBloc>().add(const AdminRewardSubmitReset());
        } else if (state.submitStatus == AdminRewardSubmitStatus.failure) {
          final items = collectValidationErrors(state.submitErrors);
          if (items.isNotEmpty) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => ValidationErrorSheet(
                title: 'Gagal memperbarui reward',
                items: items,
              ),
            );
          } else if (state.submitErrorMessage != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.submitErrorMessage!),
                  backgroundColor: const Color(0xFFB71C1C),
                ),
              );
          }
          context.read<AdminRewardBloc>().add(const AdminRewardSubmitReset());
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FA),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                        ),
                        const Text(
                          'Kelola Reward',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => context.read<AdminRewardBloc>().add(
                            const AdminRewardsLoaded(),
                          ),
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Muat ulang',
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    BlocBuilder<AdminRewardBloc, AdminRewardState>(
                      buildWhen: (prev, curr) => prev.filter != curr.filter,
                      builder: (context, state) {
                        return Wrap(
                          spacing: 8,
                          children: [
                            _FilterChip(
                              label: 'Semua',
                              selected: state.filter == null,
                              onTap: () => context.read<AdminRewardBloc>().add(
                                const AdminRewardsFiltered(null),
                              ),
                            ),
                            _FilterChip(
                              label: 'Aktif',
                              selected: state.filter == 'active',
                              onTap: () => context.read<AdminRewardBloc>().add(
                                const AdminRewardsFiltered('active'),
                              ),
                            ),
                            _FilterChip(
                              label: 'Nonaktif',
                              selected: state.filter == 'inactive',
                              onTap: () => context.read<AdminRewardBloc>().add(
                                const AdminRewardsFiltered('inactive'),
                              ),
                            ),
                            _FilterChip(
                              label: 'Kedaluwarsa',
                              selected: state.filter == 'expired',
                              onTap: () => context.read<AdminRewardBloc>().add(
                                const AdminRewardsFiltered('expired'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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

  Widget _buildList() {
    return BlocBuilder<AdminRewardBloc, AdminRewardState>(
      builder: (context, state) {
        if (state.status == AdminRewardStatus.loading &&
            state.rewards.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminRewardStatus.error && state.rewards.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.errorMessage ?? 'Gagal memuat reward.'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.read<AdminRewardBloc>().add(
                    const AdminRewardsLoaded(),
                  ),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        }
        final items = state.filteredRewards;
        if (items.isEmpty) {
          return const Center(child: Text('Belum ada reward pada filter ini.'));
        }
        return RefreshIndicator(
          onRefresh: () async =>
              context.read<AdminRewardBloc>().add(const AdminRewardsLoaded()),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _RewardCard(
              reward: items[i],
              onDetail: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RewardDetailScreen(reward: items[i]),
                ),
              ),
              onToggle: () => context.read<AdminRewardBloc>().add(
                AdminRewardStatusSubmitted(
                  id: items[i].id,
                  isActive: !items[i].isActive,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFE8F5E9),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.onDetail,
    required this.onToggle,
  });

  final AdminReward reward;
  final VoidCallback onDetail;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reward.mitra.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${reward.pointsCost} poin • ${_rupiah(reward.rupiahValue)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B8039),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 6),
          Text(
            'Stok: ${reward.stock} • ${reward.claimsCount} ditukar • '
            '${reward.usedClaimsCount} dipakai',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            'Tenggat: ${reward.expiredAtLabel}',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDetail,
                  icon: const Icon(Icons.people_alt_outlined, size: 16),
                  label: const Text('Detail'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    reward.isActive
                        ? Icons.power_settings_new
                        : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(reward.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                ),
              ),
            ],
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
          fontSize: 11,
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
      width: 56,
      height: 56,
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
