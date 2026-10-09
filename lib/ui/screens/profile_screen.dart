import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/activity/activity_bloc.dart';
import '../../bloc/activity/activity_event.dart';
import '../../bloc/activity/activity_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../bloc/dashboard/dashboard_event.dart';
import '../../bloc/dashboard/dashboard_state.dart';
import '../../bloc/level/level_bloc.dart';
import '../../bloc/level/level_event.dart';
import '../../bloc/level/level_state.dart';
import '../../models/activity.dart';
import '../../models/dashboard.dart';
import '../../models/level_tier.dart';

const _green = Color(0xFF43A047);
const _bg = Color(0xFFF1F5F1);

/// Halaman Profil sesuai desain: header user, statistik hijau,
/// lencana level (3 tier), aktivitas terbaru, progres level + eco points.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(const DashboardLoaded());
    context.read<LevelBloc>().add(const LevelLoaded());
    context.read<ActivityBloc>().add(const ActivityLoaded());
  }

  Future<void> _refreshAll() async {
    context.read<DashboardBloc>().add(const DashboardRefreshed());
    context.read<LevelBloc>().add(const LevelRefreshed());
    context.read<ActivityBloc>().add(const ActivityRefreshed());
    await context.read<DashboardBloc>().stream.firstWhere(
      (s) => s.status != DashboardStatus.loading,
    );
  }

  void _logoutListener(BuildContext context) {
    context.read<AuthBloc>().add(const LoggedOut());
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

  void _soon(BuildContext context, String fitur) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$fitur segera hadir')));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DashboardBloc, DashboardState>(
          listenWhen: (p, c) => !p.isUnauthorized && c.isUnauthorized,
          listener: (context, _) => _logoutListener(context),
        ),
        BlocListener<LevelBloc, LevelState>(
          listenWhen: (p, c) => !p.isUnauthorized && c.isUnauthorized,
          listener: (context, _) => _logoutListener(context),
        ),
        BlocListener<ActivityBloc, ActivityState>(
          listenWhen: (p, c) => !p.isUnauthorized && c.isUnauthorized,
          listener: (context, _) => _logoutListener(context),
        ),
      ],
      child: Scaffold(
        backgroundColor: _bg,
        body: BlocBuilder<DashboardBloc, DashboardState>(
          builder: (context, dashState) {
            final user = dashState.dashboard?.user;
            final isLoading =
                dashState.status == DashboardStatus.loading && user == null;
            if (isLoading) {
              return const SafeArea(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (dashState.status == DashboardStatus.error && user == null) {
              return SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada koneksi dan belum ada data tersimpan.\n${dashState.errorMessage ?? 'Gagal memuat profil.'}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refreshAll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (user == null) return const SizedBox.shrink();

            return RefreshIndicator(
              onRefresh: _refreshAll,
              child: Stack(
                children: [
                  // Background ilustrasi atas.
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/images/backgroundProfile.png',
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 250,
                        color: const Color(0xFFE8F5E9),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _ProfileHeader(
                          user: user,
                          onSettings: () => _soon(context, 'Pengaturan'),
                        ),
                        const SizedBox(height: 12),
                        _StatsCard(user: user),
                        const SizedBox(height: 12),
                        _LevelBadgeCard(
                          onRetry: () => context.read<LevelBloc>().add(
                            const LevelRefreshed(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ActivitiesCard(
                          onSeeAll: () =>
                              _soon(context, 'Riwayat aktivitas lengkap'),
                          onRetry: () => context.read<ActivityBloc>().add(
                            const ActivityRefreshed(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _LevelProgressCard(user: user),
                        const SizedBox(height: 20),
                        _LogoutButton(onLogout: () => _confirmLogout(context)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Header atas di atas background image: tombol pengaturan,
/// avatar + nama + badge level + lokasi. Transparan agar ilustrasi terlihat.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user, required this.onSettings});

  final DashboardUser user;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final location = _locationText();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: InkWell(
            onTap: onSettings,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.settings, size: 16, color: Colors.black54),
                  SizedBox(width: 4),
                  Text(
                    'Pengaturan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFE0B2),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                size: 42,
                color: Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.isEmpty ? 'Warga' : user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco, size: 14, color: _green),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          user.level.isEmpty ? 'Pejuang Bumi' : user.level,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF2E7D32),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 15, color: _green),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _locationText() {
    final rtRw = [
      if (user.rt.isNotEmpty) 'RT ${user.rt}',
      if (user.rw.isNotEmpty) 'RW ${user.rw}',
    ].join(' / ');
    final parts = [
      if (rtRw.isNotEmpty) rtRw,
      if (user.kelurahan.isNotEmpty) 'Kel. ${user.kelurahan}',
    ];
    return parts.join(', ');
  }
}

/// Kartu 3 statistik: jarak hijau, sampah terpilah, karbon hemat.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.user});

  final DashboardUser user;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Row(
        children: [
          _StatItem(
            icon: Icons.directions_bike,
            title: 'Jarak Hijau',
            value: _fmtNum(user.totalDistanceKm),
            unit: 'KM',
            caption: 'Total Perjalanan hijau',
          ),
          _verticalDivider(),
          _StatItem(
            icon: Icons.delete_outline,
            title: 'Sampah Terpilah',
            value: _fmtNum(user.totalWasteKg),
            unit: 'KG',
            caption: 'Total sampah terpilah',
          ),
          _verticalDivider(),
          _StatItem(
            icon: Icons.cloud_outlined,
            title: 'Karbon Hemat',
            value: _fmtNum(user.totalCarbonSavedKg),
            unit: 'KG CO₂',
            caption: 'Total karbon hemat',
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(height: 64, width: 1, color: Colors.grey.shade200);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.caption,
  });

  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final String caption;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: _green),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87),
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}

/// Kartu lencana: 3 tier horizontal, terkunci = grayscale + gembok.
class _LevelBadgeCard extends StatelessWidget {
  const _LevelBadgeCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, size: 18, color: Colors.amber),
              SizedBox(width: 6),
              Text(
                'Lencana Level',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<LevelBloc, LevelState>(
            builder: (context, state) {
              if (state.status == LevelStatus.loading && state.data == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              if (state.status == LevelStatus.error && state.data == null) {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.errorMessage ?? 'Gagal memuat lencana.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    TextButton(onPressed: onRetry, child: const Text('Ulangi')),
                  ],
                );
              }
              final tiers = state.data?.tiers ?? const <LevelTier>[];
              if (tiers.isEmpty) {
                return const Text(
                  'Belum ada lencana.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < tiers.length; i++) ...[
                      _TierBadge(tier: tiers[i]),
                      if (i < tiers.length - 1) const SizedBox(width: 16),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final LevelTier tier;

  @override
  Widget build(BuildContext context) {
    final unlocked = tier.isUnlocked;
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: unlocked ? const Color(0xFFE8F5E9) : Colors.grey.shade200,
            border: tier.isCurrent ? Border.all(color: _green, width: 2) : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: unlocked ? 1 : 0.5,
                  child: ColorFiltered(
                    colorFilter: unlocked
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.dst,
                          )
                        : const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                    child: Image.asset(
                      tier.asset,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        unlocked ? Icons.shield : Icons.lock_outline,
                        size: 30,
                        color: unlocked ? _green : Colors.grey,
                      ),
                    ),
                  ),
                ),
                if (!unlocked)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 76,
          child: Text(
            _shortLabel(tier.label),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: tier.isCurrent ? FontWeight.bold : FontWeight.w500,
              color: unlocked ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
        if (tier.isCurrent)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _green,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Aktif',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  String _shortLabel(String label) {
    // "Earth Warrior" -> "Warrior", "Earth Newbie" -> "Newbie".
    final parts = label.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : label;
  }
}

/// Kartu aktivitas terbaru dari backend.
class _ActivitiesCard extends StatelessWidget {
  const _ActivitiesCard({required this.onSeeAll, required this.onRetry});

  final VoidCallback onSeeAll;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.history, size: 18, color: Colors.black54),
              const SizedBox(width: 6),
              const Text(
                'Aktivitas Terbaru',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              InkWell(
                onTap: onSeeAll,
                child: const Row(
                  children: [
                    Text(
                      'Lihat Semua',
                      style: TextStyle(
                        fontSize: 12,
                        color: _green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: _green),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) {
              if (state.status == ActivityStatus.loading &&
                  state.items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state.status == ActivityStatus.error && state.items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.errorMessage ?? 'Gagal memuat aktivitas.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Ulangi'),
                      ),
                    ],
                  ),
                );
              }
              if (state.items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Belum ada aktivitas — selesaikan misi pertamamu!',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < state.items.length; i++) ...[
                    if (i > 0) const Divider(height: 16),
                    _ActivityRow(activity: state.items[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onLogout,
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
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final UserActivity activity;

  @override
  Widget build(BuildContext context) {
    final style = _styleForKind(activity.kind);
    final positive = activity.delta >= 0;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: style.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(style.icon, size: 20, color: style.fg),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _timeLabel(activity.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
        Text(
          '${positive ? '+' : ''}${_fmtInt(activity.delta)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: positive ? _green : Colors.redAccent,
          ),
        ),
      ],
    );
  }

  _KindStyle _styleForKind(String kind) {
    switch (kind) {
      case 'waste':
        return const _KindStyle(
          icon: Icons.delete_outline,
          bg: Color(0xFFE8F5E9),
          fg: _green,
        );
      case 'mobility':
        return const _KindStyle(
          icon: Icons.directions_bike,
          bg: Color(0xFFFFF3E0),
          fg: Colors.orange,
        );
      case 'quiz':
        return const _KindStyle(
          icon: Icons.help_outline,
          bg: Color(0xFFE8F5E9),
          fg: _green,
        );
      case 'voucher':
        return const _KindStyle(
          icon: Icons.shopping_bag_outlined,
          bg: Color(0xFFFFF3E0),
          fg: Colors.orange,
        );
      default:
        return const _KindStyle(
          icon: Icons.eco_outlined,
          bg: Color(0xFFE8F5E9),
          fg: _green,
        );
    }
  }
}

class _KindStyle {
  const _KindStyle({required this.icon, required this.bg, required this.fg});

  final IconData icon;
  final Color bg;
  final Color fg;
}

/// Bilah bawah: progres XP menuju level berikut + total eco points.
class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({required this.user});

  final DashboardUser user;

  @override
  Widget build(BuildContext context) {
    final current = _levelNumber(user.level);
    final next = current + 1;
    return _Card(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.recycling, size: 22, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Level $current',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (user.xpPercentage / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(_green),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_fmtInt(user.xp)} / ${_fmtInt(user.xpMax)} XP menuju Level $next',
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 44, color: Colors.grey.shade200),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.eco, size: 16, color: _green),
                  const SizedBox(width: 4),
                  Text(
                    _fmtInt(user.ecoPoints),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _green,
                    ),
                  ),
                ],
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Eco Points',
                    style: TextStyle(fontSize: 10, color: Colors.black45),
                  ),
                  Icon(Icons.chevron_right, size: 14, color: Colors.black38),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _fmtInt(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${negative ? '-' : ''}$buf';
}

String _fmtNum(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value
      .toStringAsFixed(1)
      .replaceAll(RegExp(r'0$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

int _levelNumber(String level) {
  final match = RegExp(r'(\d+)').firstMatch(level);
  return int.tryParse(match?.group(1) ?? '') ?? 1;
}

String _timeLabel(DateTime? time) {
  if (time == null) return '';
  final local = time.toLocal();
  final now = DateTime.now();
  final hm =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  final day = DateTime(local.year, local.month, local.day);
  final today = DateTime(now.year, now.month, now.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'Hari Ini, $hm';
  if (diff == 1) return 'Kemarin, $hm';
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}, $hm';
}
