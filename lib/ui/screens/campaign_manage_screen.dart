import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/admin_campaign/admin_campaign_bloc.dart';
import '../../bloc/admin_campaign/admin_campaign_event.dart';
import '../../bloc/admin_campaign/admin_campaign_state.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../models/donation.dart';

/// Kelola campaign donasi (role:admin): daftar semua status,
/// buat baru, ubah status/target/jadwal.
///
/// Gaya mengikuti AdminValidationScreen (header + kartu putih).
class CampaignManageScreen extends StatefulWidget {
  const CampaignManageScreen({super.key});

  @override
  State<CampaignManageScreen> createState() => _CampaignManageScreenState();
}

class _CampaignManageScreenState extends State<CampaignManageScreen> {
  static const _green = Color(0xFF1B8039);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminCampaignBloc>().add(const AdminCampaignsLoaded());
      }
    });
  }

  String _formatRupiah(double value) {
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminCampaignBloc, AdminCampaignState>(
      listenWhen: (prev, curr) =>
          (!prev.isUnauthorized && curr.isUnauthorized) ||
          (prev.submitStatus != curr.submitStatus &&
              (curr.submitStatus == AdminCampaignSubmitStatus.success ||
                  curr.submitStatus == AdminCampaignSubmitStatus.failure)),
      listener: (context, state) {
        if (state.isUnauthorized) {
          context.read<AuthBloc>().add(const LoggedOut());
          return;
        }
        if (state.submitStatus == AdminCampaignSubmitStatus.success) {
          final extra = state.lastCampaign != null
              ? ' (ID ${state.lastCampaign!['id']})'
              : '';
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Berhasil disimpan$extra.')));
          context.read<AdminCampaignBloc>().add(
            const AdminCampaignSubmitReset(),
          );
        } else if (state.submitStatus == AdminCampaignSubmitStatus.failure &&
            state.submitErrorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.submitErrorMessage!),
                backgroundColor: const Color(0xFFB71C1C),
              ),
            );
          context.read<AdminCampaignBloc>().add(
            const AdminCampaignSubmitReset(),
          );
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
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      behavior: HitTestBehavior.opaque,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios,
                            color: Color(0xFF2D3436),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Kembali',
                            style: TextStyle(
                              color: Color(0xFF2D3436),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Kelola Campaign',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Buat campaign donasi & atur status penggalangan.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showCampaignForm(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Buat Campaign Baru',
                          style: TextStyle(
                            fontSize: 13,
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
    return BlocBuilder<AdminCampaignBloc, AdminCampaignState>(
      builder: (context, state) {
        if (state.status == AdminCampaignStatus.loading &&
            state.campaigns.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.status == AdminCampaignStatus.error &&
            state.campaigns.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage ?? 'Gagal memuat campaign.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.read<AdminCampaignBloc>().add(
                      const AdminCampaignsLoaded(),
                    ),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (state.campaigns.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada campaign. Buat yang pertama!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => context.read<AdminCampaignBloc>().add(
            const AdminCampaignsLoaded(),
          ),
          color: _green,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            itemCount: state.campaigns.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final campaign = state.campaigns[index];
              final submitting =
                  state.submitStatus == AdminCampaignSubmitStatus.submitting;
              return _CampaignRow(
                campaign: campaign,
                formatRupiah: _formatRupiah,
                submitting: submitting,
                onCycleStatus: () => _cycleStatus(context, campaign),
              );
            },
          ),
        );
      },
    );
  }

  /// Putar status draft -> active -> closed (PATCH, 1 field).
  void _cycleStatus(BuildContext context, DonationCampaign campaign) {
    const order = ['draft', 'active', 'closed'];
    final next = order[(order.indexOf(campaign.status) + 1) % order.length];
    context.read<AdminCampaignBloc>().add(
      AdminCampaignUpdateSubmitted(id: campaign.id, fields: {'status': next}),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Mengubah status ke "$next"...')));
  }

  void _showCampaignForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminCampaignBloc>(),
        child: const _CampaignFormSheet(),
      ),
    );
  }
}

class _CampaignRow extends StatelessWidget {
  const _CampaignRow({
    required this.campaign,
    required this.formatRupiah,
    required this.submitting,
    required this.onCycleStatus,
  });

  final DonationCampaign campaign;
  final String Function(double) formatRupiah;
  final bool submitting;
  final VoidCallback onCycleStatus;

  @override
  Widget build(BuildContext context) {
    final style = _campaignStatusStyle(campaign.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  campaign.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  campaign.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: style.fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Terkumpul ${formatRupiah(campaign.collectedAmount)} / '
            '${formatRupiah(campaign.targetAmount)} • '
            'Tersedia ${formatRupiah(campaign.availableAmount)}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: submitting ? null : onCycleStatus,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B8039),
                side: const BorderSide(color: Color(0xFF1B8039)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text(
                'Ganti Status Berikutnya',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusChip _campaignStatusStyle(String status) {
    switch (status) {
      case 'active':
        return const _StatusChip(bg: Color(0xFFE8F5E9), fg: Color(0xFF1B8039));
      case 'closed':
        return const _StatusChip(bg: Color(0xFFEEEEEE), fg: Color(0xFF616161));
      default:
        return const _StatusChip(bg: Color(0xFFFFF3E0), fg: Color(0xFFE65100));
    }
  }
}

class _StatusChip {
  const _StatusChip({required this.bg, required this.fg});

  final Color bg;
  final Color fg;
}

/// Sheet form buat campaign: title, description, target, status awal.
class _CampaignFormSheet extends StatefulWidget {
  const _CampaignFormSheet();

  @override
  State<_CampaignFormSheet> createState() => _CampaignFormSheetState();
}

class _CampaignFormSheetState extends State<_CampaignFormSheet> {
  static const _green = Color(0xFF1B8039);

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _targetController = TextEditingController();
  String _status = 'draft';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final target = int.tryParse(
      _targetController.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan deskripsi wajib diisi.')),
      );
      return;
    }
    if (target == null || target < 100000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Target minimal Rp 100.000.')),
      );
      return;
    }
    context.read<AdminCampaignBloc>().add(
      AdminCampaignCreateSubmitted({
        'title': title,
        'description': desc,
        'target_amount': target,
        'status': _status,
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminCampaignBloc, AdminCampaignState>(
      listenWhen: (prev, curr) =>
          prev.submitStatus != curr.submitStatus &&
          curr.submitStatus == AdminCampaignSubmitStatus.success,
      listener: (context, _) => Navigator.pop(context),
      child: Container(
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
          child: BlocBuilder<AdminCampaignBloc, AdminCampaignState>(
            builder: (context, state) {
              final submitting =
                  state.submitStatus == AdminCampaignSubmitStatus.submitting;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Buat Campaign Baru',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _titleController,
                    'Judul campaign',
                    enabled: !submitting,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    _descController,
                    'Deskripsi program',
                    maxLines: 3,
                    enabled: !submitting,
                  ),
                  const SizedBox(height: 10),
                  _field(
                    _targetController,
                    'Target dana (min Rp 100.000)',
                    keyboard: TextInputType.number,
                    enabled: !submitting,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        'Status awal: ',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _status,
                        items: const ['draft', 'active']
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: submitting
                            ? null
                            : (v) => setState(() => _status = v ?? 'draft'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 0,
                      ),
                      child: submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Buat Campaign',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboard,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF4FAF5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
