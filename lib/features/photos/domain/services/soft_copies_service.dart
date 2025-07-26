import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photocafe_windows/core/handlers/dio_handler.dart';
import 'package:uuid/uuid.dart';

class SoftCopiesService {
  final Dio _dio = DioClient().instance;
  final _uuid = Uuid();

  Future<SoftCopiesUploadResult> uploadMediaFiles({
    required List<File> mediaFiles,
    required String? processedVideoPath, // Only the VHS processed video
    required Function(double) onProgress,
  }) async {
    try {
      onProgress(0.0);

      final archiveId = _uuid.v4();
      final formData = FormData();

      // Add archive ID
      formData.fields.add(MapEntry('archiveId', archiveId));

      double currentProgress = 0.1;
      final progressPerFile =
          0.8 / (mediaFiles.length + (processedVideoPath != null ? 1 : 0));

      // Add photo files
      for (int i = 0; i < mediaFiles.length; i++) {
        final file = mediaFiles[i];
        final fileName = 'photo_${i + 1}.${_getFileExtension(file.path)}';

        final multipartFile = await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        );

        formData.files.add(MapEntry('files', multipartFile));

        currentProgress += progressPerFile;
        onProgress(currentProgress);
      }

      // Add processed video if available (only VHS filtered version)
      if (processedVideoPath != null) {
        final videoFile = File(processedVideoPath);
        if (await videoFile.exists()) {
          print('Uploading VHS processed video: $processedVideoPath');

          final multipartFile = await MultipartFile.fromFile(
            processedVideoPath,
            filename:
                'session_video_vhs.mp4', // Clear naming for processed video
          );

          formData.files.add(MapEntry('files', multipartFile));
          currentProgress += progressPerFile;
          onProgress(currentProgress);
        } else {
          print(
            'Warning: Processed video file not found at: $processedVideoPath',
          );
        }
      }

      onProgress(0.9);

      // Upload to server using the correct route
      final response = await _dio.post(
        '/api/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        onSendProgress: (sent, total) {
          // Additional progress tracking for upload
          final uploadProgress = 0.9 + (sent / total) * 0.1;
          onProgress(uploadProgress);
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final responseArchiveId = data['archiveId'] ?? archiveId;

        return SoftCopiesUploadResult(
          success: true,
          archiveId: responseArchiveId,
          downloadUrl: _generateArchiveUrl(responseArchiveId),
          uploadedFiles: List<String>.from(
            (data['files'] as List).map((file) => file['fileName']),
          ),
        );
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'Network error occurred';

      if (e.response != null) {
        errorMessage =
            'Upload failed: ${e.response?.statusCode} - ${e.response?.data}';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage =
            'Connection timeout - please check your internet connection';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Upload timeout - files may be too large';
      }

      return SoftCopiesUploadResult(success: false, error: errorMessage);
    } catch (e) {
      return SoftCopiesUploadResult(success: false, error: e.toString());
    }
  }

  String _getFileExtension(String filePath) {
    return filePath.split('.').last.toLowerCase();
  }

  String _generateArchiveUrl(String archiveId) {
    // Generate the archive URL that points to the Next.js page
    final baseUrl = dotenv.env['WEB_URL'] ?? _dio.options.baseUrl;
    return '$baseUrl/archive/$archiveId';
  }

  Future<bool> verifyArchiveExists(String archiveId) async {
    try {
      final response = await _dio.get('/api/retrieve/$archiveId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

class SoftCopiesUploadResult {
  final bool success;
  final String? archiveId;
  final String? downloadUrl;
  final List<String>? uploadedFiles;
  final String? error;

  SoftCopiesUploadResult({
    required this.success,
    this.archiveId,
    this.downloadUrl,
    this.uploadedFiles,
    this.error,
  });

  @override
  String toString() {
    if (success) {
      return 'Upload successful: $archiveId (${uploadedFiles?.length ?? 0} files)';
    } else {
      return 'Upload failed: $error';
    }
  }
}
