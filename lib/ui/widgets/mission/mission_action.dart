import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/mission/mission_bloc.dart';
import '../../../bloc/mission/mission_event.dart';
import '../../../core/utils/mission_steps.dart';
import '../../../models/mission.dart';
import '../../screens/misi_scan_screen.dart';
import '../../screens/mobility_tracker_screen.dart';

/// Aksi mulai misi bersama untuk kartu list & detail.
///
/// Mobility → [MobilityTrackerScreen] lalu refresh status harian +
/// snackbar reward. Waste → [MisiScanScreen]. Kategori lain → null.
Future<void> startMission(BuildContext context, Mission mission) async {
  if (mission.isCompletedToday) return;

  if (mission.category == 'mobility') {
    final bloc = context.read<MissionBloc>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MobilityTrackerScreen(
          missionTitle: mission.title,
          activityType:
              mission.activityType ?? activityTypeFromTitle(mission.title),
          missionId: mission.id,
          targetDistanceKm: mission.targetDistanceKm ?? 0.1,
        ),
      ),
    );
    // Refresh status harian agar kartu langsung terkunci.
    bloc.add(const MissionsLoaded(force: true));
    if (result is Map<String, dynamic> && context.mounted) {
      final xp = result['xp_earned']?.toString() ?? '0';
      final points = result['points_earned']?.toString() ?? '0';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Misi selesai! +$xp XP, +$points poin.'),
          backgroundColor: const Color(0xFF1B8039),
        ),
      );
    }
  } else if (mission.category == 'waste') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MisiScanScreen(missionTitle: mission.title, missionId: mission.id),
      ),
    );
  }
}

/// Label CTA per kategori (dipakai kartu & detail agar konsisten).
String missionCtaLabel(Mission mission) {
  switch (mission.category) {
    case 'mobility':
      return 'Mulai Tracker';
    case 'waste':
      return 'Upload Foto';
    default:
      return 'Mulai';
  }
}
