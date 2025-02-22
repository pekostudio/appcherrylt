import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  final Logger logger = Logger();
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _initConnectivity();
    _setupConnectivityStream();
  }

  Future<void> _initConnectivity() async {
    try {
      _isOnline = await _connectivityService.checkInternetConnection();
      logger.d(
          'Initial connectivity status: ${_isOnline ? 'Online' : 'Offline'}');
      notifyListeners();
    } catch (e) {
      logger.e('Error checking initial connectivity: $e');
      _isOnline = false;
      notifyListeners();
    }
  }

  void _setupConnectivityStream() {
    _connectivityService.connectivityStream.listen((ConnectivityResult result) {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;

      // Only notify if there's an actual change in connectivity
      if (wasOnline != _isOnline) {
        logger.d('Connectivity changed: ${_isOnline ? 'Online' : 'Offline'}');
        notifyListeners();
      }
    });
  }

  // Method to manually check connection
  Future<void> checkConnection() async {
    try {
      final isConnected = await _connectivityService.checkInternetConnection();
      if (_isOnline != isConnected) {
        _isOnline = isConnected;
        logger
            .d('Manual connection check: ${_isOnline ? 'Online' : 'Offline'}');
        notifyListeners();
      }
    } catch (e) {
      logger.e('Error during manual connection check: $e');
    }
  }
}
