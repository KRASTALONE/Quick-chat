import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  final Dio _dio = Dio();

  Future<String> downloadFile({
    required String url,
    String? fileName,
  }) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final downloadDirectory = Directory(
      path.join(documentsDirectory.path, 'downloads'),
    );

    if (!downloadDirectory.existsSync()) {
      downloadDirectory.createSync(recursive: true);
    }

    final resolvedFileName = fileName?.trim().isNotEmpty == true
        ? fileName!.trim()
        : _fileNameFromUrl(url);

    final filePath = path.join(downloadDirectory.path, resolvedFileName);
    await _dio.download(url, filePath);
    return filePath;
  }

  String _fileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    final lastSegment = (uri != null && uri.pathSegments.isNotEmpty)
        ? uri.pathSegments.last
        : 'downloaded_file';

    final safeFileName = lastSegment.split('?').first;
    if (safeFileName.contains('.')) {
      return safeFileName;
    }

    return 'chat_file_${DateTime.now().millisecondsSinceEpoch}';
  }
}
