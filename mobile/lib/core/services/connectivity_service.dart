import 'package:connectivity_plus/connectivity_plus.dart';

/// Normalizes connectivity_plus results into a simple online/offline signal.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return _isOnline(result);
  }

  bool _isOnline(List<ConnectivityResult> result) =>
      result.any((r) => r != ConnectivityResult.none);
}
