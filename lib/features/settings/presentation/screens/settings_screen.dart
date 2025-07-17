import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_container.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/shared/screen_header.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<String> _availablePrinters = [];

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    final printers = await ref
        .read(printerProvider.notifier)
        .getAvailablePrinters();
    setState(() {
      _availablePrinters = printers;
    });
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
                    _buildSectionHeader(context, 'Printer Configuration'),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Icon(
          Icons.print_rounded,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
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
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
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
              hint: const Text('Select a printer'),
              isExpanded: true,
              underline: const SizedBox.shrink(),
              items: _availablePrinters
                  .map(
                    (printer) => DropdownMenuItem(
                      value: printer,
                      child: Text(printer, overflow: TextOverflow.ellipsis),
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
}
