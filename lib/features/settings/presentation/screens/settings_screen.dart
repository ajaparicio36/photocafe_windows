import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_container.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_header.dart';
import 'package:photocafe_windows/features/print/domain/data/models/printer_state.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/features/settings/domain/data/models/flipbook_archive_entry.dart';
import 'package:photocafe_windows/features/settings/domain/data/providers/flipbook_archive_notifier.dart';
import 'package:windows_printer/windows_printer.dart';
import 'dart:typed_data';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<String> _availablePrinters = [];
  List<CameraDescription> _availableCameras = [];
  bool _isTestPrinting = false;
  bool _isFrameTestPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final printers = await ref
        .read(printerProvider.notifier)
        .getAvailablePrinters();
    final cameras = await ref
        .read(printerProvider.notifier)
        .getAvailableCameras();
    setState(() {
      _availablePrinters = printers;
      _availableCameras = cameras;
    });
  }

  Future<void> _testPrint(String printerName) async {
    setState(() {
      _isTestPrinting = true;
    });

    try {
      // Create a simple test document
      final testText =
          '''
Test Print from PhotoCafe
========================
Printer: $printerName
Time: ${DateTime.now()}
USB Connection Test

This is a test print to verify
that your printer is working
correctly with PhotoCafe.

If you can read this, the basic
printing functionality is working.
''';

      // Try different print methods
      try {
        // Method 1: Try printing as rich text
        await WindowsPrinter.printRichTextDocument(
          content: testText,
          printerName: printerName,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test print sent successfully to $printerName'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } catch (e) {
        // Method 2: Try raw bytes with plain text
        final textBytes = Uint8List.fromList(testText.codeUnits);
        await WindowsPrinter.printRawData(
          data: textBytes,
          printerName: printerName,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test print (raw) sent to $printerName'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test print failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isTestPrinting = false;
      });
    }
  }

  String _formatArchiveDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month ${dt.year}, $hour:$minute';
  }

  Widget _buildFlipbookArchivesSection(BuildContext context) {
    final archiveState = ref.watch(flipbookArchiveProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context,
          'Flipbook PDF Archives',
          Icons.picture_as_pdf_rounded,
        ),
        const SizedBox(height: 24),
        archiveState.when(
          data: (archives) {
            if (archives.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: Center(
                  child: Text(
                    'No archived flipbooks yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: const Color(0xFF740000).withOpacity(0.6),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: archives.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_rounded,
                        size: 28,
                        color: const Color(0xFF740000),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatArchiveDate(entry.createdAt),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: const Color(0xFF740000),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.frameName,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 14,
                                    color: const Color(
                                      0xFF740000,
                                    ).withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.visibility_rounded),
                        color: const Color(0xFF740000),
                        iconSize: 28,
                        tooltip: 'Preview & Reprint',
                        onPressed: () => _openArchive(entry),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: const Color(0xFF740000).withOpacity(0.6),
                        iconSize: 28,
                        tooltip: 'Delete',
                        onPressed: () => _confirmDeleteArchive(entry),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Text(
            'Failed to load archives: $err',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Future<void> _openArchive(FlipbookArchiveEntry entry) async {
    try {
      final pdfBytes = await ref
          .read(flipbookArchiveProvider.notifier)
          .getArchivePdfBytes(entry);

      if (mounted) {
        context.go(
          '/settings/archive-preview',
          extra: {'pdfBytes': pdfBytes, 'frameName': entry.frameName},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open archive: $e')));
      }
    }
  }

  Future<void> _confirmDeleteArchive(FlipbookArchiveEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Archive'),
        content: Text(
          'Delete this flipbook archive from ${_formatArchiveDate(entry.createdAt)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(flipbookArchiveProvider.notifier).deleteArchive(entry);
    }
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF740000),
          ),
        ),
      ],
    );
  }

  Widget _buildPrinterSelector({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String? currentPrinter,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: const Color(0xFF740000),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF740000),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            width: 400,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: DropdownButton<String>(
              value: _availablePrinters.contains(currentPrinter)
                  ? currentPrinter
                  : null,
              hint: const Text(
                'Select a printer',
                style: TextStyle(color: Colors.white),
              ),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              style: const TextStyle(color: Colors.white),
              dropdownColor: Theme.of(context).colorScheme.background,
              items: _availablePrinters
                  .map(
                    (printer) => DropdownMenuItem(
                      value: printer,
                      child: Text(
                        printer,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraSelector({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String? currentCamera,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: const Color(0xFF740000),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF740000),
                  ),
                ),
                // Show warning only if same camera AND more than 2 cameras available
                if (_showCameraConflictWarning(currentCamera) &&
                    _availableCameras.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Warning: Same camera selected for photo and video',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF740000)),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Show info message when using same camera with limited options
                if (_showCameraConflictWarning(currentCamera) &&
                    _availableCameras.length <= 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Same camera will be used for both photo and video (limited cameras available)',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFF740000)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            width: 400,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: DropdownButton<String>(
              value: _availableCameras.any((cam) => cam.name == currentCamera)
                  ? currentCamera
                  : null,
              hint: const Text(
                'Select a camera',
                style: TextStyle(color: Colors.white),
              ),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              style: const TextStyle(color: Colors.white),
              dropdownColor: Theme.of(context).colorScheme.background,
              items: _availableCameras
                  .map(
                    (camera) => DropdownMenuItem(
                      value: camera.name,
                      child: Text(
                        camera.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null && _validateCameraSelection(title, value)) {
                  onChanged(value);
                } else if (value != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Camera already in use. Consider using different cameras when available.',
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _showCameraConflictWarning(String? currentCamera) {
    // No conflict possible since photos use Canon EDSDK,
    // not a system webcam. Only one webcam selector remains.
    return false;
  }

  bool _validateCameraSelection(String cameraType, String selectedCamera) {
    // No conflict validation needed since photos use Canon EDSDK,
    // not a system webcam. Any webcam can be selected freely.
    return true;
  }

  Widget _buildFullscreenToggle(BuildContext context, PrinterState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fullscreen Mode',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: const Color(0xFF740000),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enable fullscreen mode for kiosk-style operation. The application will occupy the entire screen.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF740000),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Switch(
            value: state.isFullscreen,
            onChanged: (value) {
              ref.read(printerProvider.notifier).setFullscreenMode(value);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraModeToggle(BuildContext context, PrinterState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use System Camera for Photos',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: const Color(0xFF740000),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'When enabled, photos are captured using a system webcam instead of the Canon EDSDK camera. '
                  'Use this as a fallback when the Canon camera is unavailable.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF740000),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Switch(
            value: state.useSystemCamera,
            onChanged: (value) {
              ref.read(printerProvider.notifier).setUseSystemCamera(value);
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.print_rounded,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                'Printer Test',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF740000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Test your printer connection by sending a simple test document.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF740000)),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availablePrinters.map((printer) {
              return ElevatedButton.icon(
                onPressed: _isTestPrinting ? null : () => _testPrint(printer),
                icon: _isTestPrinting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Icon(Icons.print),
                label: Text('Test $printer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // Frame Border Test Section
          Row(
            children: [
              Icon(
                Icons.crop_free_rounded,
                size: 28,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Text(
                'Frame Border Test',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF740000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Test frame border positioning by printing empty frames with alignment guides.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF740000)),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: _isFrameTestPrinting ? null : _testPrintClassicFrame,
                icon: _isFrameTestPrinting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Icon(Icons.grid_view_rounded),
                label: Text('Test Classic Frame (4x6)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isFrameTestPrinting
                    ? null
                    : _testPrintFlipbookFrame,
                icon: _isFrameTestPrinting
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Icon(Icons.collections_rounded),
                label: Text('Test Flipbook Frame (6x4)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _testPrintClassicFrame() async {
    setState(() {
      _isFrameTestPrinting = true;
    });

    try {
      await ref.read(printerProvider.notifier).testPrintClassicFrame();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Classic frame border test sent to printer'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Classic frame test failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isFrameTestPrinting = false;
      });
    }
  }

  Future<void> _testPrintFlipbookFrame() async {
    setState(() {
      _isFrameTestPrinting = true;
    });

    try {
      await ref.read(printerProvider.notifier).testPrintFlipbookFrame();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Flipbook frame border test sent to printer'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Flipbook frame test failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() {
        _isFrameTestPrinting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final printerState = ref.watch(printerProvider);

    return ScreenContainer(
      child: Column(
        children: [
          ScreenHeader(
            title: 'Settings',
            subtitle: 'Configure application settings',
            backRoute: '/',
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
              child: printerState.when(
                data: (state) => ListView(
                  children: [
                    // Flipbook PDF Archives Section
                    _buildFlipbookArchivesSection(context),
                    const SizedBox(height: 48),

                    // Display Configuration Section
                    _buildSectionHeader(
                      context,
                      'Display Configuration',
                      Icons.display_settings_rounded,
                    ),
                    const SizedBox(height: 24),
                    _buildFullscreenToggle(context, state),
                    const SizedBox(height: 48),

                    _buildSectionHeader(
                      context,
                      'Printer Configuration',
                      Icons.print_rounded,
                    ),
                    const SizedBox(height: 24),
                    _buildPrinterSelector(
                      context: context,
                      title: 'Cut Enabled Printer',
                      subtitle:
                          'Printer used for photo strips that require cutting.',
                      currentPrinter: state.cutEnabledPrinter,
                      onChanged: (printer) {
                        if (printer != null) {
                          ref
                              .read(printerProvider.notifier)
                              .setCutEnabledPrinter(printer);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildPrinterSelector(
                      context: context,
                      title: 'Cut Disabled Printer',
                      subtitle:
                          'Printer used for standard prints without cutting.',
                      currentPrinter: state.cutDisabledPrinter,
                      onChanged: (printer) {
                        if (printer != null) {
                          ref
                              .read(printerProvider.notifier)
                              .setCutDisabledPrinter(printer);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildPrinterSelector(
                      context: context,
                      title: 'Video Printer',
                      subtitle:
                          'Printer used specifically for video-related prints with custom settings.',
                      currentPrinter: state.videoPrinter,
                      onChanged: (printer) {
                        if (printer != null) {
                          ref
                              .read(printerProvider.notifier)
                              .setVideoPrinter(printer);
                        }
                      },
                    ),
                    const SizedBox(height: 48),

                    // Camera Configuration Section
                    _buildSectionHeader(
                      context,
                      'Camera Configuration',
                      Icons.camera_alt_rounded,
                    ),
                    const SizedBox(height: 24),
                    _buildCameraModeToggle(context, state),
                    const SizedBox(height: 24),
                    if (state.useSystemCamera)
                      _buildCameraSelector(
                        context: context,
                        title: 'Photo Capture Camera',
                        subtitle:
                            'System webcam used for capturing photos when Canon EDSDK is not available.',
                        currentCamera: state.photoCameraName,
                        onChanged: (camera) {
                          if (camera != null) {
                            ref
                                .read(printerProvider.notifier)
                                .setPhotoCameraName(camera);
                          }
                        },
                      ),
                    if (state.useSystemCamera) const SizedBox(height: 24),
                    _buildCameraSelector(
                      context: context,
                      title: 'Video Recording Camera',
                      subtitle:
                          'Webcam used for recording the companion video during photo sessions.',
                      currentCamera: state.videoCameraName,
                      onChanged: (camera) {
                        if (camera != null) {
                          ref
                              .read(printerProvider.notifier)
                              .setVideoCameraName(camera);
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildTestSection(),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
