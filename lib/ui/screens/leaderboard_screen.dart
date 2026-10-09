import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/leaderboard/leaderboard_bloc.dart';
import '../../bloc/leaderboard/leaderboard_event.dart';
import '../../bloc/leaderboard/leaderboard_state.dart';
import '../../models/dashboard.dart';
import '../../models/leaderboard.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _selectedTab = 0; // 0 = Minggu Ini, 1 = Bulan Ini
  int _selectedCategory = 0; // 0 = Individu se-RT, 1 = Individu se-RW

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LeaderboardBloc>().add(
          LeaderboardLoaded(scope: _scope, timeframe: _timeframe),
        );
      }
    });
  }

  LeaderboardScope get _scope =>
      _selectedCategory == 0 ? LeaderboardScope.rt : LeaderboardScope.rw;

  LeaderboardTimeframe get _timeframe => _selectedTab == 0
      ? LeaderboardTimeframe.weekly
      : LeaderboardTimeframe.monthly;

  void _onTabChanged(int tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    context.read<LeaderboardBloc>().add(
      LeaderboardLoaded(scope: _scope, timeframe: _timeframe),
    );
  }

  void _onCategoryChanged(int category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
    context.read<LeaderboardBloc>().add(
      LeaderboardLoaded(scope: _scope, timeframe: _timeframe),
    );
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<LeaderboardBloc>();
    final wait = bloc.stream.firstWhere(
      (s) => s.status != LeaderboardStatus.loading || s.board != null,
    );
    bloc.add(const LeaderboardRefreshed());
    await wait;
  }

  /// Format ribuan gaya Indonesia (3450 -> "3.450").
  String _formatXp(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return buffer.toString().split('').reversed.join();
  }

  String _rtLabel(LeaderboardPreview e) => 'RT ${e.rt} / RW ${e.rw}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: BlocListener<LeaderboardBloc, LeaderboardState>(
        // Token mati → logout global, SessionGate pindah ke Login.
        listenWhen: (prev, curr) => !prev.isUnauthorized && curr.isUnauthorized,
        listener: (context, state) {
          context.read<AuthBloc>().add(const LoggedOut());
        },
        child: BlocBuilder<LeaderboardBloc, LeaderboardState>(
          builder: (context, state) {
            final board = state.board;
            final isLoading =
                state.status == LeaderboardStatus.loading && board == null;

            if (state.status == LeaderboardStatus.error && board == null) {
              return SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
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
                                'Tidak ada koneksi dan belum ada data tersimpan.\n${state.errorMessage ?? 'Gagal memuat leaderboard.'}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<LeaderboardBloc>()
                                    .add(const LeaderboardRefreshed()),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF43A047),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final rankings = board?.rankings ?? const [];
            return SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      color: const Color(0xFF43A047),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildHeader(),
                            const SizedBox(height: 8),
                            _buildWilayahBanner(board),
                            const SizedBox(height: 12),
                            _buildTabToggle(),
                            const SizedBox(height: 16),
                            _buildCategoryToggle(),
                            const SizedBox(height: 20),
                            if (isLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 48),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF43A047),
                                  ),
                                ),
                              )
                            else ...[
                              _buildTop3Podium(rankings),
                              const SizedBox(height: 20),
                              _buildRankingList(rankings),
                              const SizedBox(height: 80),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildBottomCurrentUser(board?.currentUser),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Banner wilayah agar jelas leaderboard sudah dikelompokkan
  /// per RT/RW user sendiri, bukan general se-Indonesia.
  Widget _buildWilayahBanner(LeaderboardBoard? board) {
    final wilayah = board?.wilayah;
    // Fallback ke currentUser bila backend lama belum kirim `wilayah`.
    final label = (wilayah != null && !wilayah.isEmpty)
        ? wilayah.label
        : (board?.currentUser != null
              ? _wilayahLabelFromPreview(
                  board!.currentUser!,
                  scopeRt: _scope == LeaderboardScope.rt,
                )
              : null);
    if (label == null || label.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF43A047).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Color(0xFF1B8039), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B8039),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _wilayahLabelFromPreview(
    LeaderboardPreview e, {
    required bool scopeRt,
  }) {
    final rtRw = scopeRt ? 'RT ${e.rt}/RW ${e.rw}' : 'RW ${e.rw}';
    final area = [
      e.kelurahan,
      e.kecamatan,
      e.kota,
    ].where((s) => s.isNotEmpty).join(', ');
    if (area.isEmpty) return rtRw;
    return '$rtRw • $area';
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emoji_events, color: Colors.grey, size: 28),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Papan Peringkat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey, size: 22),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Minggu Ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 0 ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? Colors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Bulan Ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 1 ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onCategoryChanged(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedCategory == 0
                        ? Colors.green
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 18,
                      color: _selectedCategory == 0
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Individu RT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedCategory == 0
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onCategoryChanged(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedCategory == 1
                        ? Colors.green
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group,
                      size: 18,
                      color: _selectedCategory == 1
                          ? Colors.green
                          : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Individu RW',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedCategory == 1
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTop3Podium(List<LeaderboardPreview> rankings) {
    if (rankings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text(
          'Belum ada peringkat periode ini.\nSelesaikan misi untuk masuk papan!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      );
    }
    LeaderboardPreview? byRank(int rank) {
      for (final e in rankings) {
        if (e.rank == rank) return e;
      }
      return null;
    }

    Widget stepFor(
      LeaderboardPreview? e, {
      required double stepHeight,
      required Color stepColor,
      required Color badgeColor,
      required Color avatarBg,
      required Color avatarIcon,
      bool isTop1 = false,
      int flex = 1,
    }) {
      if (e == null) return Expanded(flex: flex, child: const SizedBox());
      return Expanded(
        flex: flex,
        child: _buildPodiumStep(
          rank: e.rank,
          name: e.name,
          rt: _rtLabel(e),
          points: _formatXp(e.xp),
          stepHeight: stepHeight,
          stepColor: stepColor,
          badgeColor: badgeColor,
          avatarBg: avatarBg,
          avatarIcon: avatarIcon,
          isTop1: isTop1,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          stepFor(
            byRank(2),
            stepHeight: 70,
            stepColor: Colors.blueGrey,
            badgeColor: Colors.blueGrey,
            avatarBg: Colors.blueGrey.shade100,
            avatarIcon: Colors.blueGrey,
          ),
          const SizedBox(width: 8),
          // 1st place (center, tallest)
          stepFor(
            byRank(1),
            stepHeight: 100,
            stepColor: Colors.amber,
            badgeColor: Colors.amber,
            avatarBg: const Color(0xFFFFF8E1),
            avatarIcon: Colors.amber,
            isTop1: true,
            flex: 2,
          ),
          const SizedBox(width: 8),
          // 3rd place
          stepFor(
            byRank(3),
            stepHeight: 55,
            stepColor: Colors.orange,
            badgeColor: Colors.orange,
            avatarBg: const Color(0xFFFFF3E0),
            avatarIcon: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumStep({
    required int rank,
    required String name,
    required String rt,
    required String points,
    required double stepHeight,
    required Color stepColor,
    required Color badgeColor,
    required Color avatarBg,
    required Color avatarIcon,
    bool isTop1 = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rank badge
        if (isTop1)
          const Icon(Icons.workspace_premium, color: Colors.amber, size: 30)
        else
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        const SizedBox(height: 4),
        // Avatar
        CircleAvatar(
          radius: isTop1 ? 26 : 20,
          backgroundColor: avatarBg,
          child: Icon(Icons.person, size: isTop1 ? 28 : 22, color: avatarIcon),
        ),
        const SizedBox(height: 4),
        // Name
        Text(
          name,
          style: TextStyle(
            fontSize: isTop1 ? 13 : 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // RT
        Text(
          rt,
          style: TextStyle(fontSize: isTop1 ? 10 : 9, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        // Points
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/ecopoints.png',
              width: isTop1 ? 16 : 14,
              height: isTop1 ? 16 : 14,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.eco, color: Colors.green, size: isTop1 ? 16 : 14),
            ),
            const SizedBox(width: 3),
            Text(
              points,
              style: TextStyle(
                fontSize: isTop1 ? 16 : 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B8039),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Podium step
        Container(
          width: double.infinity,
          height: stepHeight,
          decoration: BoxDecoration(
            color: stepColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            boxShadow: [
              BoxShadow(
                color: stepColor.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: isTop1 ? 36 : 28,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankingList(List<LeaderboardPreview> rankings) {
    final rest = rankings.where((e) => e.rank > 3).toList();

    if (rest.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(rest.length, (index) {
          final item = rest[index];
          return _buildRankingItem(
            rank: item.rank,
            name: item.name,
            rt: _rtLabel(item),
            points: _formatXp(item.xp),
            isLast: index == rest.length - 1,
          );
        }),
      ),
    );
  }

  Widget _buildRankingItem({
    required int rank,
    required String name,
    required String rt,
    required String points,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1)),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8F5E9),
            child: const Icon(Icons.person, color: Color(0xFF1B8039), size: 20),
          ),
          const SizedBox(width: 12),
          // Name & RT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  rt,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Points
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/ecopoints.png',
                width: 18,
                height: 18,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.eco, color: Colors.green, size: 18),
              ),
              const SizedBox(width: 4),
              Text(
                points,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B8039),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'XP',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }

  Widget _buildBottomCurrentUser(LeaderboardPreview? currentUser) {
    if (currentUser == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Trophy + rank
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, color: Colors.green, size: 22),
              const SizedBox(width: 4),
              Text(
                '${currentUser.rank}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE8F5E9),
            child: const Icon(Icons.person, color: Color(0xFF1B8039), size: 20),
          ),
          const SizedBox(width: 12),
          // Name & RT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${currentUser.name} (kamu)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _rtLabel(currentUser),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Points
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/ecopoints.png',
                width: 18,
                height: 18,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.eco, color: Colors.green, size: 18),
              ),
              const SizedBox(width: 4),
              Text(
                _formatXp(currentUser.xp),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B8039),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'XP',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}
