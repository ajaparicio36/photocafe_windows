import 'package:photocafe_windows/widgets/event_design.dart';
import 'package:photocafe_windows/widgets/bouncy_preview.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/print/print_action_panel.dart';
import 'package:photocafe_windows/features/keychain/domain/services/keychain_composition_service.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';

class KeychainPrintScreen extends ConsumerStatefulWidget {
  static const bool defaultCut = false;
  static const String cutControlTitle = 'Cut sheet after printing';
  static const String cutControlDescription =
      'Cut the complete four-up sheet after printing';

  final KeychainPrintArguments? arguments;

  const KeychainPrintScreen({super.key, this.arguments});

  @override
  ConsumerState<KeychainPrintScreen> createState() =>
      _KeychainPrintScreenState();
}

class _KeychainPrintScreenState extends ConsumerState<KeychainPrintScreen> {
  bool _isPrinting = false;
  bool _cut = KeychainPrintScreen.defaultCut;
  KeychainPrintArguments? _arguments;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arguments != null) return;
    _arguments = widget.arguments;
    if (_arguments == null) {
      final extra = GoRouterState.of(context).extra;
      if (extra is KeychainPrintArguments) {
        _arguments = extra;
      }
    }
  }

  Future<void> _print(int copies) async {
    final arguments = _arguments;
    if (arguments == null ||
        !ref
            .read(bouncySessionProvider)
            .valid(
              ref.read(photoProvider).value?.photos.map((p) => p.captureId) ??
                  [],
            ))
      return;
    setState(() {
      _isPrinting = true;
    });
    try {
      await ref
          .read(printerProvider.notifier)
          .printPdfBytes(arguments.output.sheetPdf, cut: _cut, copies: copies);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keychain sheet sent to printer.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Print failed: $error')));
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final arguments = _arguments;
    if (arguments == null) {
      return EventPage(
        title: 'Keychain print',
        subtitle: 'Your four little memories, ready to keep',
        onBack: () => context.go('/keychain/design'),
        child: EventMessage(
          message: 'Prepare your final review before printing.',
          action: EventButton(
            label: 'RETURN TO DESIGN',
            onPressed: () => context.go('/keychain/design'),
          ),
        ),
      );
    }

    final additionalFiles = <File>[
      ...arguments.mediaBundle.variantFiles,
      arguments.mediaBundle.sheetFile,
    ];
    final additionalNames = <String>[
      for (
        var index = 0;
        index < arguments.mediaBundle.variantFiles.length;
        index++
      )
        'keychain_variant_${index + 1}.png',
      'keychain_sheet.png',
    ];

    return EventPage(
      title: 'Keychain print',
      subtitle: 'Your four little memories, ready to keep',
      onBack: () => context.go('/keychain/design'),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: EventSection(
              title: 'Your keychain sheet',
              child: PrintActionPanel(
                isPrinting: _isPrinting,
                printReady: arguments.output.sheetPdf.isNotEmpty,
                splitStrips: _cut,
                cutControlTitle: KeychainPrintScreen.cutControlTitle,
                cutControlDescription:
                    KeychainPrintScreen.cutControlDescription,
                pdfBytes: null,
                additionalMediaFiles: additionalFiles,
                additionalFileNames: additionalNames,
                onSplitStripsChanged: (value) => setState(() => _cut = value),
                onPrint: _print,
              ),
            ),
          ),
          const SizedBox(width: 60),
          Expanded(
            flex: 6,
            child: EventSection(
              title: 'Complete sheet',
              figure: 'assets/event/frames_figure1.png',
              figureWidth: 180,
              child: EventPanel(
                child: BouncyPreview(
                  foregroundColor: Colors.white,
                  archive: true,
                  photos: ref.watch(photoProvider).requireValue.photos,
                  selections: arguments.output.selections,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
