import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../bloc/mission/mission_bloc.dart';
import '../../bloc/mission/mission_event.dart';
import '../../bloc/mission/mission_state.dart';
import '../widgets/mobility/mobility_stats_sheet.dart';

/// Label Indonesia untuk tipe aktivitas mobilitas.
/// Dipakai [MobilityTrackerScreen], [_ConfirmSheet], dan [_SuccessSheet].
String activityTypeLabel(String activityType) {
  switch (activityType) {
    case 'walking':
      return 'Jalan kaki';
    case 'running':
      return 'Lari';
    default:
      return 'Bersepeda';
  }
}

/// Layar pelacakan Misi Mobilitas.
///
/// Flow: user pilih misi di [MisiScreen] → mulai tracker ini →
/// tombol Selesai → konfirmasi → POST /api/missions/mobility-sync →
/// result sheet (XP/poin/CO2).
///
/// GPS & timer dihitung lokal; validasi kecepatan, target jarak, anti-cheat,
/// karbon resmi, dan reward poin dihitung Backend.
class MobilityTrackerScreen extends StatefulWidget {
  const MobilityTrackerScreen({
    super.key,
    this.missionTitle = 'Pejuang Pedal 2Km',
    this.activityType = 'cycling',
    this.missionId,
    this.targetDistanceKm = 0.1,
  });

  final String missionTitle;
  final String activityType;
  final int? missionId;

  /// Target jarak misi (KM). Selesai hanya bisa dikirim bila tercapai.
  final double targetDistanceKm;

  @override
  State<MobilityTrackerScreen> createState() => _MobilityTrackerScreenState();
}

class _MobilityTrackerScreenState extends State<MobilityTrackerScreen>
    with WidgetsBindingObserver {
  static const _fallbackCenter = LatLng(-7.28, 112.79);

  /// Batas akurasi GPS (meter). Fix dengan akurasi lebih buruk dibuang.
  static const double _accuracyThresholdM = 30;

  /// Warm-up: kunci titik start setelah 3 fix bagus berurutan yang
  /// saling berdekatan. Mencegah lonjakan awal.
  static const int _warmupRequired = 3;
  static const double _warmupRadiusM = 50;

  /// Cap absolut per-segmen (meter). Lompatan > ini dianggap glitch.
  static const double _maxSegmentM = 100;

  /// Estimasi lokal karbon (g/km), sama dengan konstanta backend
  /// (MissionController::CO2_GRAMS_PER_KM = 210).
  static const double _co2GramsPerKm = 210;

  /// Batas validasi backend (MobilitySyncRequest): min 0.1 km,
  /// min 60 detik, min 2 titik GPS.
  static const double _minDistanceKm = 0.1;
  static const int _minDurationSeconds = 60;

  /// Parameter simulator rute demo (penilaian indoor).
  /// Langkah per 2 detik disesuaikan batas backend per aktivitas
  /// (walking 7 / running 14 / cycling 25 km/jam) agar selalu lolos:
  /// jalan 2 m (3,6 km/jam), lari 5 m (9 km/jam), sepeda 12 m (21,6 km/jam).
  /// Simulator HANYA menginjeksi titik ke [_handleRawFix] — seluruh
  /// filter, timer, validasi, dan POST backend tetap berjalan normal.
  static const double _simAccuracyM = 8;
  static const double _simBearingDeg = 45;

  /// Langkah simulasi (meter per 2 detik) mengikuti aktivitas terkunci.
  double get _simStepM {
    switch (activityType) {
      case 'walking':
        return 2;
      case 'running':
        return 5;
      default:
        return 12;
    }
  }

  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  // ---- Required state (kontrak tugas) ----
  // Terkunci dari misi yang dipilih — tidak bisa diganti mid-track.
  late final String activityType;
  double totalDistanceInKm = 0;
  int secondsElapsed = 0;
  final List<LatLng> routePoints = [];

  Timer? _timer;
  StreamSubscription<Position>? _positionSub;
  LatLng? _currentPosition;
  bool _isPaused = false;
  bool _isInitializing = true;
  bool _isFinished = false;
  String? _errorMessage;
  bool _syncDialogOpen = false;

  /// true saat simulator demo aktif (menggantikan stream GPS asli).
  bool _isSimulating = false;
  Timer? _simTimer;

  /// true setelah titik start dikunci (GPS akurat).
  bool _startLocked = false;
  final List<LatLng> _warmupFixes = [];

  /// true bila izin background (Always) granted — layar boleh dimatikan.
  /// false = mode foreground-only, user wajib menjaga layar menyala.
  bool _backgroundReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    activityType = switch (widget.activityType) {
      'walking' => 'walking',
      'running' => 'running',
      _ => 'cycling',
    };
    _initTracking();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Matikan wake lock karena tracking selesai/dibuang.
    WakelockPlus.disable();
    _timer?.cancel();
    _simTimer?.cancel();
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sengaja TIDAK pause stream/timer di sini: tracking harus tetap jalan
    // saat layar mati (locked) maupun app di-minimize. Stream dilindungi
    // foreground service (Android) / background location mode (iOS).
    // Kasus yang memang tidak didukung: app di-swipe kill & HP mati total.
  }

  Future<void> _initTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _fail('GPS tidak aktif. Aktifkan layanan lokasi lalu coba lagi.');
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      _fail('Izin lokasi ditolak. Tracker membutuhkan akses lokasi.');
      return;
    }
    if (permission == LocationPermission.deniedForever) {
      _fail('Izin lokasi ditolak permanen. Aktifkan di pengaturan aplikasi.');
      return;
    }

    // Izin background agar tracking tetap jalan saat layar mati / minimize.
    // Tanpa ini stream berhenti begitu activity tak terlihat → rute beku
    // di titik awal (bug yang terjadi saat testing pakai motor kemarin).
    _backgroundReady = await _ensureBackgroundPermissions();
    if (!mounted) return;

    // Tahan CPU tetap bangun selama tracking (pendamping wake lock milik
    // foreground service geolocator di Android).
    await WakelockPlus.enable();

    if (mounted) {
      setState(() {
        _currentPosition = _fallbackCenter;
        _isInitializing = false;
      });
    }
    if (!mounted) return;
    if (_backgroundReady) {
      _snack('Background aktif — boleh kunci layar, jangan tutup aplikasi.');
    } else {
      _snack(
        'Izin background ditolak: tracking hanya jalan saat layar menyala. '
        'Jangan kunci layar ya.',
      );
    }
    _startStream();

    try {
      final first = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      _handleRawFix(LatLng(first.latitude, first.longitude), first.accuracy);
    } catch (_) {
      // Abaikan — stream yang akan mengunci start saat GPS sudah bagus.
    }
  }

  /// Meminta izin penunjang background tracking.
  ///
  /// Return true bila mode background penuh siap (layar boleh dimatikan).
  /// - Android 10+: butuh `locationAlways` di samping foreground.
  /// - Android 11+: `locationAlways` hanya bisa granted via Settings, maka
  ///   user diarahkan lewat dialog; bila menolak, tracking tetap lanjut
  ///   mode foreground-only (wajib layar menyala).
  /// - Android 13+: butuh `notification` agar notifikasi foreground service
  ///   tampil (tanpa ini service bisa dibunuh sistem).
  Future<bool> _ensureBackgroundPermissions() async {
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    if (isAndroid) {
      // Hasil diabaikan: opsional, hanya agar notifikasi foreground tampil.
      await Permission.notification.request();
    }

    var whenInUse = await Permission.locationWhenInUse.status;
    if (whenInUse.isDenied) {
      whenInUse = await Permission.locationWhenInUse.request();
    }
    if (!whenInUse.isGranted && !whenInUse.isLimited) {
      return false;
    }

    var always = await Permission.locationAlways.status;
    if (always.isGranted) return true;
    if (always.isDenied) {
      always = await Permission.locationAlways.request();
      if (always.isGranted) return true;
    }
    if (!mounted) return false;
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan tracking background?'),
        content: const Text(
          'Agar rute tetap direkam saat layar dikunci, pilih '
          '"Allow all the time / Izinkan selalu" di pengaturan. '
          'Kalau dilewati, tracking hanya jalan saat layar menyala.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lewati'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
    if (openSettings == true) {
      await openAppSettings();
      always = await Permission.locationAlways.status;
      return always.isGranted;
    }
    return false;
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isInitializing = false;
    });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || _isFinished || !mounted) return;
      setState(() => secondsElapsed++);
    });
  }

  void _startStream() {
    _positionSub?.cancel();
    // Foreground service (Android) + background updates (iOS) agar stream
    // tetap hidup saat layar mati / app di-minimize. Tanpa
    // foregroundNotificationConfig, OS menghentikan update begitu activity
    // tidak terlihat → rute beku di titik awal.
    final LocationSettings settings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      settings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: 'KarbonKita tracking berjalan',
          notificationText:
              'Rute misi direkam — boleh kunci layar, jangan tutup aplikasi.',
          notificationChannelName: 'Tracking Misi',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      settings = AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        activityType: ActivityType.fitness,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    } else {
      settings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }
    _positionSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(_onPosition, onError: (_) {});
  }

  void _onPosition(Position position) {
    if (_isPaused || _isFinished || !mounted) return;
    _handleRawFix(
      LatLng(position.latitude, position.longitude),
      position.accuracy,
    );
  }

  void _handleRawFix(LatLng point, double accuracy) {
    if (_isPaused || _isFinished || !mounted) return;
    if (accuracy <= 0 || accuracy > _accuracyThresholdM) return;

    if (!_startLocked) {
      _warmupFixes.add(point);
      if (_warmupFixes.length > _warmupRequired) {
        _warmupFixes.removeAt(0);
      }
      setState(() => _currentPosition = point);
      if (_warmupFixes.length == _warmupRequired &&
          _warmupClustered(_warmupFixes)) {
        setState(() {
          _startLocked = true;
          routePoints.add(point);
          _currentPosition = point;
        });
        _mapController.move(point, 16);
        _startTimer();
      }
      return;
    }

    final last = routePoints.isNotEmpty ? routePoints.last : _currentPosition;
    if (last == null) {
      setState(() {
        routePoints.add(point);
        _currentPosition = point;
      });
      return;
    }
    final segmentM = _distance.as(LengthUnit.Meter, last, point);
    if (segmentM > _maxSegmentM) return; // teleport/glitch GPS — buang.
    if (segmentM < 1) {
      setState(() => _currentPosition = point);
      return;
    }
    setState(() {
      totalDistanceInKm += segmentM / 1000;
      routePoints.add(point);
      _currentPosition = point;
    });
    _mapController.move(point, _mapController.camera.zoom);
  }

  bool _warmupClustered(List<LatLng> fixes) {
    for (var i = 1; i < fixes.length; i++) {
      if (_distance.as(LengthUnit.Meter, fixes.first, fixes[i]) >
          _warmupRadiusM) {
        return false;
      }
    }
    return true;
  }

  void _togglePause() {
    if (_isInitializing || _isFinished || !_startLocked) return;
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _timer?.cancel();
      _positionSub?.pause();
    } else {
      _startTimer();
      _positionSub?.resume();
    }
  }

  /// Dialog konfirmasi sebelum simulator demo dijalankan.
  Future<void> _askStartSimulation() async {
    if (_isInitializing || _isFinished || _isSimulating) return;
    final start = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simulasi Rute (Demo)?'),
        content: Text(
          'Untuk penilaian indoor: rute buatan digerakkan otomatis '
          '(±$_simEstimateMinutes menit untuk target '
          '${_targetKm.toStringAsFixed(2)} KM). Rute tetap divalidasi '
          'server seperti biasa (jarak, durasi, kecepatan) dan tercatat '
          'sebagai aktivitas asli.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Mulai Simulasi'),
          ),
        ],
      ),
    );
    if (start == true) _startSimulation();
  }

  /// Menjalankan simulator: pause stream GPS asli, injeksi titik
  /// sintetis tiap 2 detik lewat [_handleRawFix] yang sama.
  void _startSimulation() {
    if (_isSimulating || _isFinished || !mounted) return;
    _positionSub?.pause();
    setState(() => _isSimulating = true);
    _beginSimTicks();
  }

  void _beginSimTicks() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_isPaused || _isFinished || !mounted) return;
      final base =
          _currentPosition ??
          (routePoints.isNotEmpty ? routePoints.last : _fallbackCenter);
      final next = _distance.offset(base, _simStepM, _simBearingDeg);
      _handleRawFix(next, _simAccuracyM);
    });
  }

  /// Menghentikan simulator dan mengembalikan stream GPS asli.
  void _stopSimulation() {
    if (!_isSimulating) return;
    _simTimer?.cancel();
    _simTimer = null;
    if (mounted) setState(() => _isSimulating = false);
    if (!_isFinished && !_isPaused) _positionSub?.resume();
  }

  /// Downsample rute agar tidak melebihi batas backend (max 2000 titik).
  List<Map<String, double>> _gpsPath() {
    var points = routePoints;
    if (points.length > 2000) {
      final step = points.length / 2000;
      final sampled = <LatLng>[];
      for (var i = 0; i < points.length; i += step.ceil()) {
        sampled.add(points[i]);
      }
      if (sampled.last != points.last) sampled.add(points.last);
      points = sampled;
    }
    return points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList();
  }

  double get _roundedDistanceKm =>
      double.parse(totalDistanceInKm.toStringAsFixed(2));

  /// Target efektif (fallback 0,1 km bila misi tak punya target).
  double get _targetKm =>
      widget.targetDistanceKm > 0 ? widget.targetDistanceKm : _minDistanceKm;

  /// Progres 0..1 menuju target (untuk progress bar).
  double get _targetProgress {
    if (_targetKm <= 0) return 0;
    final p = totalDistanceInKm / _targetKm;
    if (p < 0) return 0;
    if (p > 1) return 1;
    return p;
  }

  String get _distanceText =>
      '${totalDistanceInKm.toStringAsFixed(2)} / ${_targetKm.toStringAsFixed(2)} KM';

  /// Estimasi menit simulasi untuk mencapai target (untuk dialog demo).
  int get _simEstimateMinutes =>
      ((_targetKm * 1000 / _simStepM * 2) / 60).ceil() + 1;

  String get _co2Text {
    final kg = totalDistanceInKm * _co2GramsPerKm / 1000;
    return '${kg.toStringAsFixed(2)} kg CO2';
  }

  Future<void> _onFinish() async {
    if (_isInitializing || _isFinished) return;
    if (!_startLocked || routePoints.length < 2) {
      _snack('Tunggu sinyal GPS akurat dulu (minimal 2 titik rute).');
      return;
    }
    if (_roundedDistanceKm < _targetKm) {
      _snack(
        'Target misi ${_targetKm.toStringAsFixed(2)} KM belum tercapai '
        '(jarak ${totalDistanceInKm.toStringAsFixed(2)} KM). Lanjut lagi!',
      );
      return;
    }
    if (secondsElapsed < _minDurationSeconds) {
      _snack(
        'Durasi masih ${_formatDuration(secondsElapsed)}. '
        'Minimal 01:00 agar diterima backend.',
      );
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ConfirmSheet(
        missionTitle: widget.missionTitle,
        activityType: activityType,
        distanceText: _distanceText,
        targetText: 'Target ${_targetKm.toStringAsFixed(2)} KM tercapai',
        durationText: _formatDuration(secondsElapsed),
        co2Text: _co2Text,
        pointCount: routePoints.length,
        isSimulated: _isSimulating,
      ),
    );
    if (confirmed != true || !mounted) return;

    // Bekukan tracker lalu kirim ke backend via MissionBloc.
    setState(() => _isFinished = true);
    _timer?.cancel();
    _simTimer?.cancel();
    WakelockPlus.disable();
    await _positionSub?.cancel();
    if (!mounted) return;

    context.read<MissionBloc>().add(
      MobilitySynced(
        missionId: widget.missionId,
        activityType: activityType,
        distanceKm: _roundedDistanceKm,
        durationSeconds: secondsElapsed,
        gpsCoordinatesPath: _gpsPath(),
      ),
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleSyncSuccess(Map<String, dynamic>? result) {
    _closeSyncDialog();
    if (!mounted) return;
    context.read<MissionBloc>().add(const MobilitySyncReset());
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SuccessSheet(
        missionTitle: widget.missionTitle,
        activityType: activityType,
        result: result ?? const {},
        onDone: () {
          Navigator.pop(context); // tutup sheet
          Navigator.pop(context, result); // kembali ke Misi + bawa hasil
        },
      ),
    );
  }

  void _handleSyncFailure(String message) {
    _closeSyncDialog();
    if (!mounted) return;
    context.read<MissionBloc>().add(const MobilitySyncReset());
    final isDailyCap = message.toLowerCase().contains('sudah diselesaikan');
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FailureSheet(
        message: message,
        isDailyCap: isDailyCap,
        onRetry: () {
          Navigator.pop(context);
          _retrySync();
        },
        onResume: () {
          Navigator.pop(context);
          _resumeAfterFailure();
        },
        onBackToMissions: () {
          Navigator.pop(context);
          Navigator.pop(context);
          context.read<MissionBloc>().add(const MissionsLoaded(force: true));
        },
      ),
    );
  }

  void _retrySync() {
    setState(() => _isFinished = true);
    context.read<MissionBloc>().add(
      MobilitySynced(
        missionId: widget.missionId,
        activityType: activityType,
        distanceKm: _roundedDistanceKm,
        durationSeconds: secondsElapsed,
        gpsCoordinatesPath: _gpsPath(),
      ),
    );
  }

  void _resumeAfterFailure() {
    if (!mounted) return;
    setState(() => _isFinished = false);
    WakelockPlus.enable();
    if (_startLocked) _startTimer();
    if (_isSimulating) {
      _beginSimTicks();
    } else {
      _startStream();
    }
  }

  void _closeSyncDialog() {
    if (_syncDialogOpen && mounted) {
      Navigator.pop(context);
      _syncDialogOpen = false;
    }
  }

  void _showSyncDialog() {
    if (_syncDialogOpen) return;
    _syncDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF22C55E)),
                SizedBox(height: 12),
                Text('Mengirim aktivitas ke server...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _recenter() {
    final target = _currentPosition;
    if (target != null) _mapController.move(target, 16);
  }

  Future<bool> _confirmDiscard() async {
    if (!_startLocked || _isFinished) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan misi?'),
        content: const Text(
          'Rute yang sudah direkam akan hilang dan tidak dapat poin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjut'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MissionBloc, MissionState>(
      listenWhen: (prev, curr) => prev.mobilityStatus != curr.mobilityStatus,
      listener: (context, state) {
        switch (state.mobilityStatus) {
          case MobilitySyncStatus.syncing:
            _showSyncDialog();
            break;
          case MobilitySyncStatus.success:
            _handleSyncSuccess(state.mobilityResult);
            break;
          case MobilitySyncStatus.failure:
            _handleSyncFailure(
              state.mobilityErrorMessage ?? 'Gagal sinkronisasi.',
            );
            break;
          case MobilitySyncStatus.initial:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FA),
        body: _isInitializing
            ? const _LoadingView()
            : _errorMessage != null
            ? _ErrorView(message: _errorMessage!, onBack: _onBack)
            : BlocBuilder<MissionBloc, MissionState>(
                buildWhen: (prev, curr) =>
                    prev.mobilityStatus != curr.mobilityStatus,
                builder: (context, syncState) {
                  final isSyncing =
                      syncState.mobilityStatus == MobilitySyncStatus.syncing;
                  return _TrackerView(
                    mapController: _mapController,
                    routePoints: routePoints,
                    currentPosition: _currentPosition,
                    missionTitle: widget.missionTitle,
                    durationText: _formatDuration(secondsElapsed),
                    distanceText: _distanceText,
                    targetProgress: _targetProgress,
                    targetText: 'Target ${_targetKm.toStringAsFixed(2)} KM',
                    co2Text: _co2Text,
                    activityType: activityType,
                    isPaused: _isPaused,
                    isSyncing: isSyncing,
                    isWaitingGps: !_startLocked,
                    isSimulating: _isSimulating,
                    showBackgroundHint: _backgroundReady,
                    onBack: _onBack,
                    onRecenter: _recenter,
                    onStartSimulation: _askStartSimulation,
                    onStopSimulation: _stopSimulation,
                    onPauseResume: _togglePause,
                    onFinish: _onFinish,
                  );
                },
              ),
      ),
    );
  }

  Future<void> _onBack() async {
    if (await _confirmDiscard()) {
      if (mounted) Navigator.pop(context);
    }
  }
}

class _TrackerView extends StatelessWidget {
  const _TrackerView({
    required this.mapController,
    required this.routePoints,
    required this.currentPosition,
    required this.missionTitle,
    required this.durationText,
    required this.distanceText,
    required this.targetProgress,
    required this.targetText,
    required this.co2Text,
    required this.activityType,
    required this.isPaused,
    required this.isSyncing,
    this.isWaitingGps = false,
    this.isSimulating = false,
    this.showBackgroundHint = false,
    required this.onBack,
    required this.onRecenter,
    required this.onStartSimulation,
    required this.onStopSimulation,
    required this.onPauseResume,
    required this.onFinish,
  });

  final MapController mapController;
  final List<LatLng> routePoints;
  final LatLng? currentPosition;
  final String missionTitle;
  final String durationText;
  final String distanceText;
  final double targetProgress;
  final String targetText;
  final String co2Text;
  final String activityType;
  final bool isPaused;
  final bool isSyncing;
  final bool isWaitingGps;
  final bool isSimulating;
  final bool showBackgroundHint;
  final VoidCallback onBack;
  final VoidCallback onRecenter;
  final VoidCallback onStartSimulation;
  final VoidCallback onStopSimulation;
  final VoidCallback onPauseResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _MapView(
            mapController: mapController,
            routePoints: routePoints,
            currentPosition: currentPosition,
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _CircleButton(icon: Icons.arrow_back, onTap: onBack),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            missionTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.lock,
                          size: 14,
                          color: Color(0xFF1B8039),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 16,
          top: MediaQuery.of(context).size.height * 0.42,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CircleButton(
                icon: Icons.my_location,
                iconColor: const Color(0xFF22C55E),
                onTap: onRecenter,
              ),
              const SizedBox(height: 10),
              _CircleButton(
                icon: isSimulating ? Icons.stop_circle : Icons.science,
                iconColor: const Color(0xFFF9A825),
                onTap: isSimulating ? onStopSimulation : onStartSimulation,
              ),
            ],
          ),
        ),
        if (isSimulating)
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).size.height * 0.12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9A825),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.science, color: Colors.white, size: 16),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'MODE DEMO — rute simulasi, tetap divalidasi server.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (isWaitingGps)
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).size.height * 0.12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mencari sinyal GPS akurat… tetap di tempat.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (showBackgroundHint)
          Positioned(
            left: 16,
            right: 16,
            top: MediaQuery.of(context).size.height * 0.12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1B8039),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 16),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Background aktif — boleh kunci layar, jangan tutup aplikasi.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: MobilityStatsSheet(
            durationText: durationText,
            distanceText: distanceText,
            targetProgress: targetProgress,
            targetText: targetText,
            co2Text: co2Text,
            activityType: activityType,
            isPaused: isPaused,
            isSyncing: isSyncing,
            isSimulating: isSimulating,
            onPauseResume: onPauseResume,
            onFinish: onFinish,
          ),
        ),
      ],
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({
    required this.mapController,
    required this.routePoints,
    required this.currentPosition,
  });

  final MapController mapController;
  final List<LatLng> routePoints;
  final LatLng? currentPosition;

  @override
  Widget build(BuildContext context) {
    final center =
        currentPosition ??
        (routePoints.isNotEmpty
            ? routePoints.first
            : _MobilityTrackerScreenState._fallbackCenter);
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(initialCenter: center, initialZoom: 16),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.karbonkita.app',
        ),
        if (routePoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: const Color(0xFF22C55E),
                strokeWidth: 5,
              ),
            ],
          ),
        if (currentPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: currentPosition!,
                width: 36,
                height: 36,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const CircleAvatar(backgroundColor: Color(0xFF2196F3)),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF2E9E4B)),
          SizedBox(height: 12),
          Text(
            'Mengaktifkan GPS...',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_outlined,
                size: 56,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onBack,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E9E4B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = Colors.black87,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

/// Konfirmasi sebelum kirim ke backend.
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.missionTitle,
    required this.activityType,
    required this.distanceText,
    required this.targetText,
    required this.durationText,
    required this.co2Text,
    required this.pointCount,
    this.isSimulated = false,
  });

  final String missionTitle;
  final String activityType;
  final String distanceText;
  final String targetText;
  final String durationText;
  final String co2Text;
  final int pointCount;
  final bool isSimulated;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              missionTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${activityTypeLabel(activityType)} (terkunci) • $pointCount titik GPS',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (isSimulated) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.science, size: 12, color: Color(0xFFF9A825)),
                    SizedBox(width: 4),
                    Text(
                      'Rute simulasi (demo) — tetap divalidasi server',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(label: 'Jarak', value: distanceText),
                ),
                Expanded(
                  child: _SummaryItem(label: 'Durasi', value: durationText),
                ),
                Expanded(
                  child: _SummaryItem(label: 'CO2', value: co2Text),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.flag, size: 14, color: Color(0xFF1B8039)),
                const SizedBox(width: 4),
                Text(
                  targetText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B8039),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Lanjut'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Kirim'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

/// Hasil sukses dari backend: XP, poin, CO2, level, streak.
class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({
    required this.missionTitle,
    required this.activityType,
    required this.result,
    required this.onDone,
  });

  final String missionTitle;
  final String activityType;
  final Map<String, dynamic> result;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final xp = result['xp_earned']?.toString() ?? '0';
    final points = result['points_earned']?.toString() ?? '0';
    final distance = result['distance_km']?.toString() ?? '-';
    final co2g = result['co2_saved_grams'];
    final co2 = co2g == null
        ? '-'
        : '${(double.tryParse(co2g.toString()) ?? 0) / 1000} kg';
    final level = result['new_level']?.toString();
    final streak = result['streak_days']?.toString();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFF22C55E),
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Misi selesai!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '$missionTitle • ${activityTypeLabel(activityType)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _RewardCard(label: 'XP', value: '+$xp'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RewardCard(label: 'Poin', value: '+$points'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _RewardCard(label: 'Jarak', value: '$distance km'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'CO2 hemat $co2'
                '${level != null ? ' • $level' : ''}'
                '${streak != null ? ' • Streak $streak hari' : ''}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: const Text('Kembali ke Misi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B8039),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

/// Gagal sync: tampilkan pesan backend + opsi retry / lanjut tracking.
/// Untuk kunci harian, retry tidak ada gunanya — tampilkan tombol kembali.
class _FailureSheet extends StatelessWidget {
  const _FailureSheet({
    required this.message,
    required this.onRetry,
    required this.onResume,
    this.isDailyCap = false,
    this.onBackToMissions,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onResume;
  final bool isDailyCap;
  final VoidCallback? onBackToMissions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Icon(
              isDailyCap ? Icons.lock : Icons.error_outline,
              color: isDailyCap ? const Color(0xFF1B8039) : Colors.red,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              isDailyCap
                  ? 'Sudah selesai hari ini'
                  : 'Gagal mengirim aktivitas',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            if (isDailyCap)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onBackToMissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B8039),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kembali ke Misi'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onResume,
                      child: const Text('Lanjut Tracking'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
