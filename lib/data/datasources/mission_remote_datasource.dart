import '../../core/network/api_endpoints.dart';
import '../../core/network/dio_client.dart';
import '../../models/daily_quiz.dart';
import '../../models/mission.dart';
import '../../models/quiz_node.dart';
import '../../models/quiz_session.dart';

/// Akses mentah ke endpoint mission backend.
class MissionRemoteDatasource {
  MissionRemoteDatasource(this._client);

  final DioClient _client;

  /// GET /api/missions/active
  /// Return list mission mobility & waste yang aktif.
  Future<List<Mission>> fetchActiveMissions() async {
    final envelope = await _client.get(ApiEndpoints.missionsActive);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Mission.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar misi tidak dikenali.');
  }

  /// GET /api/saga/quizzes
  /// Return kuis harian (Saga Map) - backend mengembalikan 1 quiz object.
  Future<DailyQuiz> fetchDailyQuiz() async {
    final envelope = await _client.get(ApiEndpoints.sagaQuizzes);
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return DailyQuiz.fromJson(data);
    }
    throw const FormatException('Format kuis harian tidak dikenali.');
  }

  /// GET /api/saga/nodes
  /// Return daftar node peta Saga (1 node = 1 misi quiz).
  Future<List<QuizNode>> fetchSagaNodes() async {
    final envelope = await _client.get(ApiEndpoints.sagaNodes);
    final data = envelope['data'];
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(QuizNode.fromJson)
          .toList();
    }
    throw const FormatException('Format daftar node saga tidak dikenali.');
  }

  /// GET /api/saga/nodes/{id}/questions
  /// Return sesi 5 soal hari ini untuk 1 node playable.
  Future<QuizSession> fetchNodeQuestions(int missionId) async {
    final envelope = await _client.get(
      ApiEndpoints.sagaNodeQuestions(missionId),
    );
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return QuizSession.fromJson(data);
    }
    throw const FormatException('Format sesi kuis tidak dikenali.');
  }

  /// GET /api/saga/quizzes (delegasi)
  /// Representasi ringkas untuk daftar misi tab Misi.
  Future<List<Mission>> fetchSagaQuizzes() async {
    final quiz = await fetchDailyQuiz();
    return [quiz.toMission()];
  }

  /// POST /api/missions/verify-waste
  /// Upload foto untuk validasi AI sampah (multipart: mission_id + image).
  /// Return envelope mentah; 409/422/503 diteruskan sebagai exception
  /// dengan `data` payload dari backend.
  Future<Map<String, dynamic>> verifyWaste({
    required int missionId,
    required String imagePath,
  }) async {
    final envelope = await _client.postMultipart(
      ApiEndpoints.verifyWaste,
      fields: <String, dynamic>{'mission_id': missionId},
      filePath: imagePath,
      fileField: 'image',
    );
    return envelope;
  }

  /// POST /api/missions/mobility-sync
  /// Sinkronisasi data mobilitas (GPS, jarak, durasi).
  Future<Map<String, dynamic>> mobilitySync({
    int? missionId,
    required String activityType, // 'cycling' | 'walking' | 'running'
    required double distanceKm,
    required int durationSeconds,
    required List<Map<String, double>> gpsCoordinatesPath,
  }) async {
    final body = <String, dynamic>{
      'activity_type': activityType,
      'distance_km': distanceKm,
      'duration_seconds': durationSeconds,
      'gps_coordinates_path': gpsCoordinatesPath,
    };
    if (missionId != null) body['mission_id'] = missionId;
    final envelope = await _client.post(ApiEndpoints.mobilitySync, body);
    return envelope;
  }

  /// POST /api/saga/answer
  /// Submit jawaban kuis. Return envelope mentah (dipakai MissionBloc lama).
  Future<Map<String, dynamic>> submitQuizAnswer({
    required int quizId,
    required String answer,
  }) async {
    final envelope = await _client.post(ApiEndpoints.sagaAnswer, {
      'quiz_id': quizId,
      'answer': answer,
    });
    return envelope;
  }

  /// POST /api/saga/answer (typed)
  /// Return hasil benar/salah + reward. 409/401 diteruskan sebagai exception.
  Future<QuizAnswerResult> answerQuiz({
    required int quizId,
    required String answer,
  }) async {
    final envelope = await _client.post(ApiEndpoints.sagaAnswer, {
      'quiz_id': quizId,
      'answer': answer.toUpperCase(),
    });
    final data = envelope['data'];
    if (data is Map<String, dynamic>) {
      return QuizAnswerResult.fromJson(data);
    }
    throw const FormatException('Format hasil kuis tidak dikenali.');
  }
}
