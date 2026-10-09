import 'package:connectivity_plus/connectivity_plus.dart';

/// Status koneksi untuk banner offline + penanda "data offline".
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Cek sekali: true bila ada koneksi (wifi/mobile/ethernet).
  Future<bool> get isOnline async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((r) => r != ConnectivityResult.none);
    } catch (_) {
      return true;
    }
  }

  /// Stream status online/offline untuk banner.
  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged.map(
    (results) => results.any((r) => r != ConnectivityResult.none),
  );
}
