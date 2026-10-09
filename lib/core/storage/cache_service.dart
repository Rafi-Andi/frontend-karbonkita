import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Cache offline read-only untuk semua data yang sudah diload.
///
/// - Disimpan sebagai JSON string: `{"saved_at": iso, "payload": ...}`.
/// - Tanpa kadaluarsa: `readPayload` selalu mengembalikan data terakhir.
/// - Aman untuk unit test: bila Hive box belum dibuka, fallback ke memori.
class CacheService {
  CacheService({Box<String>? box}) : _box = box;

  static const String boxName = 'karbon_cache';

  Box<String>? _box;
  final Map<String, String> _memory = {};

  /// Wajib dipanggil sekali di `main()` sebelum `runApp`.
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box ??= await Hive.openBox<String>(boxName);
    } catch (_) {
      // Fallback memori (mis. test / platform tanpa path provider).
      _box = null;
    }
  }

  /// Untuk test: inject box/memory tanpa init().
  void setBoxForTest(Box<String>? box) => _box = box;

  // ---------- primitif ----------

  String? _readRaw(String key) {
    final box = _box;
    if (box != null) {
      try {
        return box.get(key) ?? _memory[key];
      } catch (_) {
        return _memory[key];
      }
    }
    return _memory[key];
  }

  Future<void> _writeRaw(String key, String raw) async {
    _memory[key] = raw;
    final box = _box;
    if (box != null) {
      try {
        await box.put(key, raw);
      } catch (_) {
        // Abaikan: memori tetap terisi.
      }
    }
  }

  /// Tulis payload Map/List + cap waktu simpan.
  Future<void> writeJson(String key, Object payload) async {
    final raw = jsonEncode({
      'saved_at': DateTime.now().toIso8601String(),
      'payload': payload,
    });
    await _writeRaw(key, raw);
  }

  /// Baca payload mentah (Map atau List) atau null bila belum ada/rusak.
  dynamic readPayload(String key) {
    final raw = _readRaw(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded['payload'];
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? readMap(String key) {
    final payload = readPayload(key);
    return payload is Map<String, dynamic> ? payload : null;
  }

  List<dynamic>? readList(String key) {
    final payload = readPayload(key);
    return payload is List ? payload : null;
  }

  /// Kapan key terakhir disimpan (untuk label "terakhir diperbarui").
  DateTime? lastUpdated(String key) {
    final raw = _readRaw(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      final saved = (decoded as Map)['saved_at'];
      return saved is String ? DateTime.tryParse(saved) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    _memory.remove(key);
    try {
      await _box?.delete(key);
    } catch (_) {}
  }

  /// Hapus seluruh cache (dipanggil saat logout agar ganti user bersih).
  Future<void> clearAll() async {
    _memory.clear();
    try {
      await _box?.clear();
    } catch (_) {}
  }
}
