import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/admin_mission/admin_mission_bloc.dart';
import '../../../bloc/admin_mission/admin_mission_event.dart';
import '../../../bloc/admin_mission/admin_mission_state.dart';
import '../../../models/mission.dart';
import '../widgets/validation_error_sheet.dart';

/// Form tambah/ubah misi mobility & waste (role:admin).
///
/// `mission` null = tambah baru; selain itu = ubah (kategori terkunci).
/// Field kondisional mengikuti kategori: mobility → aktivitas + target
/// jarak; waste → validation prompt. Error 422 tampil sebagai bottom sheet
/// rincian, form tetap terbuka agar bisa diperbaiki.
class MissionFormScreen extends StatefulWidget {
  const MissionFormScreen({super.key, this.mission});

  final Mission? mission;

  @override
  State<MissionFormScreen> createState() => _MissionFormScreenState();
}

class _MissionFormScreenState extends State<MissionFormScreen> {
  static const _green = Color(0xFF1B8039);

  static const _categories = ['mobility', 'waste'];
  static const _activities = ['walking', 'running', 'cycling'];

  static const _icons = [
    'directions_bike',
    'directions_walk',
    'directions_run',
    'wb_sunny',
    'recycling',
    'memory',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _xp;
  late final TextEditingController _points;
  late final TextEditingController _target;
  late final TextEditingController _prompt;

  late String _category;
  String? _activity;
  String? _icon;
  late bool _isActive;

  bool get _isEdit => widget.mission != null;
  bool get _isMobility => _category == 'mobility';

  @override
  void initState() {
    super.initState();
    final m = widget.mission;
    _title = TextEditingController(text: m?.title ?? '');
    _description = TextEditingController(text: m?.description ?? '');
    _xp = TextEditingController(text: m != null ? '${m.xpReward}' : '');
    _points = TextEditingController(text: m != null ? '${m.pointsReward}' : '');
    _target = TextEditingController(
      text: m?.targetDistanceKm != null ? '${m!.targetDistanceKm}' : '',
    );
    _prompt = TextEditingController();
    _category = m?.category == 'waste' ? 'waste' : 'mobility';
    _activity = m?.activityType ?? (_isMobility ? 'walking' : null);
    _icon = m?.icon.isNotEmpty == true ? m!.icon : null;
    _isActive = m?.isActive ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _xp.dispose();
    _points.dispose();
    _target.dispose();
    _prompt.dispose();
    super.dispose();
  }

  String _categoryLabel(String value) => value == 'mobility'
      ? 'Mobilitas (jalan/lari/sepeda)'
      : 'Sampah (foto AI)';

  String _activityLabel(String value) {
    switch (value) {
      case 'walking':
        return 'Jalan kaki (maks 7 km/jam)';
      case 'running':
        return 'Lari (maks 14 km/jam)';
      default:
        return 'Bersepeda (maks 25 km/jam)';
    }
  }

  void _onCategoryChanged(String? value) {
    if (value == null || _isEdit) return;
    setState(() => _category = value);
  }

  Map<String, dynamic> _buildFields() {
    final fields = <String, dynamic>{
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      if (_xp.text.trim().isNotEmpty) 'xp_reward': int.parse(_xp.text.trim()),
      if (_points.text.trim().isNotEmpty)
        'points_reward': int.parse(_points.text.trim()),
      if (_icon != null) 'icon': _icon,
      'is_active': _isActive,
    };
    if (!_isEdit) fields['category'] = _category;
    if (_isMobility) {
      fields['activity_type'] = _activity;
      fields['target_distance_km'] = double.parse(
        _target.text.trim().replaceAll(',', '.'),
      );
    } else {
      fields['validation_prompt'] = _prompt.text.trim();
    }
    return fields;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final m = widget.mission;
    if (_isEdit) {
      context.read<AdminMissionBloc>().add(
        AdminMissionUpdateSubmitted(id: m!.id, fields: _buildFields()),
      );
    } else {
      context.read<AdminMissionBloc>().add(
        AdminMissionCreateSubmitted(_buildFields()),
      );
    }
  }

  void _showErrors(
    BuildContext context,
    Map<String, List<String>> errors,
    String? fallback,
  ) {
    final items = collectValidationErrors(errors);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(fallback ?? 'Gagal menyimpan misi.'),
            backgroundColor: const Color(0xFFB71C1C),
          ),
        );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ValidationErrorSheet(title: 'Periksa isian form', items: items),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminMissionBloc, AdminMissionState>(
      listenWhen: (prev, curr) =>
          prev.submitStatus != curr.submitStatus &&
          (curr.submitStatus == AdminMissionSubmitStatus.success ||
              curr.submitStatus == AdminMissionSubmitStatus.failure),
      listener: (context, state) {
        if (state.submitStatus == AdminMissionSubmitStatus.success) {
          context.read<AdminMissionBloc>().add(const AdminMissionSubmitReset());
          Navigator.pop(context, true);
          return;
        }
        if (state.submitStatus == AdminMissionSubmitStatus.failure) {
          _showErrors(context, state.submitErrors, state.submitErrorMessage);
          context.read<AdminMissionBloc>().add(const AdminMissionSubmitReset());
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FA),
        appBar: AppBar(
          title: Text(_isEdit ? 'Ubah Misi' : 'Tambah Misi'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: InputDecoration(
                    labelText: 'Kategori',
                    border: const OutlineInputBorder(),
                    helperText: _isEdit
                        ? 'Kategori terkunci setelah misi dibuat.'
                        : null,
                  ),
                  items: _categories
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(_categoryLabel(c)),
                        ),
                      )
                      .toList(),
                  onChanged: _isEdit ? null : _onCategoryChanged,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: 'Judul misi',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _xp,
                        decoration: const InputDecoration(
                          labelText: 'XP reward',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return int.tryParse(v.trim()) == null
                              ? 'Harus angka.'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _points,
                        decoration: const InputDecoration(
                          labelText: 'Poin reward',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          return int.tryParse(v.trim()) == null
                              ? 'Harus angka.'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _icons.contains(_icon) ? _icon : null,
                  decoration: const InputDecoration(
                    labelText: 'Ikon (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  items: _icons
                      .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                      .toList(),
                  onChanged: (v) => setState(() => _icon = v),
                ),
                if (_isMobility) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _activities.contains(_activity)
                        ? _activity
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Aktivitas',
                      border: OutlineInputBorder(),
                      helperText:
                          'Mengunci kecepatan valid + tracker di aplikasi.',
                    ),
                    items: _activities
                        .map(
                          (a) => DropdownMenuItem(
                            value: a,
                            child: Text(_activityLabel(a)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _activity = v),
                    validator: (v) => v == null ? 'Wajib dipilih.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _target,
                    decoration: const InputDecoration(
                      labelText: 'Target jarak (KM)',
                      border: OutlineInputBorder(),
                      helperText: 'Minimal 0,1 KM.',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Wajib diisi.';
                      final parsed = double.tryParse(
                        v.trim().replaceAll(',', '.'),
                      );
                      if (parsed == null) return 'Harus angka.';
                      if (parsed < 0.1) return 'Minimal 0,1 KM.';
                      return null;
                    },
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _prompt,
                    decoration: const InputDecoration(
                      labelText: 'Kriteria foto (validation prompt)',
                      border: OutlineInputBorder(),
                      helperText:
                          'Instruksi untuk AI: jenis sampah + syarat foto.',
                    ),
                    maxLines: 4,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Wajib diisi.' : null,
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Misi aktif'),
                  subtitle: const Text(
                    'Nonaktif = disembunyikan dari warga, riwayat tetap aman.',
                  ),
                  activeThumbColor: _green,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),
                BlocBuilder<AdminMissionBloc, AdminMissionState>(
                  buildWhen: (prev, curr) =>
                      prev.submitStatus != curr.submitStatus,
                  builder: (context, state) {
                    final busy =
                        state.submitStatus ==
                        AdminMissionSubmitStatus.submitting;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: busy ? null : _submit,
                        icon: busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save, size: 18),
                        label: Text(
                          busy
                              ? 'Menyimpan...'
                              : (_isEdit ? 'Simpan Perubahan' : 'Buat Misi'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
