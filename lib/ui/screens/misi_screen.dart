import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/mission/mission_bloc.dart';
import '../../bloc/mission/mission_event.dart';
import '../../bloc/mission/mission_state.dart';
import '../../models/mission.dart';
import '../widgets/mission/mission_action.dart';
import 'mission_detail_screen.dart';

class MisiScreen extends StatelessWidget {
  const MisiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Trigger initial load when screen is built (kuis hanya lewat FAB)
    context.read<MissionBloc>().add(const MissionsLoaded());

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildCategoryTabs(),
              const SizedBox(height: 20),
              _buildMissionList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Misi Hijau Harian',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E6C46),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Selesaikan misi, kumpulkan\npoin, dan jaga bumi kita!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time, color: Colors.green, size: 24),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Riset dalam',
                        style: TextStyle(fontSize: 10, color: Colors.green),
                      ),
                      Text(
                        '10:45:12',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.ac_unit, color: Colors.blue, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Streak Freeze: ',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  Text(
                    'Aktif',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return BlocBuilder<MissionBloc, MissionState>(
      buildWhen: (prev, curr) => prev.currentFilter != curr.currentFilter,
      builder: (context, state) {
        int selectedIndex = _categoryToIndex(state.currentFilter);
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTabItem(
                0,
                Icons.grid_view_rounded,
                'Semua',
                selectedIndex,
                context,
              ),
              _buildTabItem(
                1,
                Icons.pedal_bike,
                'Mobilitas',
                selectedIndex,
                context,
              ),
              _buildTabItem(
                2,
                Icons.recycling,
                'Sampah',
                selectedIndex,
                context,
              ),
            ],
          ),
        );
      },
    );
  }

  int _categoryToIndex(String? category) {
    switch (category) {
      case null:
        return 0;
      case 'mobility':
        return 1;
      case 'waste':
        return 2;
      default:
        return 0;
    }
  }

  String? _indexToCategory(int index) {
    switch (index) {
      case 0:
        return null;
      case 1:
        return 'mobility';
      case 2:
        return 'waste';
      default:
        return null;
    }
  }

  Widget _buildTabItem(
    int index,
    IconData icon,
    String label,
    int selectedIndex,
    BuildContext context,
  ) {
    bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        context.read<MissionBloc>().add(
          MissionsFiltered(_indexToCategory(index)),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.green : Colors.grey, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.green : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isSelected ? Colors.green : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionList() {
    return BlocBuilder<MissionBloc, MissionState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.filteredMissions != curr.filteredMissions ||
          prev.errorMessage != curr.errorMessage,
      builder: (context, state) {
        if (state.status == MissionStatus.loading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF1B8039)),
            ),
          );
        }

        if (state.status == MissionStatus.error) {
          return _buildErrorState(
            'Tidak ada koneksi dan belum ada data tersimpan.\n${state.errorMessage ?? 'Terjadi kesalahan'}',
            context,
          );
        }

        if (state.filteredMissions.isEmpty) {
          return _buildEmptyState(state.currentFilter);
        }

        return Column(
          children: state.filteredMissions.map((mission) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: _buildMissionCard(mission, context),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildErrorState(String message, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFFC62828)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              context.read<MissionBloc>().add(const MissionsLoaded());
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B8039),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String? filter) {
    String message;
    IconData icon;

    switch (filter) {
      case 'mobility':
        message = 'Belum ada misi mobilitas aktif';
        icon = Icons.pedal_bike;
        break;
      case 'waste':
        message = 'Belum ada misi sampah aktif';
        icon = Icons.recycling;
        break;
      default:
        message = 'Belum ada misi aktif';
        icon = Icons.assignment;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.grey[400], size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _openDetail(Mission mission, BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MissionDetailScreen(mission: mission)),
    );
  }

  Widget _buildMissionCard(Mission mission, BuildContext context) {
    // Kunci harian 1x per misi — kartu selesai hari ini tetap bisa
    // di-tap untuk baca langkah (read-only di detail).
    if (mission.isCompletedToday) {
      return _buildCompletedCard(mission, context);
    }

    final buttonText = missionCtaLabel(mission);
    final buttonColor = mission.categoryColor;
    final canStart =
        mission.category == 'mobility' || mission.category == 'waste';
    final VoidCallback? onPressed = canStart
        ? () => startMission(context, mission)
        : null;

    return InkWell(
      onTap: () => _openDetail(mission, context),
      borderRadius: BorderRadius.circular(15),
      splashColor: const Color(0xFF1B8039).withValues(alpha: 0.12),
      highlightColor: const Color(0xFF1B8039).withValues(alpha: 0.06),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: mission.iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mission.categoryIcon,
                    color: mission.categoryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                // Middle Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: mission.categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mission.categoryIcon,
                                  color: mission.categoryColor,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  mission.categoryLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: mission.categoryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (mission.category == 'mobility' &&
                              mission.targetDistanceKm != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.flag,
                                    color: Color(0xFF1565C0),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Target ${mission.targetDistanceKm!.toStringAsFixed(1)} KM',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF1565C0),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              mission.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                height: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mission.description,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Points & Button Row (below the main content)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/ecopoints.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.eco,
                              color: Colors.green,
                              size: 20,
                            ),
                      ),
                      const SizedBox(width: 4),
                      Column(
                        children: [
                          Text(
                            '+${mission.pointsReward}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text('Poin', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: onPressed ?? () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Kartu misi yang sudah verified hari ini — terkunci sampai besok.
  /// Tetap bisa di-tap untuk membaca langkah di detail (read-only).
  Widget _buildCompletedCard(Mission mission, BuildContext context) {
    return InkWell(
      onTap: () => _openDetail(mission, context),
      borderRadius: BorderRadius.circular(15),
      splashColor: const Color(0xFF1B8039).withValues(alpha: 0.12),
      highlightColor: const Color(0xFF1B8039).withValues(alpha: 0.06),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F8E9),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFF1B8039), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFF1B8039),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          mission.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF1B8039),
                        size: 22,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B8039),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Selesai hari ini • Reset besok',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
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
