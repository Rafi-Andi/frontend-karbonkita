import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/register_region/register_region_cubit.dart';
import '../../models/region.dart';

/// Satu dropdown wilayah (provinsi / kota / kecamatan / kelurahan).
///
/// Dipakai berulang oleh [RegionCascadingDropdowns] agar register pengguna
/// dan register UMKM memakai tampilan + perilaku yang persis sama.
class RegionDropdownField extends StatelessWidget {
  const RegionDropdownField({
    super.key,
    required this.hint,
    required this.icon,
    required this.value,
    required this.items,
    required this.loading,
    required this.onChanged,
  });

  final String hint;
  final IconData icon;
  final Region? value;
  final List<Region> items;
  final bool loading;
  final ValueChanged<Region?> onChanged;

  @override
  Widget build(BuildContext context) {
    final enabled = !loading && items.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Region>(
          isExpanded: true,
          value: value,
          icon: loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
          hint: Row(
            children: [
              Icon(icon, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loading ? 'Memuat...' : hint,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          items: items
              .map(
                (r) => DropdownMenuItem<Region>(
                  value: r,
                  child: Text(
                    r.name,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

/// 4 dropdown cascading wilayah.id: Provinsi → Kota/Kab → Kecamatan → Kelurahan.
///
/// Dipakai di register pengguna dan (2x instance) di register UMKM
/// (domisili owner + alamat usaha). Sumber data dari [RegisterRegionCubit]
/// yang disuntik via [cubit] — tiap grup alamat wajib punya cubit sendiri
/// agar pilihan domisili dan usaha tidak saling menimpa.
///
/// Menampilkan notice offline + tombol muat ulang (via [onRetry] bila
/// disediakan, default ke `cubit.retry()`), serta error per level.
class RegionCascadingDropdowns extends StatelessWidget {
  const RegionCascadingDropdowns({
    super.key,
    required this.cubit,
    this.helperText = 'Pilih dari daftar agar datamu konsisten',
  });

  final RegisterRegionCubit cubit;
  final String helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 20,
              color: Colors.black87,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Pilih Wilayah',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            BlocBuilder<RegisterRegionCubit, RegisterRegionState>(
              bloc: cubit,
              builder: (context, state) {
                final loading = state.loadingLevel != null;
                return IconButton(
                  tooltip: 'Muat ulang daftar wilayah',
                  onPressed: loading ? null : cubit.retry,
                  icon: loading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.refresh,
                          size: 20,
                          color: Color(0xFF1B8039),
                        ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        BlocBuilder<RegisterRegionCubit, RegisterRegionState>(
          bloc: cubit,
          builder: (context, state) {
            return Column(
              children: [
                if (state.isOffline) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 16,
                          color: Colors.amber.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mode offline: daftar wilayah terbatas. '
                                'Sambungkan internet lalu ketuk ikon muat ulang di atas.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              if (state.offlineReason != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Detail: ${state.offlineReason}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                RegionDropdownField(
                  hint: 'Provinsi',
                  icon: Icons.map_outlined,
                  value: state.province,
                  items: state.provinces,
                  loading: state.loadingLevel == RegionLevel.province,
                  onChanged: (v) => cubit.selectProvince(v),
                ),
                const SizedBox(height: 12),
                RegionDropdownField(
                  hint: 'Kota / Kabupaten',
                  icon: Icons.location_city,
                  value: state.regency,
                  items: state.regencies,
                  loading: state.loadingLevel == RegionLevel.regency,
                  onChanged: (v) => cubit.selectRegency(v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RegionDropdownField(
                        hint: 'Kecamatan',
                        icon: Icons.share_location,
                        value: state.district,
                        items: state.districts,
                        loading: state.loadingLevel == RegionLevel.district,
                        onChanged: (v) => cubit.selectDistrict(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RegionDropdownField(
                        hint: 'Kelurahan',
                        icon: Icons.home_work_outlined,
                        value: state.village,
                        items: state.villages,
                        loading: state.loadingLevel == RegionLevel.village,
                        onChanged: (v) => cubit.selectVillage(v),
                      ),
                    ),
                  ],
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.error!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}
