import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final Logger logger = Logger();

  Future<bool> checkInternetConnection() async {
    try {
      // First check connectivity status
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        logger.d('No connectivity detected');
        return false;
      }

      // Then verify actual internet connection by trying to reach a reliable host
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          logger.d('Internet connection verified');
          return true;
        }
      } on SocketException catch (e) {
        logger.d('No internet connection (Socket check failed): $e');
        return false;
      }

      logger.d('No internet connection (Lookup failed)');
      return false;
    } catch (e) {
      logger.e('Error checking internet connection: $e');
      return false;
    }
  }

  Stream<ConnectivityResult> get connectivityStream =>
      _connectivity.onConnectivityChanged;
}
