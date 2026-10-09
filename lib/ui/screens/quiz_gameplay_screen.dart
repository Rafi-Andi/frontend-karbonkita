import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/auth/auth_bloc.dart';
import '../../../bloc/auth/auth_event.dart';
import '../../../bloc/quiz/quiz_bloc.dart';
import '../../../bloc/quiz/quiz_event.dart';
import '../../../bloc/quiz/quiz_state.dart';
import '../../../models/daily_quiz.dart';
import '../../../models/quiz_session.dart';
import '../widgets/quiz/quiz_answer_option.dart';
import '../widgets/quiz/quiz_feedback_card.dart';
import '../widgets/quiz/quiz_progress_segments.dart';

/// Halaman gameplay sesi 1 node: 5 soal berurutan dari backend.
/// Benar = +XP lanjut; salah = hangus (0 XP) lanjut. Tanpa retry.
class QuizGameplayScreen extends StatefulWidget {
  final int missionId;
  final String nodeTitle;
  final int totalXp;

  const QuizGameplayScreen({
    super.key,
    required this.missionId,
    required this.nodeTitle,
    required this.totalXp,
  });

  @override
  State<QuizGameplayScreen> createState() => _QuizGameplayScreenState();
}

class _QuizGameplayScreenState extends State<QuizGameplayScreen> {
  String? _selectedLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<QuizBloc>().add(NodeSessionLoaded(widget.missionId));
      }
    });
  }

  void _submit() {
    final label = _selectedLabel;
    if (label == null) return;
    context.read<QuizBloc>().add(QuizAnswered(label));
  }

  void _next() {
    setState(() => _selectedLabel = null);
    context.read<QuizBloc>().add(const SessionQuestionNext());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<QuizBloc, QuizState>(
        listenWhen: (prev, curr) =>
            (!prev.isUnauthorized && curr.isUnauthorized) ||
            (prev.sessionErrorMessage != curr.sessionErrorMessage &&
                curr.sessionErrorMessage != null) ||
            (prev.errorMessage != curr.errorMessage &&
                curr.errorMessage != null) ||
            prev.lastResult != curr.lastResult,
        listener: (context, state) {
          if (state.isUnauthorized) {
            context.read<AuthBloc>().add(const LoggedOut());
          } else if (state.sessionErrorMessage != null &&
              state.session == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.sessionErrorMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.errorMessage != null && state.lastResult == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state.lastResult == null) {
            setState(() => _selectedLabel = null);
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/backgroundkuis.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: const Color(0xFFF2F7F0)),
              ),
            ),
            SafeArea(
              child: BlocBuilder<QuizBloc, QuizState>(
                builder: (context, state) {
                  final session = state.session;
                  final isBusy = state.status == QuizStatus.answering;

                  if ((state.sessionStatus == SessionStatus.loading ||
                          state.sessionStatus == SessionStatus.initial) &&
                      session == null) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF43A047),
                      ),
                    );
                  }

                  if (state.sessionStatus == SessionStatus.error &&
                      session == null) {
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
                              state.sessionErrorMessage ?? 'Gagal memuat soal.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context.read<QuizBloc>().add(
                                NodeSessionLoaded(
                                  widget.missionId,
                                  force: true,
                                ),
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

                  if (session == null) {
                    return const SizedBox.shrink();
                  }

                  // Sesi selesai (semua terjawab) -> ringkasan.
                  if (session.isFinished && state.lastResult == null) {
                    return _buildSummary(context, session);
                  }

                  final idx = state.sessionIndex.clamp(
                    0,
                    session.questions.length - 1,
                  );
                  final question = session.questions[idx];
                  final result = state.lastResult;

                  return _buildQuestion(
                    context,
                    session: session,
                    index: idx,
                    question: question,
                    result: result,
                    isBusy: isBusy,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestion(
    BuildContext context, {
    required QuizSession session,
    required int index,
    required DailyQuiz question,
    required QuizAnswerResult? result,
    required bool isBusy,
  }) {
    final answered = question.isCompletedToday;
    final justAnswered = result != null;
    final locked = isBusy || answered || justAnswered;
    final revealed = answered ? question.correctAnswer : null;
    final answeredCount = session.questions
        .where((q) => q.isCompletedToday)
        .length;
    final wrongIndexes = {
      for (var i = 0; i < session.questions.length; i++)
        if (session.questions[i].wasCorrect == false) i,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _buildHeader(session, index),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: QuizProgressSegments(
            total: session.questions.length,
            answeredCount: answeredCount,
            currentIndex: index,
            incorrectIndexes: wrongIndexes,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF43A047),
                            width: 2,
                          ),
                          color: const Color(0xFFE8F5E9),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF43A047),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.question,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(question.options.length, (i) {
                    final opt = question.options[i];
                    final isRevealed =
                        revealed != null && opt.label == revealed;
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: i == question.options.length - 1 ? 0 : 10,
                      ),
                      child: QuizAnswerOptionTile(
                        option: opt,
                        selected: isRevealed || _selectedLabel == opt.label,
                        locked: locked,
                        onTap: () => setState(() => _selectedLabel = opt.label),
                      ),
                    );
                  }),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _buildFeedback(question: question, result: result),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildBottomBar(
          isBusy: isBusy,
          hasResult: result != null,
          canSubmit:
              !isBusy && !justAnswered && !answered && _selectedLabel != null,
        ),
      ],
    );
  }

  Widget _buildHeader(QuizSession session, int index) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.nodeTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Soal ${index + 1} dari ${session.questions.length}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_on, color: Color(0xFF43A047), size: 16),
              const SizedBox(width: 4),
              Text(
                '+${session.xpPerQuestion} XP',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeedback({
    required DailyQuiz question,
    required QuizAnswerResult? result,
  }) {
    if (result == null) return const SizedBox.shrink();
    if (result.isCorrect) {
      final explanation = question.explanation;
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: QuizFeedbackCard(
          key: const ValueKey('feedback_correct'),
          variant: QuizFeedbackVariant.correct,
          title: 'Benar! +${result.xpEarned} XP',
          explanation: (explanation == null || explanation.isEmpty)
              ? 'Lanjut ke soal berikutnya!'
              : explanation,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: QuizFeedbackCard(
        key: ValueKey('feedback_wrong_${result.userMissionId}'),
        variant: QuizFeedbackVariant.incorrect,
        title: 'Soal Hangus!',
        explanation:
            'Jawaban belum tepat dan soal ini tidak bisa diulang hari ini. Lanjut ke soal berikutnya!',
      ),
    );
  }

  Widget _buildBottomBar({
    required bool isBusy,
    required bool hasResult,
    required bool canSubmit,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: hasResult
              ? _next
              : canSubmit
              ? _submit
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isBusy)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Text(
                  hasResult ? 'Lanjut' : 'Kirim Jawaban',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, QuizSession session) {
    final correct = session.questions.where((q) => q.wasCorrect == true).length;
    final wrong = session.questions.where((q) => q.wasCorrect == false).length;
    final xp = correct * session.xpPerQuestion;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: _buildHeader(session, session.questions.length - 1),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Color(0xFFFF8F00),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Babak Selesai!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$correct dari ${session.questions.length} benar',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  if (wrong > 0)
                    Text(
                      '$wrong soal hangus',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFEF6C00),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '+$xp XP',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kembali besok untuk babak baru!',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
