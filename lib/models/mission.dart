import 'package:flutter/material.dart';

/// Mission model dari API response.
/// Backend MissionResource: id, title, description, category, activity_type
/// (mobility saja: walking/running/cycling, null = misi lama),
/// xp_reward, points_reward, target_distance_km (mobility saja,
/// null = tanpa target), icon, is_completed_today (kunci harian 1x per misi).
class Mission {
  const Mission({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.xpReward,
    required this.pointsReward,
    required this.icon,
    this.isCompletedToday = false,
    this.targetDistanceKm,
    this.activityType,
    this.isActive = true,
  });

  final int id;
  final String title;
  final String description;
  final String category; // 'mobility' | 'waste' | 'quiz'
  final int xpReward;
  final int pointsReward;
  final String icon;

  /// True bila user sudah verified misi ini hari ini (WIB).
  /// Default false agar cache lama tetap aman.
  final bool isCompletedToday;

  /// Target jarak (KM) khusus misi mobilitas. Null = tanpa target.
  final double? targetDistanceKm;

  /// Aktivitas pengikat misi mobilitas (walking/running/cycling).
  /// Null untuk misi lama / non-mobilitas — pemanggil fallback ke
  /// tebakan judul via [activityTypeFromTitle].
  final String? activityType;

  /// Status aktif dari backend. Default true agar cache lama tetap aman.
  final bool isActive;

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'mobility',
      xpReward: (json['xp_reward'] as num? ?? 0).toInt(),
      pointsReward: (json['points_reward'] as num? ?? 0).toInt(),
      icon: json['icon'] as String? ?? '',
      isCompletedToday: json['is_completed_today'] as bool? ?? false,
      targetDistanceKm: (json['target_distance_km'] as num?)?.toDouble(),
      activityType: json['activity_type'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'xp_reward': xpReward,
    'points_reward': pointsReward,
    'icon': icon,
    'is_completed_today': isCompletedToday,
    'target_distance_km': targetDistanceKm,
    'activity_type': activityType,
    'is_active': isActive,
  };

  /// Helper untuk mapping category ke icon Flutter
  IconData get categoryIcon {
    switch (category) {
      case 'mobility':
        return Icons.pedal_bike;
      case 'waste':
        return Icons.recycling;
      case 'quiz':
        return Icons.help_outline;
      default:
        return Icons.assignment;
    }
  }

  /// Helper untuk mapping category ke color
  Color get categoryColor {
    switch (category) {
      case 'mobility':
        return Colors.green;
      case 'waste':
        return Colors.green;
      case 'quiz':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  /// Helper untuk mapping category ke label Indonesia
  String get categoryLabel {
    switch (category) {
      case 'mobility':
        return 'Mobilitas';
      case 'waste':
        return 'Sampah';
      case 'quiz':
        return 'Kuis';
      default:
        return category;
    }
  }

  /// Helper untuk background color icon
  Color get iconBgColor {
    switch (category) {
      case 'mobility':
        return const Color(0xFFE8F5E9);
      case 'waste':
        return const Color(0xFFE8F5E9);
      case 'quiz':
        return const Color(0xFFFFF3E0);
      default:
        return const Color(0xFFE3F2FD);
    }
  }
}
