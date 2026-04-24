import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:photocafe_windows/core/handlers/dio_handler.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';

class FlipbookUploadScreen extends ConsumerStatefulWidget {
  const FlipbookUploadScreen({super.key});

  @override
  ConsumerState<FlipbookUploadScreen> createState() =>
      _FlipbookUploadScreenState();
}

class _FlipbookUploadScreenState extends ConsumerState<FlipbookUploadScreen> {
  late final String _sessionId;
  late final String _uploadUrl;
  Timer? _pollTimer;
  bool _videoReceived = false;
  bool _downloading = false;
  bool _timedOut = false;
  String? _errorMessage;
  int _elapsedSeconds = 0;
  static const _pollInterval = Duration(seconds: 3);
  static const _timeoutSeconds = 300; // 5 minutes

  static String _generateSessionId() {
    final rng = Random.secure();
    String hex(int count) => List.generate(
      count,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    return '${hex(4)}-${hex(2)}-4${hex(1)}${(rng.nextInt(4) + 8).toRadixString(16)}${hex(1)}-${hex(6)}';
  }

  @override
  void initState() {
    super.initState();
    _sessionId = _generateSessionId();
    final webUrl =
        dotenv.env['WEB_URL'] ?? 'https://click-click-popup.ajaparicio.com';
    _uploadUrl = '$webUrl/upload/$_sessionId';
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      _elapsedSeconds += _pollInterval.inSeconds;

      if (_elapsedSeconds >= _timeoutSeconds) {
        _pollTimer?.cancel();
        if (mounted) setState(() => _timedOut = true);
        return;
      }

      await _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (_videoReceived || _downloading) return;

    try {
      final dio = DioClient().instance;
      final response = await dio.get('/api/upload-video/$_sessionId/status');

      final data = response.data as Map<String, dynamic>;
      if (data['ready'] == true && data['fileName'] != null) {
        _pollTimer?.cancel();
        setState(() => _videoReceived = true);
        await _downloadAndProceed(data['fileName'] as String);
      }
    } on DioException catch (e) {
      // Silently ignore polling errors — the server may be unreachable
      // briefly. The next poll will retry.
      debugPrint('Poll error: ${e.message}');
    }
  }

  Future<void> _downloadAndProceed(String fileName) async {
    setState(() => _downloading = true);

    try {
      final dio = DioClient().instance;
      final tempDir = await getTemporaryDirectory();
      final videoDir = Directory(p.join(tempDir.path, 'videos'));
      if (!await videoDir.exists()) {
        await videoDir.create(recursive: true);
      }

      final localPath = p.join(
        videoDir.path,
        'upload_${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );

      await dio.download('/api/files/$_sessionId/$fileName', localPath);

      final file = File(localPath);
      if (!await file.exists() || await file.length() < 1024) {
        throw Exception('Downloaded video is invalid or too small');
      }

      // Load into the video pipeline
      await ref.read(videoProvider.notifier).loadExternalVideo(localPath);

      if (mounted) {
        // Short delay so the user sees "Video received!"
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go('/flipbook/filter');
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (mounted) {
        setState(() {
          _downloading = false;
          _videoReceived = false;
          _errorMessage = 'Failed to download video. Please try again.';
        });
        // Resume polling so the user can re-upload
        _startPolling();
      }
    }
  }

  void _retry() {
    setState(() {
      _timedOut = false;
      _errorMessage = null;
      _elapsedSeconds = 0;
    });
    _startPolling();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/design/flipbook-home/flipbook-home_bg.png',
              fit: BoxFit.fill,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => context.go('/flipbook/start'),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Color(0xFF740000),
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Main card
                  Container(
                    width: screenSize.width * 0.55,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: _buildContent(screenSize),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Size screenSize) {
    if (_timedOut) return _buildTimeoutState();
    if (_errorMessage != null) return _buildErrorState();
    if (_downloading) return _buildDownloadingState();
    if (_videoReceived) return _buildReceivedState();
    return _buildWaitingState(screenSize);
  }

  Widget _buildWaitingState(Size screenSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Scan to upload your video',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF740000),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Use your phone to record or choose a video (max 7 seconds)',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 14,
            color: const Color(0xFF740000).withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // QR code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF740000).withOpacity(0.15),
              width: 2,
            ),
          ),
          child: QrImageView(
            data: _uploadUrl,
            version: QrVersions.auto,
            size: screenSize.width * 0.18,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF740000),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF740000),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Waiting indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: const Color(0xFF740000).withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Waiting for video...',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 14,
                color: const Color(0xFF740000).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceivedState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade600,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Video received!',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF740000),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF740000).withOpacity(0.1),
            borderRadius: BorderRadius.circular(40),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF740000),
              strokeWidth: 4,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Downloading video...',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF740000),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeoutState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_off_rounded, color: Colors.orange.shade700, size: 56),
        const SizedBox(height: 16),
        const Text(
          'Session timed out',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF740000),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No video was received within 5 minutes.',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 14,
            color: const Color(0xFF740000).withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _retry,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF740000),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Try Again',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 56),
        const SizedBox(height: 16),
        Text(
          _errorMessage ?? 'An error occurred',
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 14,
            color: Colors.red.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _retry,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF740000),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Retry',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
