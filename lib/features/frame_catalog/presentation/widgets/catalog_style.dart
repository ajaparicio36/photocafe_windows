import 'package:flutter/material.dart';
import '../../domain/frame_catalog_models.dart';

const catalogInk = Color(0xFF740000);
const catalogPaper = Color(0xFFF7F5F5);

String frameKindLabel(FrameTemplateKind kind) => switch (kind) {
  FrameTemplateKind.classicPortrait => 'Portrait / Keychain',
  FrameTemplateKind.classicLandscape => 'Landscape',
  FrameTemplateKind.classicPhotobox => 'Photobox',
  FrameTemplateKind.flipbook => 'Flipbook',
};

String catalogErrorMessage(Object error) => error is FrameCatalogException
    ? error.message
    : 'The change could not be saved. Check the local storage and try again.';

/// A self-contained staff surface; customer styling stays unchanged.
class CatalogTheme extends StatelessWidget {
  final Widget child;

  const CatalogTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: catalogInk,
      brightness: Brightness.light,
    ).copyWith(primary: catalogInk, onPrimary: Colors.white);
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: catalogPaper,
        appBarTheme: const AppBarTheme(
          backgroundColor: catalogInk,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 44)),
        ),
        tooltipTheme: const TooltipThemeData(
          waitDuration: Duration(milliseconds: 500),
        ),
      ),
      child: child,
    );
  }
}

class CatalogNotice extends StatelessWidget {
  final String message;
  final bool isError;
  final VoidCallback? onDismiss;

  const CatalogNotice({
    super.key,
    required this.message,
    this.isError = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isError ? scheme.errorContainer : const Color(0xFFFFE9B4),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: isError
                  ? scheme.onErrorContainer
                  : const Color(0xFF503900),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: isError
                      ? scheme.onErrorContainer
                      : const Color(0xFF503900),
                ),
              ),
            ),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Dismiss message',
                onPressed: onDismiss,
                icon: const Icon(Icons.close, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}
