import '../../core/network/auth_exception.dart';
import '../../core/network/mission_exception.dart';
import '../../core/storage/cache_keys.dart';
import '../../core/storage/cache_service.dart';
import '../../core/storage/token_storage.dart';
import '../datasources/mission_remote_datasource.dart';
import '../../models/daily_quiz.dart';
import '../../models/mission.dart';
import '../../models/verify_waste_result.dart';
import '../../models/quiz_node.dart';
import '../../models/quiz_session.dart';

/// Orkestrasi data mission + cache offline read-only.
class MissionRepository {
  MissionRepository(this._remote, {CacheService? cache, TokenStorage? storage})
    : _cache = cache,
      _storage = storage;

  final MissionRemoteDatasource _remote;
  final CacheService? _cache;
  final TokenStorage? _storage;

  Future<String> _uid() async {
    try {
      final user = await _storage?.readUser();
      if (user != null) return user.id.toString();
    } catch (_) {}
    return 'guest';
  }

  // ---------- misi aktif ----------

  /// Ambil misi aktif (mobility + waste) dari backend.
  Future<List<Mission>> getActiveMissions() async {
    try {
      final result = await _remote.fetchActiveMissions();
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(
          CacheKeys.missionsActive(await _uid()),
          result.map((m) => m.toJson()).toList(),
        );
      }
      return result;
    } on MissionException {
      rethrow;
    } catch (e) {
      throw MissionException('Gagal memuat misi aktif: $e');
    }
  }

  Future<({List<Mission> missions, DateTime? savedAt})>
  getCachedActiveMissions() async {
    final cache = _cache;
    if (cache == null) return (missions: const <Mission>[], savedAt: null);
    final key = CacheKeys.missionsActive(await _uid());
    final raw =
        cache.readList(key) ??
        cache.readList(CacheKeys.missionsActive('guest'));
    if (raw == null) return (missions: const <Mission>[], savedAt: null);
    try {
      return (
        missions: raw
            .whereType<Map<String, dynamic>>()
            .map(Mission.fromJson)
            .toList(),
        savedAt: cache.lastUpdated(key),
      );
    } catch (_) {
      return (missions: const <Mission>[], savedAt: null);
    }
  }

  // ---------- saga quizzes ----------

  /// Ambil kuis harian (Saga Map) dari backend.
  Future<List<Mission>> getSagaQuizzes() async {
    try {
      final result = await _remote.fetchSagaQuizzes();
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(
          CacheKeys.sagaQuizzes(await _uid()),
          result.map((m) => m.toJson()).toList(),
        );
      }
      return result;
    } on MissionException {
      rethrow;
    } catch (e) {
      throw MissionException('Gagal memuat kuis harian: $e');
    }
  }

  Future<List<Mission>> getCachedSagaQuizzes() async {
    final cache = _cache;
    if (cache == null) return const [];
    final key = CacheKeys.sagaQuizzes(await _uid());
    final raw =
        cache.readList(key) ?? cache.readList(CacheKeys.sagaQuizzes('guest'));
    if (raw == null) return const [];
    try {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(Mission.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ---------- saga nodes ----------

  /// Ambil daftar node peta Saga dari backend.
  Future<List<QuizNode>> getSagaNodes() async {
    try {
      final result = await _remote.fetchSagaNodes();
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(
          CacheKeys.sagaNodes(await _uid()),
          result.map((n) => n.toJson()).toList(),
        );
      }
      return result;
    } on MissionException {
      rethrow;
    } on AuthException catch (e) {
      throw MissionException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
        data: e.data,
      );
    } catch (e) {
      throw MissionException('Gagal memuat node saga: $e');
    }
  }

  Future<({List<QuizNode> nodes, DateTime? savedAt})>
  getCachedSagaNodes() async {
    final cache = _cache;
    if (cache == null) return (nodes: const <QuizNode>[], savedAt: null);
    final key = CacheKeys.sagaNodes(await _uid());
    final raw =
        cache.readList(key) ?? cache.readList(CacheKeys.sagaNodes('guest'));
    if (raw == null) return (nodes: const <QuizNode>[], savedAt: null);
    try {
      return (
        nodes: raw
            .whereType<Map<String, dynamic>>()
            .map(QuizNode.fromJson)
            .toList(),
        savedAt: cache.lastUpdated(key),
      );
    } catch (_) {
      return (nodes: const <QuizNode>[], savedAt: null);
    }
  }

  // ---------- sesi node ----------

  /// Ambil sesi soal 1 node dari backend.
  Future<QuizSession> getNodeQuestions(int missionId) async {
    try {
      final result = await _remote.fetchNodeQuestions(missionId);
      final cache = _cache;
      if (cache != null) {
        await cache.writeJson(
          CacheKeys.sagaSession(missionId),
          result.toJson(),
        );
      }
      return result;
    } on MissionException {
      rethrow;
    } on AuthException catch (e) {
      throw MissionException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
        data: e.data,
      );
    } catch (e) {
      throw MissionException('Gagal memuat soal sesi: $e');
    }
  }

  Future<QuizSession?> getCachedNodeQuestions(int missionId) async {
    final map = _cache?.readMap(CacheKeys.sagaSession(missionId));
    if (map == null) return null;
    try {
      return QuizSession.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // ---------- daily quiz ----------

  /// Ambil kuis harian (typed) dari backend.
  Future<DailyQuiz> getDailyQuiz() async {
    try {
      final result = await _remote.fetchDailyQuiz();
      final cache = _cache;
      if (cache != null) {
        final date = DateTime.now().toIso8601String().substring(0, 10);
        await cache.writeJson(CacheKeys.dailyQuiz(date), result.toJson());
        // Simpan juga key umum agar offline lintas hari tetap ada fallback.
        await cache.writeJson(CacheKeys.dailyQuiz('latest'), result.toJson());
      }
      return result;
    } on MissionException {
      rethrow;
    } on AuthException catch (e) {
      // Dio melempar AuthException langsung — pertahankan statusCode (401).
      throw MissionException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
        data: e.data,
      );
    } catch (e) {
      throw MissionException('Gagal memuat kuis harian: $e');
    }
  }

  Future<DailyQuiz?> getCachedDailyQuiz() async {
    final cache = _cache;
    if (cache == null) return null;
    final date = DateTime.now().toIso8601String().substring(0, 10);
    final map =
        cache.readMap(CacheKeys.dailyQuiz(date)) ??
        cache.readMap(CacheKeys.dailyQuiz('latest'));
    if (map == null) return null;
    try {
      return DailyQuiz.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Submit jawaban kuis (typed). 409/401 diteruskan dengan statusCode.
  Future<QuizAnswerResult> answerQuiz({
    required int quizId,
    required String answer,
  }) async {
    try {
      return await _remote.answerQuiz(quizId: quizId, answer: answer);
    } on MissionException {
      rethrow;
    } on AuthException catch (e) {
      throw MissionException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
        data: e.data,
      );
    } catch (e) {
      throw MissionException('Gagal submit jawaban kuis: $e');
    }
  }

  /// Verifikasi foto sampah via AI (multipart upload).
  /// Return [VerifyWasteResult] dari `data` envelope 200/201.
  /// 409 duplicate / 409 daily-cap / 503 / 422 diteruskan sebagai
  /// [MissionException] lengkap dengan `statusCode` + `data` backend
  /// agar Bloc bisa menampilkan dialog yang tepat.
  Future<VerifyWasteResult> verifyWaste({
    required int missionId,
    required String imagePath,
  }) async {
    try {
      final envelope = await _remote.verifyWaste(
        missionId: missionId,
        imagePath: imagePath,
      );
      final data = envelope['data'];
      if (data is Map<String, dynamic>) {
        return VerifyWasteResult.fromJson(data);
      }
      throw const MissionException('Format hasil verifikasi tidak dikenali.');
    } on MissionException {
      rethrow;
    } on AuthException catch (e) {
      throw MissionException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
        data: e.data,
      );
    } catch (e) {
      throw MissionException('Gagal verifikasi sampah: $e');
    }
  }

  /// Sinkronisasi aktivitas mobilitas.
  Future<Map<String, dynamic>> syncMobility({
    int? missionId,
    required String activityType,
    required double distanceKm,
    required int durationSeconds,
    required List<Map<String, double>> gpsCoordinatesPath,
  }) async {
    try {
      return await _remote.mobilitySync(
        missionId: missionId,
        activityType: activityType,
        distanceKm: distanceKm,
        durationSeconds: durationSeconds,
        gpsCoordinatesPath: gpsCoordinatesPath,
      );
    } on MissionException {
      rethrow;
    } on AuthException catch (e) {
      throw MissionException(
        e.message,
        errors: e.errors,
        statusCode: e.statusCode,
        data: e.data,
      );
    } catch (e) {
      throw MissionException('Gagal sinkronisasi mobilitas: $e');
    }
  }

  /// Submit jawaban kuis.
  Future<Map<String, dynamic>> submitQuizAnswer({
    required int quizId,
    required String answer,
  }) async {
    try {
      return await _remote.submitQuizAnswer(quizId: quizId, answer: answer);
    } on MissionException {
      rethrow;
    } catch (e) {
      throw MissionException('Gagal submit jawaban kuis: $e');
    }
  }
}
