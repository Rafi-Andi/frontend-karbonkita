import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/admin_mission/admin_mission_bloc.dart';
import '../../bloc/admin_mission/admin_mission_event.dart';
import '../../bloc/admin_mission/admin_mission_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../models/mission.dart';
import '../widgets/validation_error_sheet.dart';
import 'mission_form_screen.dart';

/// Kelola misi mobility & waste (role:admin): daftar semua status,
/// tambah, ubah, aktif/nonaktif.
///
/// Gaya mengikuti AdminValidationScreen (header + kartu putih).
class MissionManageScreen extends StatefulWidget {
  const MissionManageScreen({super.key});

  @override
  State<MissionManageScreen> createState() => _MissionManageScreenState();
}

class _MissionManageScreenState extends State<MissionManageScreen> {
  static const _green = Color(0xFF1B8039);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminMissionBloc>().add(const AdminMissionsLoaded());
      }
    });
  }

  void _openForm([Mission? mission]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MissionFormScreen(mission: mission)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminMissionBloc, AdminMissionState>(
      listenWhen: (prev, curr) =>
          (!prev.isUnauthorized && curr.isUnauthorized) ||
          (prev.submitStatus != curr.submitStatus &&
              (curr.submitStatus == AdminMissionSubmitStatus.success ||
                  curr.submitStatus == AdminMissionSubmitStatus.failure)),
      listener: (context, state) {
        if (state.isUnauthorized) {
          context.read<AuthBloc>().add(const LoggedOut());
          return;
        }
        if (state.submitStatus == AdminMissionSubmitStatus.success) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(content: Text('Misi tersimpan.')));
          context.read<AdminMissionBloc>().add(const AdminMissionSubmitReset());
        } else if (state.submitStatus == AdminMissionSubmitStatus.failure) {
          final items = collectValidationErrors(state.submitErrors);
          if (items.isNotEmpty) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => ValidationErrorSheet(
                title: 'Gagal menyimpan misi',
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
          context.read<AdminMissionBloc>().add(const AdminMissionSubmitReset());
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
                          'Kelola Misi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => context.read<AdminMissionBloc>().add(
                            const AdminMissionsLoaded(),
                          ),
                          icon: const Icon(Icons.refresh),
                          tooltip: 'Muat ulang',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text(
                          'Tambah Misi Baru',
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
                    const SizedBox(height: 12),
                    BlocBuilder<AdminMissionBloc, AdminMissionState>(
                      buildWhen: (prev, curr) => prev.filter != curr.filter,
                      builder: (context, state) {
                        return Wrap(
                          spacing: 8,
                          children: [
                            _FilterChip(
                              label: 'Semua',
                              selected: state.filter == null,
                              onTap: () => context.read<AdminMissionBloc>().add(
                                const AdminMissionsFiltered(null),
                              ),
                            ),
                            _FilterChip(
                              label: 'Mobilitas',
                              selected: state.filter == 'mobility',
                              onTap: () => context.read<AdminMissionBloc>().add(
                                const AdminMissionsFiltered('mobility'),
                              ),
                            ),
                            _FilterChip(
                              label: 'Sampah',
                              selected: state.filter == 'waste',
                              onTap: () => context.read<AdminMissionBloc>().add(
                                const AdminMissionsFiltered('waste'),
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
    return BlocBuilder<AdminMissionBloc, AdminMissionState>(
      builder: (context, state) {
        if (state.status == AdminMissionStatus.loading &&
            state.missions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminMissionStatus.error &&
            state.missions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(state.errorMessage ?? 'Gagal memuat misi.'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => context.read<AdminMissionBloc>().add(
                    const AdminMissionsLoaded(),
                  ),
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          );
        }
        final items = state.filteredMissions;
        if (items.isEmpty) {
          return const Center(child: Text('Belum ada misi pada filter ini.'));
        }
        return RefreshIndicator(
          onRefresh: () async =>
              context.read<AdminMissionBloc>().add(const AdminMissionsLoaded()),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _MissionCard(
              mission: items[i],
              onEdit: () => _openForm(items[i]),
              onToggle: () => context.read<AdminMissionBloc>().add(
                AdminMissionStatusSubmitted(
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

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.onEdit,
    required this.onToggle,
  });

  final Mission mission;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final meta = mission.category == 'mobility'
        ? () {
            final activity = switch (mission.activityType) {
              'walking' => 'Jalan kaki',
              'running' => 'Lari',
              'cycling' => 'Bersepeda',
              _ => 'Aktivitas bebas',
            };
            final target = mission.targetDistanceKm != null
                ? ' • Target ${mission.targetDistanceKm!.toStringAsFixed(1)} KM'
                : '';
            return 'Mobilitas • $activity$target';
          }()
        : 'Sampah • Validasi foto AI';
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
            children: [
              Expanded(
                child: Text(
                  mission.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: mission.isActive
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mission.isActive ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: mission.isActive
                        ? const Color(0xFF1B8039)
                        : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            meta,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            '+${mission.xpReward} XP • +${mission.pointsReward} poin',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B8039),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Ubah'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    mission.isActive
                        ? Icons.power_settings_new
                        : Icons.play_arrow,
                    size: 16,
                  ),
                  label: Text(mission.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
