import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';

class DownloadService {
  final Dio _dio = Dio();
  final Logger logger = Logger();

  Future<void> downloadFile(
      String url, String fileName, String accessToken, int playlistId) async {
    try {
      logger.d(
          'Starting download process for file: $fileName (Playlist ID: $playlistId)');
      logger.d('URL: $url');

      // Check Android version and request appropriate permissions
      if (Platform.isAndroid) {
        final isAndroid13Plus = await _isAndroid13OrHigher();
        logger.d('Android 13 or higher: $isAndroid13Plus');

        if (isAndroid13Plus) {
          logger.d('Checking current audio permission status');
          var currentStatus = await Permission.audio.status;
          logger.d('Current audio permission status: $currentStatus');

          if (!currentStatus.isGranted) {
            logger.d('Requesting audio permission for Android 13+');
            var audioStatus = await Permission.audio.request();
            logger.d('Audio permission request result: $audioStatus');

            if (!audioStatus.isGranted) {
              logger.e('Audio permission not granted. Status: $audioStatus');
              throw Exception(
                  "Audio permission required to download tracks. Please grant permission in settings.");
            }
          } else {
            logger.d('Audio permission already granted');
          }
        } else {
          logger.d('Checking current storage permission status');
          var currentStatus = await Permission.storage.status;
          logger.d('Current storage permission status: $currentStatus');

          if (!currentStatus.isGranted) {
            logger.d('Requesting storage permission for Android 12 or below');
            var storageStatus = await Permission.storage.request();
            logger.d('Storage permission request result: $storageStatus');

            if (!storageStatus.isGranted) {
              logger
                  .e('Storage permission not granted. Status: $storageStatus');
              throw Exception(
                  "Storage permission required to download tracks. Please grant permission in settings.");
            }
          } else {
            logger.d('Storage permission already granted');
          }
        }
      }

      logger.d('Getting application documents directory');
      final directory = await getApplicationDocumentsDirectory();
      logger.d('App storage directory path: ${directory.path}');

      // Verify directory is writable
      try {
        final testFile = File('${directory.path}/test_write');
        await testFile.writeAsString('test');
        await testFile.delete();
        logger.d('Verified directory is writable');
      } catch (e) {
        logger.e('Directory is not writable: $e');
        throw Exception("Cannot write to storage directory");
      }

      // Create a subfolder for the playlist
      final playlistDir = Directory('${directory.path}/$playlistId');
      if (!await playlistDir.exists()) {
        logger.d('Creating playlist directory: ${playlistDir.path}');
        await playlistDir.create(recursive: true);
        logger.d('Successfully created playlist directory');
      } else {
        logger.d('Playlist directory already exists');
      }

      final filePath = "${playlistDir.path}/$fileName";
      logger.d('Target download path: $filePath');

      // Check if file already exists
      final existingFile = File(filePath);
      if (await existingFile.exists()) {
        logger.d('File already exists, deleting old version');
        await existingFile.delete();
      }

      try {
        String urlWithToken = "$url?access_token=$accessToken";
        logger.d('Starting file download');

        final response = await _dio.download(
          urlWithToken,
          filePath,
          options: Options(
            headers: {
              'Authorization':
                  'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
            },
            followRedirects: true,
            validateStatus: (status) {
              logger.d('Response status code: $status');
              return status != null && status < 500;
            },
          ),
          onReceiveProgress: (received, total) {
            if (total != -1) {
              final progress = (received / total * 100).toStringAsFixed(1);
              logger
                  .d('Download progress: $progress% ($received/$total bytes)');
            }
          },
        );

        logger.d('Download completed. Response status: ${response.statusCode}');

        // Verify file was downloaded
        final file = File(filePath);
        if (await file.exists()) {
          final size = await file.length();
          logger.d('File exists at path with size: $size bytes');

          // Verify file is readable
          try {
            final bytes = await file.readAsBytes();
            logger.d('Successfully read ${bytes.length} bytes from file');

            if (bytes.isEmpty) {
              logger.e('File exists but is empty');
              throw Exception("Downloaded file is empty");
            }
          } catch (e) {
            logger.e('File exists but is not readable: $e');
            throw Exception("Downloaded file is not readable: $e");
          }
        } else {
          logger.e(
              'File download failed - file does not exist at path: $filePath');
          throw Exception(
              "File download failed - file not created at: $filePath");
        }
      } catch (e) {
        logger.e('Error during file download: $e');
        rethrow;
      }
    } catch (e) {
      logger.e('Error in downloadFile: $e');
      rethrow;
    }
  }

  Future<bool> _isAndroid13OrHigher() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        logger.d('Android SDK version: $sdkInt');
        return sdkInt >= 33;
      }
      return false;
    } catch (e) {
      logger.e('Error checking Android version: $e');
      return false;
    }
  }
}
