import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/voucher/voucher_bloc.dart';
import '../../bloc/voucher/voucher_event.dart';
import '../../bloc/voucher/voucher_state.dart';
import '../../core/network/api_endpoints.dart';
import '../../models/voucher.dart';
import 'dompet_voucher_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  @override
  void initState() {
    super.initState();
    context.read<VoucherBloc>().add(const VouchersLoaded());
  }

  /// Format angka ala Indonesia: 1250 -> "1.250".
  String _formatPoints(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    var count = 0;
    for (var i = digits.length - 1; i >= 0; i--) {
      buffer.write(digits[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write('.');
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<VoucherBloc, VoucherState>(
      listenWhen: (prev, curr) =>
          (!prev.isUnauthorized && curr.isUnauthorized) ||
          (prev.claimStatus != curr.claimStatus &&
              (curr.claimStatus == ClaimStatus.success ||
                  curr.claimStatus == ClaimStatus.failure)),
      listener: (context, state) {
        if (state.isUnauthorized) {
          context.read<AuthBloc>().add(const LoggedOut());
          return;
        }
        if (state.claimStatus == ClaimStatus.success &&
            state.lastClaim != null) {
          _showClaimSuccess(
            state.lastClaim!.qrToken,
            state.lastClaim!.voucherTitle,
            state.lastClaim!.remainingPoints,
          );
        } else if (state.claimStatus == ClaimStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.claimErrorMessage ?? 'Gagal klaim voucher.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.read<VoucherBloc>().add(const VoucherClaimReset());
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FA),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildPointsAndWalletRow(),
                const SizedBox(height: 20),
                _buildCategoryChips(),
                const SizedBox(height: 20),
                _buildBanner(),
                const SizedBox(height: 25),
                _buildRecommendationsHeader(),
                const SizedBox(height: 15),
                _buildProductsGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onClaimTap(Voucher voucher) {
    final ecoPoints = context.read<VoucherBloc>().state.ecoPoints;
    if (ecoPoints != null && voucher.pointsCost > ecoPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Poin tidak cukup. Butuh ${_formatPoints(voucher.pointsCost)}, '
            'saldo ${_formatPoints(ecoPoints)}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tukar Voucher?'),
        content: Text(
          '${voucher.title}\n'
          'Biaya: ${_formatPoints(voucher.pointsCost)} poin'
          '${ecoPoints == null ? '' : '\nSisa: ${_formatPoints(ecoPoints - voucher.pointsCost)} poin'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<VoucherBloc>().add(
                VoucherClaimSubmitted(voucher.id),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B8039),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tukar'),
          ),
        ],
      ),
    );
  }

  void _showClaimSuccess(String qrToken, String title, int remaining) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF1B8039)),
            SizedBox(width: 8),
            Expanded(child: Text('Voucher Diklaim!')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'KODE VOUCHER',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                  Text(
                    qrToken,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sisa poin: ${_formatPoints(remaining)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tunjukkan kode ini ke kasir merchant untuk ditukar.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<VoucherBloc>().add(const VoucherClaimReset());
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<VoucherBloc>().add(const VoucherClaimReset());
              Navigator.of(dialogContext).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DompetVoucherScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B8039),
              foregroundColor: Colors.white,
            ),
            child: const Text('Lihat Dompet'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.shopping_bag, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Green Market Place',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E6C46),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPointsAndWalletRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/ecopoints.png',
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.eco, color: Colors.green, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Poin: ',
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                BlocBuilder<VoucherBloc, VoucherState>(
                  buildWhen: (prev, curr) =>
                      prev.ecoPoints != curr.ecoPoints ||
                      prev.status != curr.status,
                  builder: (context, state) {
                    if (state.status == VoucherStatus.loading &&
                        state.ecoPoints == null) {
                      return const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    return Text(
                      _formatPoints(state.ecoPoints ?? 0),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DompetVoucherScreen(),
                ),
              );
            },
            icon: const Icon(Icons.account_balance_wallet, size: 18),
            label: const Text(
              'Dompet Voucher',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B8039),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return BlocBuilder<VoucherBloc, VoucherState>(
      buildWhen: (prev, curr) =>
          prev.selectedCategory != curr.selectedCategory ||
          prev.status != curr.status,
      builder: (context, state) {
        final loadingCategory = state.status == VoucherStatus.loading
            ? state.selectedCategory
            : null;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(VoucherCategory.values.length, (index) {
              final category = VoucherCategory.values[index];
              final isSelected = state.selectedCategory == category.value;
              final isLoadingThis =
                  state.status == VoucherStatus.loading &&
                  loadingCategory == category.value;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: isSelected
                      ? null
                      : () {
                          context.read<VoucherBloc>().add(
                            VouchersLoaded(category: category.value),
                          );
                        },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLoadingThis)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Icon(
                            category.icon,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 16,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          category.label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.asset(
        'assets/images/bannermarketplace.png',
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildRecommendationsHeader() {
    return Row(
      children: [
        Image.asset(
          'assets/images/ecopoints.png',
          width: 20,
          height: 20,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.eco, color: Colors.green, size: 20),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Rekomendasi Untukmu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lihat Semua',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
              Icon(Icons.chevron_right, color: Colors.green, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductsGrid() {
    return BlocBuilder<VoucherBloc, VoucherState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.vouchers != curr.vouchers ||
          prev.selectedCategory != curr.selectedCategory ||
          prev.claimStatus != curr.claimStatus ||
          prev.claimingVoucherId != curr.claimingVoucherId ||
          prev.ecoPoints != curr.ecoPoints,
      builder: (context, state) {
        if (state.status == VoucherStatus.loading ||
            state.status == VoucherStatus.initial) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(color: Color(0xFF1B8039)),
            ),
          );
        }

        if (state.status == VoucherStatus.error) {
          return _buildErrorState(
            'Tidak ada koneksi dan belum ada data tersimpan.\n${state.errorMessage ?? 'Terjadi kesalahan'}',
          );
        }

        if (state.vouchers.isEmpty) {
          return _buildEmptyState(state.selectedCategory);
        }

        return GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.62,
          children: state.vouchers
              .map((voucher) => _buildProductCard(voucher))
              .toList(),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
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
              final category = context
                  .read<VoucherBloc>()
                  .state
                  .selectedCategory;
              context.read<VoucherBloc>().add(
                VouchersLoaded(category: category),
              );
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

  Widget _buildEmptyState(String? category) {
    String? label;
    if (category != null) {
      for (final c in VoucherCategory.values) {
        if (c.value == category) {
          label = c.label;
          break;
        }
      }
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
          Icon(Icons.storefront_outlined, color: Colors.grey[400], size: 48),
          const SizedBox(height: 12),
          Text(
            label == null
                ? 'Belum ada voucher tersedia'
                : 'Belum ada voucher $label',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Voucher voucher) {
    final storeName = voucher.mitra.displayName;

    return Container(
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
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
              child: Builder(
                builder: (context) {
                  // Samakan host URL gambar dengan baseUrl aplikasi.
                  final imageUrl = ApiEndpoints.resolveImageUrl(
                    voucher.imageUrl,
                  );
                  if (imageUrl.isEmpty) {
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
                    );
                  }
                  return Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.brown.shade100,
                        child: Text(
                          storeName.isNotEmpty
                              ? storeName[0].toUpperCase()
                              : '-',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.brown.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              storeName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Image.asset(
                                  'assets/images/ecopoints.png',
                                  width: 12,
                                  height: 12,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.eco,
                                        color: Colors.green,
                                        size: 12,
                                      ),
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'UMKM',
                                  style: TextStyle(
                                    fontSize: 8,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    voucher.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B8039),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  BlocBuilder<VoucherBloc, VoucherState>(
                    buildWhen: (prev, curr) =>
                        prev.claimStatus != curr.claimStatus ||
                        prev.claimingVoucherId != curr.claimingVoucherId,
                    builder: (context, claimState) {
                      final claimingThis =
                          claimState.claimStatus == ClaimStatus.claiming &&
                          claimState.claimingVoucherId == voucher.id;
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: claimingThis
                              ? null
                              : () => _onClaimTap(voucher),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8F5E9),
                            foregroundColor: const Color(0xFF1B8039),
                            disabledBackgroundColor: const Color(0xFFE8F5E9),
                            disabledForegroundColor: const Color(0xFF1B8039),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: const BorderSide(
                                color: Color(0xFF1B8039),
                                width: 1,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (claimingThis)
                                  const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF1B8039),
                                    ),
                                  )
                                else ...[
                                  Image.asset(
                                    'assets/images/ecopoints.png',
                                    width: 14,
                                    height: 14,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(
                                              Icons.eco,
                                              color: Color(0xFF1B8039),
                                              size: 14,
                                            ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Tukar ${_formatPoints(voucher.pointsCost)} Poin',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
