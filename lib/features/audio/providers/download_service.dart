import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class DownloadService {
  final Dio _dio = Dio();
  final Logger logger = Logger();

  Future<void> downloadFile(
      String url, String fileName, String accessToken, int playlistId) async {
    var status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception("Storage permission not granted");
    }

    Directory? directory;
    if (Platform.isAndroid) {
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory == null) {
      throw Exception("Could not get the storage directory");
    }

    // Create a subfolder for the playlist using playlistId
    Directory playlistDir = Directory('${directory.path}/$playlistId');
    if (!await playlistDir.exists()) {
      await playlistDir.create(recursive: true);
    }

    String filePath = "${playlistDir.path}/$fileName";

    try {
      String urlWithToken = "$url?access_token=$accessToken";
      await _dio.download(
        urlWithToken,
        filePath,
        options: Options(
          headers: {
            'Authorization':
                'Basic YXBwOnd5cWQ3eWdqbmpvOXVyaGdmem5yYmc4amI3OGI3bWZ1',
          },
        ),
      );
      logger.d("File downloaded to $filePath");
    } catch (e) {
      logger.d("Error downloading file: $e");
      rethrow;
    }
  }
}
