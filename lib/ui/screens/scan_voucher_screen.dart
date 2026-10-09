import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../bloc/merchant/merchant_bloc.dart';
import '../../bloc/merchant/merchant_event.dart';
import '../../bloc/merchant/merchant_state.dart';
import '../../models/merchant_dashboard.dart';

/// Scanner voucher merchant: kamera QR asli + input manual token.
///
/// - Hasil scan QR / input manual dikirim sebagai `unique_code` ke
///   `POST /api/vouchers/redeem` via [MerchantBloc].
/// - Format token asli backend `KBK-XXX-XXX` — tidak ada validasi regex
///   di client, biarkan backend memvalidasi `exists:qr_token`.
class ScanVoucherScreen extends StatefulWidget {
  const ScanVoucherScreen({super.key});

  @override
  State<ScanVoucherScreen> createState() => _ScanVoucherScreenState();
}

class _ScanVoucherScreenState extends State<ScanVoucherScreen> {
  late final MobileScannerController _scannerController;
  final TextEditingController _tokenController = TextEditingController();
  bool _isTorchOn = false;
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    final state = context.read<MerchantBloc>().state;
    if (_sheetOpen || state.redeemStatus == MerchantRedeemStatus.redeeming) {
      return;
    }
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue?.trim() ?? '';
    if (raw.isEmpty) return;
    _tokenController.text = raw;
    _submit(raw);
  }

  void _handleVerifikasi() {
    final text = _tokenController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor token voucher')),
      );
      return;
    }
    _submit(text);
  }

  void _submit(String code) {
    context.read<MerchantBloc>().add(MerchantRedeemSubmitted(code));
  }

  String _cameraErrorMessage(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Akses kamera ditolak. Aktifkan izin kamera untuk aplikasi ini di pengaturan, lalu coba lagi.';
      case MobileScannerErrorCode.unsupported:
        return 'Perangkat ini tidak mendukung pemindaian QR. Gunakan input manual di bawah.';
      default:
        return 'Kamera gagal dinyalakan. Gunakan input manual token di bawah.';
    }
  }

  void _showSuccessSheet(RedeemResult result) {
    _sheetOpen = true;
    _scannerController.stop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
        result: result,
        onDone: () {
          Navigator.pop(context);
        },
      ),
    ).whenComplete(() {
      if (!mounted) return;
      _sheetOpen = false;
      context.read<MerchantBloc>().add(const MerchantRedeemReset());
      _tokenController.clear();
      _scannerController.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A14),
      body: SafeArea(
        child: BlocListener<MerchantBloc, MerchantState>(
          listenWhen: (prev, curr) => prev.redeemStatus != curr.redeemStatus,
          listener: (context, state) {
            if (state.redeemStatus == MerchantRedeemStatus.success &&
                state.lastRedeem != null) {
              _showSuccessSheet(state.lastRedeem!);
            } else if (state.redeemStatus == MerchantRedeemStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.redeemErrorMessage ?? 'Gagal verifikasi voucher.',
                  ),
                  backgroundColor: const Color(0xFFB71C1C),
                ),
              );
            } else if (state.isUnauthorized) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesi berakhir. Silakan login ulang.'),
                ),
              );
            }
          },
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scanner Voucher',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Arahkan kamera ke QR voucher pelanggan',
                        style: TextStyle(fontSize: 13, color: Colors.white60),
                      ),
                      const SizedBox(height: 16),
                      _buildViewport(),
                      const SizedBox(height: 20),
                      _buildManualInput(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.pop(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chevron_left, color: Colors.white70, size: 20),
                SizedBox(width: 4),
                Text(
                  'Kembali ke Dashboard Merchant',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              await _scannerController.toggleTorch();
              if (mounted) setState(() => _isTorchOn = !_isTorchOn);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  Icon(
                    _isTorchOn ? Icons.flash_on : Icons.flash_off,
                    color: _isTorchOn ? Colors.amber : Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lampu',
                    style: TextStyle(
                      fontSize: 11,
                      color: _isTorchOn ? Colors.amber : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewport() {
    return BlocBuilder<MerchantBloc, MerchantState>(
      buildWhen: (prev, curr) => prev.redeemStatus != curr.redeemStatus,
      builder: (context, state) {
        final redeeming = state.redeemStatus == MerchantRedeemStatus.redeeming;
        return Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onBarcodeDetect,
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.no_photography_outlined,
                              color: Colors.white54,
                              size: 36,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _cameraErrorMessage(error),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () async {
                                try {
                                  await _scannerController.start();
                                } catch (_) {}
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white38),
                              ),
                              child: const Text('Coba Nyalakan Kamera'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Positioned(
                  top: 16,
                  left: 16,
                  child: _Corner(top: true, left: true),
                ),
                const Positioned(
                  top: 16,
                  right: 16,
                  child: _Corner(top: true, left: false),
                ),
                const Positioned(
                  bottom: 16,
                  left: 16,
                  child: _Corner(top: false, left: true),
                ),
                const Positioned(
                  bottom: 16,
                  right: 16,
                  child: _Corner(top: false, left: false),
                ),
                if (redeeming)
                  Container(
                    color: Colors.black.withValues(alpha: 0.55),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF00E676)),
                          SizedBox(height: 12),
                          Text(
                            'Memverifikasi voucher…',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Text(
                      'Posisikan QR di dalam area',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManualInput() {
    return BlocBuilder<MerchantBloc, MerchantState>(
      buildWhen: (prev, curr) => prev.redeemStatus != curr.redeemStatus,
      builder: (context, state) {
        final redeeming = state.redeemStatus == MerchantRedeemStatus.redeeming;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3329),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Input Manual Nomor Token Voucher',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A3F35),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: TextField(
                        controller: _tokenController,
                        enabled: !redeeming,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: KBK-ABC-DEF',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.characters,
                        onSubmitted: (_) => _handleVerifikasi(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: redeeming ? null : _handleVerifikasi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E9E4B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: redeeming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Verifikasi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00E676);
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        children: [
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            left: left ? 0 : null,
            right: left ? null : 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessSheet extends StatelessWidget {
  final RedeemResult result;
  final VoidCallback onDone;
  const _SuccessSheet({required this.result, required this.onDone});

  @override
  Widget build(BuildContext context) {
    final success = result.isCompleted;
    return Container(
      margin: EdgeInsets.only(
        top: 80,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: success
                    ? const Color(0xFF1B8039)
                    : const Color(0xFFF57F17),
                shape: BoxShape.circle,
              ),
              child: Icon(
                success ? Icons.check : Icons.hourglass_empty,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Voucher Berhasil Diverifikasi!' : 'Payout Diproses!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              success
                  ? 'Transaksi berhasil dan dana telah dicairkan.'
                  : 'Payout diterima Xendit, menunggu status final via webhook.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            _InfoCard(
              icon: Icons.local_offer,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF43A047),
              label: 'Detail Voucher',
              title: result.voucherTitle.isEmpty
                  ? result.qrToken
                  : '${result.voucherTitle} — ${_formatRp(result.amount)}',
              subtitle: 'Token: ${result.qrToken}',
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF5EB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1B8039).withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'xendit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF1B8039),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Pencairan Dana via Xendit',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF1B8039),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          success
                              ? 'Pencairan Dana ${_formatRp(result.amount)} via Xendit SUKSES!'
                              : 'Payout ${result.disbursementStatus} — Ref ${result.referenceId}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1B8039),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ref: ${result.referenceId}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: success
                          ? const Color(0xFF43A047)
                          : const Color(0xFFF57F17),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      success ? Icons.check : Icons.hourglass_empty,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onDone,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text(
                  'Selesai & Scan Lagi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8039),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 12,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(width: 4),
                Text(
                  'Aman & Terverifikasi',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _formatRp(double value) {
    final intPart = value.truncate().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      final rev = intPart.length - i;
      buffer.write(intPart[i]);
      if (rev > 1 && rev % 3 == 1) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String title;
  final String subtitle;
  const _InfoCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
