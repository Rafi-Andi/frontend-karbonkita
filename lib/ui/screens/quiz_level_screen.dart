import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../bloc/dashboard/dashboard_state.dart';
import '../../bloc/quiz/quiz_bloc.dart';
import '../../bloc/quiz/quiz_event.dart';
import '../../bloc/quiz/quiz_state.dart';
import '../../models/quiz_node.dart';
import '../../models/quiz_stage.dart';
import '../widgets/quiz/quiz_info_card.dart';
import '../widgets/quiz/quiz_level_header.dart';
import '../widgets/quiz/quiz_path_painter.dart';
import '../widgets/quiz/quiz_quota_banner.dart';
import '../widgets/quiz/quiz_stage_bottom_sheet.dart';
import '../widgets/quiz/quiz_stage_node.dart';

/// Halaman Level Kuis bergaya gamifikasi (Duolingo-like).
/// Dibuka via Floating Widget kuis (FABKuis) dengan full-screen push.
/// Daftar node (1 node = 1 misi quiz) dimuat dari backend via QuizBloc;
/// hanya 1 node berikutnya yang belum selesai yang terbuka berurutan
/// dari bawah (anti-loncat), sisanya locked. Kuota 2 node selesai per hari;
/// selesai node 1 langsung membuka node 2 hari itu juga.
/// Skip sehari tidak menghanguskan progres.
class QuizLevelScreen extends StatefulWidget {
  const QuizLevelScreen({super.key});

  @override
  State<QuizLevelScreen> createState() => _QuizLevelScreenState();
}

class _QuizLevelScreenState extends State<QuizLevelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<QuizBloc>().add(const DailyQuizLoaded());
        context.read<QuizBloc>().add(const SagaNodesLoaded());
      }
    });
  }

  /// Petakan node backend ke model tampilan stage.
  QuizStage _stageFor(QuizNode node) {
    final status = node.isDone
        ? QuizStageStatus.completed
        : node.isPlayableToday
        ? QuizStageStatus.active
        : QuizStageStatus.locked;
    return QuizStage(
      number: node.position,
      tag: 'BABAK ${node.position}',
      title: node.title,
      description: node.description,
      questionCount: node.quizzesCount,
      status: status,
    );
  }

  /// Kuota harian: max 2 node selesai/hari (1 node = 1 sesi).
  static const int _dailyQuota = 2;

  int _remainingQuota(List<QuizNode> nodes) {
    final doneToday = nodes.where((n) => n.isCompletedToday).length;
    return (_dailyQuota - doneToday).clamp(0, _dailyQuota);
  }

  void _onNodeTap(BuildContext context, QuizNode node, int remainingQuota) {
    final stage = _stageFor(node);
    // Semua node bisa dibuka untuk lihat deskripsi; hanya playable
    // yang bisa dimainkan (diatur di bottom sheet, termasuk lock kuota habis).
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuizStageBottomSheet(
        stage: stage,
        node: node,
        remainingQuota: remainingQuota,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F0),
      body: BlocListener<QuizBloc, QuizState>(
        listenWhen: (prev, curr) => !prev.isUnauthorized && curr.isUnauthorized,
        listener: (context, state) {
          context.read<AuthBloc>().add(const LoggedOut());
        },
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: BlocBuilder<DashboardBloc, DashboardState>(
                  builder: (context, dashState) {
                    final points = dashState.dashboard?.user.ecoPoints ?? 0;
                    return QuizLevelHeader(
                      title: QuizLevelData.levelTitle,
                      userPoints: points,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: BlocBuilder<QuizBloc, QuizState>(
                  builder: (context, state) =>
                      QuizQuotaBanner(remaining: _remainingQuota(state.nodes)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: BlocBuilder<QuizBloc, QuizState>(
                  builder: (context, state) => _buildDailyStatus(state),
                ),
              ),
              Expanded(
                child: BlocBuilder<QuizBloc, QuizState>(
                  builder: (context, state) {
                    if (state.nodesStatus == SagaNodesStatus.loading ||
                        state.nodesStatus == SagaNodesStatus.initial) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF43A047),
                        ),
                      );
                    }
                    if (state.nodesStatus == SagaNodesStatus.error) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Tidak ada koneksi dan belum ada data tersimpan.\n${state.nodesErrorMessage ?? 'Gagal memuat peta saga.'}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => context.read<QuizBloc>().add(
                                  const SagaNodesLoaded(force: true),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF43A047),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final nodes = [...state.nodes]
                      ..sort((a, b) => a.position.compareTo(b.position));
                    if (nodes.isEmpty) {
                      return const Center(
                        child: Text(
                          'Belum ada babak kuis.',
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final w = constraints.maxWidth;
                          return SizedBox(
                            height: _mapHeight(nodes.length),
                            width: w,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: QuizPathPainter(),
                                  ),
                                ),
                                // Panah latar dekoratif.
                                Positioned(
                                  left: w * 0.16,
                                  top: 150,
                                  child: Icon(
                                    Icons.arrow_upward,
                                    size: 44,
                                    color: const Color(
                                      0xFF1B5E20,
                                    ).withValues(alpha: 0.08),
                                  ),
                                ),
                                Positioned(
                                  right: w * 0.12,
                                  top: 210,
                                  child: Icon(
                                    Icons.arrow_upward,
                                    size: 54,
                                    color: const Color(
                                      0xFF1B5E20,
                                    ).withValues(alpha: 0.08),
                                  ),
                                ),
                                // Kartu hadiah di ujung jalur (atas).
                                Positioned(
                                  top: 6,
                                  left: 0,
                                  right: 0,
                                  child: Center(child: _buildRewardCard(nodes)),
                                ),
                                // Node dari backend: posisi teratas = position terbesar.
                                ..._buildNodeWidgets(context, nodes, w),
                                // Kartu motivasi kiri.
                                Positioned(
                                  top: 228,
                                  left: 12,
                                  child: QuizInfoCard(
                                    icon: Icons.recycling,
                                    iconColor: const Color(0xFF43A047),
                                    iconBgColor: const Color(0xFFE8F5E9),
                                    subtitle:
                                        'Terus belajar,\nselamatkan bumi!',
                                    maxWidth: 150,
                                  ),
                                ),
                                // Kartu motivasi kanan.
                                Positioned(
                                  top: 420,
                                  right: 12,
                                  child: QuizInfoCard(
                                    icon: Icons.lightbulb_outline,
                                    iconColor: const Color(0xFFFFA000),
                                    iconBgColor: const Color(0xFFFFF8E1),
                                    subtitle:
                                        'Setiap jawaban\nmembawamu ke\nmasa depan yang\nlebih hijau!',
                                    maxWidth: 150,
                                  ),
                                ),
                                // Kartu hadiah kecil dekoratif kiri bawah.
                                Positioned(
                                  bottom: 8,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.07,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.card_giftcard,
                                      color: Color(0xFF43A047),
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _mapHeight(int count) => 140.0 + count * 116.0;

  /// Top tiap slot diukur dari bawah (slot 0 = paling bawah, untuk position 1).
  /// Layout klasik 5 node dipertahankan agar pas dengan jalur lukis;
  /// jumlah lain diratakan dinamis supaya tidak ter-clip di luar peta.
  List<double> _slotTops(int count) {
    if (count == 5) return const [600.0, 540.0, 372.0, 236.0, 96.0];
    final height = _mapHeight(count);
    if (count == 1) return [height - 200.0];
    final step = (height - 220.0) / (count - 1);
    return List.generate(count, (k) => height - 120.0 - k * step);
  }

  /// Slot zig-zag untuk tiap node (dari bawah ke atas).
  /// Hanya 1 node aktif berurutan (anti-loncat); kuota diteruskan ke
  /// bottom sheet agar tombol terkunci saat kuota habis.
  List<Widget> _buildNodeWidgets(
    BuildContext context,
    List<QuizNode> nodes,
    double w,
  ) {
    const leftFractions = [0.28, 0.52, 0.30, 0.55, 0.36, 0.45];
    final tops = _slotTops(nodes.length);
    final remainingQuota = _remainingQuota(nodes);
    final widgets = <Widget>[];
    for (var i = 0; i < nodes.length; i++) {
      // Node position kecil di bawah, besar di atas.
      final node = nodes[i];
      final top = tops[i];
      final left = w * leftFractions[i % leftFractions.length];
      final stage = _stageFor(node);
      if (stage.status == QuizStageStatus.active) {
        widgets.add(
          Positioned(
            top: top - 58,
            left: left - 20,
            child: const QuizActiveTooltip(),
          ),
        );
        widgets.add(
          Positioned(
            top: top,
            left: left,
            child: QuizStageNode(
              stage: stage,
              onTap: () => _onNodeTap(context, node, remainingQuota),
            ),
          ),
        );
      } else {
        widgets.add(
          Positioned(
            top: top,
            left: left,
            child: QuizStageNode(
              stage: stage,
              onTap: () => _onNodeTap(context, node, remainingQuota),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  /// Kartu hadiah jujur: XP 1 babak aktif hari ini (strict 1-terbuka).
  Widget _buildRewardCard(List<QuizNode> nodes) {
    final actives = nodes.where((n) => n.isPlayableToday && !n.isDone).toList();
    final shown = actives.isNotEmpty
        ? actives.take(1).toList()
        : nodes.take(1).toList();
    final xp = shown.fold<int>(0, (sum, n) => sum + n.xpReward);
    return QuizInfoCard(
      icon: Icons.flash_on,
      iconColor: const Color(0xFFFF8F00),
      iconBgColor: const Color(0xFFFFF3E0),
      title: 'Hadiah Hari Ini',
      titleHighlight: null,
      subtitle: '+$xp XP',
      maxWidth: 210,
    );
  }

  /// Strip status kuis hari ini: judul asli, +XP, badge selesai.
  Widget _buildDailyStatus(QuizState state) {
    if (state.status == QuizStatus.loading ||
        state.status == QuizStatus.initial) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFF43A047),
            ),
          ),
        ),
      );
    }

    if (state.status == QuizStatus.error && state.quiz == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.errorMessage ?? 'Gagal memuat kuis hari ini.',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () => context.read<QuizBloc>().add(
                const DailyQuizLoaded(force: true),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final quiz = state.quiz;
    if (quiz == null) return const SizedBox.shrink();

    final done = quiz.isCompletedToday;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? const Color(0xFF43A047) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: done ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_circle : Icons.quiz,
              color: done ? const Color(0xFF43A047) : const Color(0xFFFF8F00),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quiz.missionTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? 'Sudah selesai hari ini • Kembali besok'
                      : 'Kuis hari ini • +${quiz.xpReward} XP',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
