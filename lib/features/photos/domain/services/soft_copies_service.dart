import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photocafe_windows/core/handlers/dio_handler.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';

class SoftCopiesService {
  final Dio _dio = DioClient().instance;
  final _uuid = Uuid();

  Future<SoftCopiesUploadResult> uploadMediaFiles({
    required List<File> mediaFiles,
    required String? processedVideoPath, // Only the VHS processed video
    Uint8List? pdfBytes,
    bool allowSocialMediaPosting = false,
    required Function(double) onProgress,
  }) async {
    try {
      onProgress(0.0);

      final archiveId = _uuid.v4();
      final formData = FormData();

      // Add archive ID
      formData.fields.add(MapEntry('archiveId', archiveId));

      // Add social media consent flag
      formData.fields.add(
        MapEntry('allowSocialMediaPosting', allowSocialMediaPosting.toString()),
      );

      double currentProgress = 0.1;
      final totalFiles =
          mediaFiles.length +
          (processedVideoPath != null ? 1 : 0) +
          (pdfBytes != null ? 1 : 0) +
          (allowSocialMediaPosting ? 1 : 0); // +1 for consent document
      final progressPerFile = totalFiles > 0 ? 0.8 / totalFiles : 0.8;

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

      // Convert PDF to high-quality PNG and upload
      if (pdfBytes != null) {
        print('Converting photostrip PDF to PNG at 300 DPI...');
        try {
          final pngBytes = await _convertPdfToPng(pdfBytes);
          print('PNG conversion complete: ${pngBytes.length} bytes');

          final multipartFile = MultipartFile.fromBytes(
            pngBytes,
            filename: 'photostrip.png',
          );
          formData.files.add(MapEntry('files', multipartFile));
        } catch (e) {
          print('PNG conversion failed, uploading PDF as fallback: $e');
          // Fallback: upload original PDF if conversion fails
          final multipartFile = MultipartFile.fromBytes(
            pdfBytes,
            filename: 'photostrip.pdf',
          );
          formData.files.add(MapEntry('files', multipartFile));
        }
        currentProgress += progressPerFile;
        onProgress(currentProgress);
      }

      // Generate and add social media consent document if consent was given
      if (allowSocialMediaPosting) {
        print('Generating social media consent document...');
        final consentDocument = _generateConsentDocument(archiveId);
        final consentBytes = Uint8List.fromList(consentDocument.codeUnits);
        final consentMultipartFile = MultipartFile.fromBytes(
          consentBytes,
          filename: 'social_media_consent_agreement.txt',
        );
        formData.files.add(MapEntry('files', consentMultipartFile));
        currentProgress += progressPerFile;
        onProgress(currentProgress);
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

  /// Rasterize the first page of a PDF at 300 DPI and return PNG bytes.
  Future<Uint8List> _convertPdfToPng(Uint8List pdfBytes) async {
    // Rasterize at 300 DPI for full print quality (4×6″ = 1200×1800 px)
    const dpi = 300.0;

    final pages = Printing.raster(pdfBytes, dpi: dpi);
    final firstPage = await pages.first;

    // PdfRaster.toPng() returns fully encoded PNG bytes at the rasterized resolution
    final pngBytes = await firstPage.toPng();
    print(
      'PDF rasterized to PNG: ${firstPage.width}×${firstPage.height} px, '
      '${pngBytes.length} bytes',
    );

    return pngBytes;
  }

  String _generateArchiveUrl(String archiveId) {
    // Generate the archive URL that points to the Next.js page
    final baseUrl = dotenv.env['WEB_URL'] ?? _dio.options.baseUrl;
    return '$baseUrl/archive/$archiveId';
  }

  /// Generates a formal consent document for social media posting authorization
  String _generateConsentDocument(String archiveId) {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final formattedDate =
        '${months[now.month - 1]} ${now.day.toString().padLeft(2, '0')}, ${now.year}';
    final formattedTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final timestamp = now.toUtc().toIso8601String();

    return '''
================================================================================
                    SOCIAL MEDIA CONSENT AUTHORIZATION
                         OFFICIAL DOCUMENTATION
================================================================================

DOCUMENT TYPE: Digital Consent Agreement
DOCUMENT ID: CONSENT-$archiveId
GENERATED: $formattedDate at $formattedTime
TIMESTAMP (UTC): $timestamp

--------------------------------------------------------------------------------
                              DECLARATION
--------------------------------------------------------------------------------

This document serves as formal proof and legal record that the individual(s) 
participating in the photo session associated with Archive ID: $archiveId 
has/have voluntarily provided consent for the use of their photographs and 
video content for social media and promotional purposes.

--------------------------------------------------------------------------------
                         CONSENT ACKNOWLEDGMENT
--------------------------------------------------------------------------------

By accepting the digital consent agreement presented during the photo session,
the consenting party has acknowledged and agreed to the following terms:

1. GRANT OF PERMISSION
   The consenting party hereby grants PhotoCafe and its affiliates the 
   non-exclusive, royalty-free right to use, reproduce, modify, publish, 
   and distribute the photographs and video content captured during this 
   session.

2. PERMITTED USES
   The content may be used for:
   • Social media platforms (Instagram, Facebook, TikTok, Twitter/X, etc.)
   • Company websites and online portfolios
   • Promotional and marketing materials
   • Advertising campaigns
   • Press and media publications

3. NO COMPENSATION
   The consenting party acknowledges that no monetary compensation will be 
   provided for the use of their images in promotional materials.

4. DURATION
   This consent remains valid indefinitely unless revoked in writing by 
   contacting the establishment directly.

5. REVOCATION RIGHTS
   The consenting party retains the right to request removal of their 
   content by submitting a formal written request. However, removal from 
   third-party shares, reposts, or cached versions cannot be guaranteed.

6. AGE VERIFICATION
   By providing consent, the individual confirms they are of legal age to 
   enter into this agreement, or have obtained proper guardian authorization.

--------------------------------------------------------------------------------
                         DIGITAL VERIFICATION
--------------------------------------------------------------------------------

Session Archive ID:     $archiveId
Consent Provided:       YES
Consent Method:         Digital Agreement (In-App Confirmation)
Agreement Version:      1.0
Platform:               PhotoCafe Windows Application
Consent Timestamp:      $timestamp

--------------------------------------------------------------------------------
                              AUTHENTICITY
--------------------------------------------------------------------------------

This document was automatically generated at the time of consent and is stored
alongside the session media files as an official record of authorization.

The digital nature of this consent, combined with the unique Archive ID and 
timestamp, serves as verifiable proof that consent was obtained through the 
official PhotoCafe application workflow.

================================================================================
                    END OF CONSENT DOCUMENTATION
================================================================================

Generated by PhotoCafe Soft Copies Service
Archive Reference: $archiveId
''';
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
