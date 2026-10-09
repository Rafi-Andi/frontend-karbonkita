import 'package:flutter/material.dart';
import '../../../models/quiz_node.dart';
import '../../../models/quiz_stage.dart';
import '../../screens/quiz_gameplay_screen.dart';

/// Bottom sheet detail node saga.
/// Playable: tombol main ke gameplay sesi. Locked/completed: mode baca-saja
/// (lihat deskripsi, tombol disabled/tanpa navigasi main).
/// Bila kuota harian habis (remainingQuota <= 0), node locked dikunci
/// dengan pesan kuota habis.
class QuizStageBottomSheet extends StatelessWidget {
  final QuizStage stage;
  final QuizNode node;

  /// Sisa kuota main hari ini (2 node/hari). Default 2 agar kompatibel
  /// dengan pemanggil lama/test.
  final int remainingQuota;

  const QuizStageBottomSheet({
    super.key,
    required this.stage,
    required this.node,
    this.remainingQuota = 2,
  });

  @override
  Widget build(BuildContext context) {
    final completed = node.isDone;
    final quotaExhausted = remainingQuota <= 0;
    final playable = node.isPlayableToday && !completed && !quotaExhausted;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFF43A047),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble,
                          color: Colors.white,
                          size: 34,
                        ),
                        const Positioned(
                          top: 12,
                          child: Text(
                            '?',
                            style: TextStyle(
                              color: Color(0xFF43A047),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6D00),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              stage.tag,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                                color: Color(0xFFFF6D00),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stage.titleWithCount,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                stage.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _MetaChip(
                    icon: Icons.flash_on,
                    label: '+${node.xpReward} XP',
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.quiz,
                    label:
                        '${node.answeredToday}/${node.totalQuestions > 0 ? node.totalQuestions : node.quizzesCount} terjawab',
                  ),
                  const SizedBox(width: 8),
                  _MetaChip(
                    icon: Icons.bolt,
                    label: 'Sisa $remainingQuota/2 hari ini',
                  ),
                ],
              ),
              if (quotaExhausted && !completed) ...[
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.info_outline, size: 14, color: Colors.black54),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Kuota 2x main hari ini habis — kembali besok.',
                        style: TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: playable
                      ? () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuizGameplayScreen(
                                missionId: node.id,
                                nodeTitle: node.title,
                                totalXp: node.xpReward,
                              ),
                            ),
                          );
                        }
                      : completed
                      ? () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => QuizGameplayScreen(
                                missionId: node.id,
                                nodeTitle: node.title,
                                totalXp: node.xpReward,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        completed
                            ? Icons.visibility
                            : playable
                            ? Icons.play_arrow
                            : Icons.lock,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        completed
                            ? 'Lihat Hasil'
                            : playable
                            ? 'Mulai Tantangan'
                            : quotaExhausted
                            ? 'Kuota habis — kembali besok'
                            : 'Terkunci — selesaikan babak sebelumnya',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF43A047)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
