import 'dart:io';
import 'package:dio/dio.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'package:photocafe_windows/services/bouncy_fixture.dart';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/photos/domain/services/soft_copies_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PrintActionPanel extends ConsumerStatefulWidget {
  static const String defaultCutControlTitle = 'Split into Strips';
  static const String defaultCutControlDescription =
      'Prints two identical strips (requires cutter)';

  final bool isPrinting;
  final bool printReady;
  final bool splitStrips;
  final ValueChanged<bool> onSplitStripsChanged;
  final ValueChanged<int> onPrint;
  final Uint8List? pdfBytes;
  final List<File> additionalMediaFiles;
  final List<String> additionalFileNames;
  final String cutControlTitle;
  final String cutControlDescription;

  const PrintActionPanel({
    super.key,
    required this.isPrinting,
    this.printReady = true,
    required this.splitStrips,
    required this.onSplitStripsChanged,
    required this.onPrint,
    this.pdfBytes,
    this.additionalMediaFiles = const [],
    this.additionalFileNames = const [],
    this.cutControlTitle = defaultCutControlTitle,
    this.cutControlDescription = defaultCutControlDescription,
  });

  @override
  ConsumerState<PrintActionPanel> createState() => _PrintActionPanelState();
}

class _PrintActionPanelState extends ConsumerState<PrintActionPanel> {
  int _copies = 1;
  bool _isProcessingSoftCopies = false;
  double _processingProgress = 0.0;
  String _processingStatus = '';
  bool _allowSocialMediaPosting = false;

  void _showSocialMediaConsentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 700,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF740000).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Icon(
                    Icons.policy_rounded,
                    size: 48,
                    color: const Color(0xFF740000),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Social Media Consent Agreement',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF740000),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Agreement text
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        '''CONSENT FOR SOCIAL MEDIA USE

By agreeing to this consent, I hereby grant PhotoCafe and its affiliates the right and permission to use, publish, and share my photographs and video content captured during this photo session on social media platforms, websites, and other promotional materials.

I understand that:

1. My photos and videos may be shared on platforms including but not limited to Instagram, Facebook, TikTok, Twitter/X, and the company website.

2. The content may be used for promotional, marketing, and advertising purposes.

3. I will not receive monetary compensation for the use of my images on social media.

4. I may request removal of my content by contacting the establishment directly.

5. Once content is shared on social media, complete removal from third-party shares or reposts cannot be guaranteed.

6. A digital copy of this consent agreement will be stored with my session files as proof of my authorization.

By clicking "I Agree", I confirm that I am of legal age to provide this consent (or have guardian approval) and agree to all terms stated above.''',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            setState(() {
                              _allowSocialMediaPosting = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: const Color(0xFF740000),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'I Disagree',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF740000),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            setState(() {
                              _allowSocialMediaPosting = true;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF740000),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'I Agree',
                            style: TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  CancelToken? _uploadCancellation;
  Future<void> _handleSoftCopies() =>
      ref.read(bouncySessionProvider).track(_softCopiesWork());
  Future<void> _softCopiesWork() async {
    if (_isProcessingSoftCopies) return;
    final session = ref.read(bouncySessionProvider);
    final generation = session.generation;
    if (!session.valid(
      ref.read(photoProvider).requireValue.photos.map((p) => p.captureId),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Retake incomplete shots before continuing.'),
        ),
      );
      return;
    }
    setState(() {
      _isProcessingSoftCopies = true;
      _processingStatus = 'Preparing Bouncy MP4…';
    });
    final token = CancelToken();
    _uploadCancellation = token;
    void cancel() => token.cancel('Session cancelled');
    session.cancellations.add(cancel);
    try {
      late final String animation;
      try {
        animation = await ref.read(bouncyMediaProvider).export();
      } catch (error) {
        if (!mounted || generation != session.generation) return;
        await showDialog<void>(
          context: context,
          builder: (dialog) => AlertDialog(
            backgroundColor: Colors.white,
            titleTextStyle: const TextStyle(
              color: Color(0xff740000),
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            contentTextStyle: const TextStyle(
              color: Color(0xff740000),
              fontSize: 16,
            ),
            title: const Text('Motion export unavailable'),
            content: const Text(
              'Your photos are still printable. Choose Get Soft Copies again to retry the motion export. No archive has been uploaded.',
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xff740000),
                ),
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Retry later'),
              ),
            ],
          ),
        );
        return;
      }
      if (!mounted || generation != session.generation) return;
      setState(() {
        _processingStatus = 'Uploading soft copies…';
        _processingProgress = 0.5;
      });
      final media = await ref.read(photoProvider.notifier).getAllMediaFiles();
      if (generation != session.generation || token.isCancelled) return;
      final files = [...widget.additionalMediaFiles, File(animation)];
      final names = [...widget.additionalFileNames, 'bouncy_preview.mp4'];
      final result = await session.track(
        SoftCopiesService().uploadMediaFiles(
          mediaFiles: media,
          additionalMediaFiles: files,
          additionalFileNames: names,
          pdfBytes: widget.pdfBytes,
          cancelToken: token,
          allowSocialMediaPosting: _allowSocialMediaPosting,
          onProgress: (progress) {
            if (mounted && generation == session.generation)
              setState(() => _processingProgress = progress);
          },
        ),
      );
      if (!mounted || generation != session.generation) return;
      if (!result.success) throw StateError(result.error ?? 'Upload failed');
      _showSoftCopiesSuccessDialog(result.downloadUrl!);
    } catch (error) {
      if (mounted && generation == session.generation)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Soft copies unavailable: $error')),
        );
    } finally {
      session.cancellations.remove(cancel);
      if (mounted && generation == session.generation)
        setState(() {
          _isProcessingSoftCopies = false;
          _processingStatus = '';
        });
    }
  }

  @override
  void dispose() {
    _uploadCancellation?.cancel('Screen closed');
    super.dispose();
  }

  void _showSoftCopiesSuccessDialog(String downloadUrl) {
    if (!mounted) return;
    setState(() {
      _isProcessingSoftCopies = false;
      _processingProgress = 0;
      _processingStatus = '';
    });
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialog) => SoftCopiesReadyDialog(
        downloadUrl: downloadUrl,
        onStartOver: () {
          Navigator.pop(dialog);
          _startOver();
        },
      ),
    );
  }

  Future<void> _startOver() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Color(0xff740000),
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xff740000),
          fontSize: 16,
        ),
        title: const Text('Cancel and start over?'),
        content: const Text(
          'Current photos, motion export and local upload work will be discarded. Already accepted uploads cannot be recalled.',
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xff740000),
            ),
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Keep session'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Cancel and start over'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _uploadCancellation?.cancel('Start over');
    final notifier = ref.read(photoProvider.notifier);
    await notifier.clearAllPhotos();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final valid = ref
        .watch(bouncySessionProvider)
        .valid(
          ref.watch(photoProvider).value?.photos.map((p) => p.captureId) ?? [],
        );
    return Material(
      color: const Color(0xff740000),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Print and soft copies',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 64,
              child: FilledButton.icon(
                onPressed: widget.isPrinting || !valid || !widget.printReady
                    ? null
                    : () => widget.onPrint(_copies),
                icon: const Icon(Icons.print),
                label: Text(widget.isPrinting ? 'Printing...' : 'Print Photos'),
              ),
            ),
            if (!valid)
              const Text(
                'Retake incomplete shots before printing.',
                style: TextStyle(color: Colors.white),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Fewer copies',
                  onPressed: _copies > 1
                      ? () => setState(() => _copies--)
                      : null,
                  icon: const Icon(Icons.remove, color: Colors.white),
                ),
                Text(
                  '$_copies copies',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                IconButton(
                  tooltip: 'More copies',
                  onPressed: _copies < 10
                      ? () => setState(() => _copies++)
                      : null,
                  icon: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                widget.cutControlTitle,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                widget.cutControlDescription,
                style: const TextStyle(color: Colors.white70),
              ),
              value: widget.splitStrips,
              onChanged: widget.onSplitStripsChanged,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Allow social media posting',
                style: TextStyle(color: Colors.white),
              ),
              value: _allowSocialMediaPosting,
              onChanged: (value) {
                if (value) {
                  _showSocialMediaConsentDialog();
                } else {
                  setState(() => _allowSocialMediaPosting = false);
                }
              },
            ),
            if (BouncyFixture.enabled)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'QA encoder failure',
                  style: TextStyle(color: Colors.white),
                ),
                value: ref.read(bouncyMediaProvider).failEncoder,
                onChanged: (value) => setState(
                  () => ref.read(bouncyMediaProvider).failEncoder = value,
                ),
              ),
            SizedBox(
              height: 56,
              child: OutlinedButton.icon(
                onPressed:
                    _isProcessingSoftCopies || !valid || !widget.printReady
                    ? null
                    : _handleSoftCopies,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                icon: const Icon(Icons.download),
                label: Text(
                  _isProcessingSoftCopies
                      ? _processingStatus
                      : 'Get Soft Copies',
                ),
              ),
            ),
            if (_isProcessingSoftCopies)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(value: _processingProgress),
              ),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.isPrinting ? null : _startOver,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.refresh),
              label: const Text('Start Over'),
            ),
          ],
        ),
      ),
    );
  }
}

class SoftCopiesReadyDialog extends StatelessWidget {
  final String downloadUrl;
  final VoidCallback onStartOver;
  const SoftCopiesReadyDialog({
    super.key,
    required this.downloadUrl,
    required this.onStartOver,
  });
  @override
  Widget build(BuildContext context) {
    final availableHeight = MediaQuery.sizeOf(context).height * 0.84;
    return Dialog(
      backgroundColor: Colors.white,
      child: SizedBox(
        width: 520,
        height: availableHeight > 600 ? 600 : availableHeight,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Soft Copies Ready!',
                style: TextStyle(
                  color: Color(0xff740000),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan to download your photos and Bouncy Preview. Available for 8 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xff740000), fontSize: 14),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: QrImageView(
                      data: downloadUrl,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: SelectableText(
                  downloadUrl,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xff740000),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xff740000),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onStartOver,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xff740000),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Start Over'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
