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
    if (arguments == null) return;
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
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/keychain/design'),
            child: const Text('Return to Keychain design'),
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

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/design/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/keychain/design'),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF740000),
                        size: 32,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'KEYCHAIN PRINT PREVIEW',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: PrintActionPanel(
                          isPrinting: _isPrinting,
                          splitStrips: _cut,
                          cutControlTitle: KeychainPrintScreen.cutControlTitle,
                          cutControlDescription:
                              KeychainPrintScreen.cutControlDescription,
                          // The printable PDF is sent by [_print]. Soft-copy
                          // upload uses the exact 600×900 variants and the
                          // 1200×1800 sheet PNG below, so it must not add a
                          // second rasterized copy of the PDF.
                          pdfBytes: null,
                          additionalMediaFiles: additionalFiles,
                          additionalFileNames: additionalNames,
                          onSplitStripsChanged: (value) {
                            setState(() => _cut = value);
                          },
                          onPrint: _print,
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF740000,
                            ).withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'FOUR-UP SHEET',
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: Container(
                                  color: Colors.white,
                                  child: Image.memory(
                                    arguments.output.sheetPng,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'TL • TR • BL • BR  |  1200 × 1800 PNG',
                                style: TextStyle(
                                  fontFamily: 'SpaceMono',
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
