import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;

import '../../bloc/mission/mission_bloc.dart';
import '../../bloc/mission/mission_event.dart';
import '../../bloc/mission/mission_state.dart';
import '../../models/verify_waste_result.dart';
import '../widgets/mission_scan/scan_frame_painter.dart';
import '../widgets/mission_scan/validation_result_sheet.dart';
import '../widgets/mission_scan/waste_verify_dialogs.dart';

/// Kompresi foto hasil kamera di background isolate (pure-Dart).
///
/// Return path file siap upload (≤5MB sesuai `VerifyWasteRequest` backend).
/// Gagal/berukuran kecil → return [originalPath] apa adanya.
String _compressImage(String originalPath) {
  try {
    final bytes = File(originalPath).readAsBytesSync();
    if (bytes.lengthInBytes <= 4 * 1024 * 1024) return originalPath;
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return originalPath;
    final resized = decoded.width > 1080
        ? img.copyResize(decoded, width: 1080)
        : decoded;
    var quality = 82;
    var out = img.encodeJpg(resized, quality: quality);
    while (out.length > 5 * 1024 * 1024 && quality > 55) {
      quality -= 10;
      out = img.encodeJpg(resized, quality: quality);
    }
    final target =
        '${Directory.systemTemp.path}/karbonkita_waste_${DateTime.now().millisecondsSinceEpoch}.jpg';
    File(target).writeAsBytesSync(out);
    return target;
  } catch (_) {
    return originalPath;
  }
}

/// Halaman "Validasi Misi Scan Kamera AI".
///
/// Dibuka dari tab Misi via tombol "Upload Foto" kartu kategori Sampah.
/// Foto hasil [takePicture] dikompres lokal lalu diupload ke
/// `POST /api/missions/verify-waste` via [MissionBloc]; validasi Gemini
/// berjalan server-side.
class MisiScanScreen extends StatefulWidget {
  const MisiScanScreen({
    super.key,
    this.missionTitle = 'Misi Sampah',
    this.missionId,
  });

  final String missionTitle;
  final int? missionId;

  @override
  State<MisiScanScreen> createState() => _MisiScanScreenState();
}

class _MisiScanScreenState extends State<MisiScanScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  String? _errorMessage;
  bool _flashOn = false;
  bool _isCapturing = false;

  /// Path foto terakhir (untuk retry 503/failure tanpa foto ulang).
  String? _lastImagePath;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _fail('Tidak ada kamera yang tersedia di perangkat ini.');
        return;
      }
      final back = cameras.where(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      final selected = back.isNotEmpty ? back.first : cameras.first;
      final controller = CameraController(
        selected,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } on CameraException catch (e) {
      _fail(_cameraErrorText(e));
    } catch (_) {
      _fail('Gagal membuka kamera. Periksa izin kamera lalu coba lagi.');
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isInitializing = false;
    });
  }

  String _cameraErrorText(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        return 'Izin kamera ditolak. Aktifkan izin kamera di pengaturan.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Izin kamera ditolak permanen. Aktifkan di pengaturan aplikasi.';
      case 'CameraAccessRestricted':
        return 'Akses kamera dibatasi di perangkat ini.';
      default:
        return 'Gagal membuka kamera (${e.code}). Coba lagi.';
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final next = !_flashOn;
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashOn = next);
    } catch (_) {
      // Abaikan: tidak semua perangkat mendukung torch saat preview.
    }
  }

  Future<void> _onShutter() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }
    final missionId = widget.missionId;
    if (missionId == null) {
      _snack('Misi tidak valid. Kembali lalu coba lagi.');
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final photo = await controller.takePicture();
      // Kompres di isolate agar UI tidak macet, lalu kirim ke backend.
      final uploadPath = await compute(_compressImage, photo.path);
      if (!mounted) return;
      _lastImagePath = uploadPath;
      context.read<MissionBloc>().add(
        WasteVerifyRequested(missionId: missionId, imagePath: uploadPath),
      );
    } on CameraException {
      if (mounted) {
        _snack('Gagal mengambil foto. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _retryUpload() {
    final missionId = widget.missionId;
    final imagePath = _lastImagePath;
    if (missionId == null || imagePath == null) {
      _snack('Foto sebelumnya hilang. Ambil foto baru.');
      return;
    }
    context.read<MissionBloc>().add(
      WasteVerifyRequested(missionId: missionId, imagePath: imagePath),
    );
  }

  void _resetVerify() {
    context.read<MissionBloc>().add(const WasteVerifyReset());
  }

  void _backToMissions({Object? result}) {
    _resetVerify();
    if (mounted) Navigator.pop(context, result);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------- Bloc listener ----------

  void _onVerifyState(BuildContext context, MissionState state) {
    switch (state.wasteVerifyStatus) {
      case WasteVerifyStatus.verified:
        final result = state.verifyResult;
        if (result != null) _showResultSheet(result);
      case WasteVerifyStatus.rejected:
        final result = state.verifyResult;
        if (result != null) _showResultSheet(result);
      case WasteVerifyStatus.duplicate:
        showDuplicateWasteDialog(
          context,
          message:
              state.wasteVerifyErrorMessage ??
              'Foto ini sudah pernah dipakai orang lain.',
          onBackToMissions: () => _backToMissions(),
        );
      case WasteVerifyStatus.dailyCapped:
        showDailyCappedWasteDialog(
          context,
          message:
              state.wasteVerifyErrorMessage ??
              'Misi ini sudah diselesaikan hari ini.',
          onBackToMissions: () => _backToMissions(),
        );
      case WasteVerifyStatus.pendingReview:
        showPendingWasteDialog(
          context,
          message:
              state.wasteVerifyErrorMessage ??
              'AI sedang sibuk. Foto masuk antrean.',
          onRetry: _retryUpload,
          onBackToMissions: () => _backToMissions(),
        );
      case WasteVerifyStatus.failure:
        showWasteFailureDialog(
          context,
          message:
              state.wasteVerifyErrorMessage ??
              'Terjadi kesalahan jaringan. Coba lagi.',
          onRetry: _retryUpload,
          onBackToMissions: () => _backToMissions(),
        );
      case WasteVerifyStatus.initial:
      case WasteVerifyStatus.uploading:
        break;
    }
  }

  Future<void> _showResultSheet(VerifyWasteResult result) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ValidationResultSheet(
        result: result,
        onContinue: () {
          Navigator.pop(context); // tutup sheet
          _backToMissions(result: true); // kembali ke layar Misi
        },
        onRetry: result.verified
            ? null
            : () {
                Navigator.pop(context); // tutup sheet, tetap di kamera
                _resetVerify();
              },
      ),
    );
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    return BlocListener<MissionBloc, MissionState>(
      listenWhen: (prev, curr) =>
          prev.wasteVerifyStatus != curr.wasteVerifyStatus,
      listener: _onVerifyState,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<MissionBloc, MissionState>(
          buildWhen: (prev, curr) =>
              prev.wasteVerifyStatus != curr.wasteVerifyStatus,
          builder: (context, state) {
            final uploading =
                state.wasteVerifyStatus == WasteVerifyStatus.uploading;
            if (_isInitializing) return _buildLoading();
            if (_errorMessage != null || _controller == null) {
              return _buildCameraError();
            }
            return _buildCameraView(
              busy: _isCapturing || uploading,
              busyLabel: uploading
                  ? 'Mengupload & AI menganalisis foto...\nBisa memakan waktu ~20 detik'
                  : 'Menyiapkan foto...',
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF2E9E4B)),
          SizedBox(height: 12),
          Text(
            'Membuka kamera...',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white54,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Kamera tidak tersedia.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 20),
              _backPill(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraView({required bool busy, required String busyLabel}) {
    return Stack(
      children: [
        Positioned.fill(child: _buildPreview()),
        SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 10),
              _buildTooltip(),
              const Spacer(),
              _buildScanFrame(),
              const Spacer(),
              _buildShutter(busy: busy),
              const SizedBox(height: 24),
            ],
          ),
        ),
        if (busy) _buildAnalyzingOverlay(busyLabel),
      ],
    );
  }

  Widget _buildPreview() {
    final controller = _controller!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final previewSize = controller.value.previewSize;
        if (previewSize == null) return CameraPreview(controller);
        return ClipRect(
          child: OverflowBox(
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: previewSize.height,
                height: previewSize.width,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_backPill(), _flashButton()],
      ),
    );
  }

  Widget _backPill() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Kembali ke Misi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _flashButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _toggleFlash,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: _flashOn
                  ? Border.all(color: const Color(0xFFFFD54F), width: 1.5)
                  : null,
            ),
            child: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? const Color(0xFFFFD54F) : Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Flash',
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildTooltip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lightbulb_outline, color: Color(0xFF22C55E), size: 16),
          SizedBox(width: 6),
          Flexible(
            child: Text(
              'Pastikan sampah terpilah terlihat jelas & pencahayaan cukup',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFrame() {
    final side = MediaQuery.of(context).size.width * 0.68;
    return IgnorePointer(
      child: SizedBox(
        width: side,
        height: side,
        child: CustomPaint(painter: ScanFramePainter()),
      ),
    );
  }

  Widget _buildShutter({required bool busy}) {
    return GestureDetector(
      onTap: busy ? null : _onShutter,
      child: Opacity(
        opacity: busy ? 0.6 : 1,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, color: Colors.green[700], size: 28),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyzingOverlay(String label) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    color: Color(0xFF22C55E),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
