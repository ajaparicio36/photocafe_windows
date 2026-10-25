import 'package:flutter/foundation.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'frame_artwork_loader.dart';
import 'frame_catalog_models.dart';

FrameLayoutType layoutTypeForKind(FrameTemplateKind kind) => switch (kind) {
  FrameTemplateKind.classicPhotobox => FrameLayoutType.twoPhotos,
  FrameTemplateKind.classicLandscape => FrameLayoutType.fourLandscapePhotos,
  _ => FrameLayoutType.fourPhotos,
};

FrameDefinition classicDefinition(FrameTemplate template) {
  final type = layoutTypeForKind(template.kind);
  final layout = FrameLayout(
    type: type,
    leftColumnPositions: List.unmodifiable(
      template.slots.map(
        (slot) => FramePhotoPosition(
          left: slot.left,
          top: slot.top,
          width: slot.width,
          height: slot.height,
          rotationDegrees: slot.rotationDegrees,
          photoIndex: slot.photoIndex,
        ),
      ),
    ),
    rightColumnPositions: const [],
    topOffset: 0,
    frameAssetPath: FrameArtworkLoader.reference(template.artwork),
  );
  return FrameDefinition(
    id: template.id,
    name: template.name,
    description:
        FrameConstants.allBundledFrames
            .where((frame) => frame.id == template.id)
            .firstOrNull
            ?.description ??
        switch (template.kind) {
          FrameTemplateKind.classicLandscape =>
            'A landscape photo layout with your selected frame.',
          FrameTemplateKind.classicPhotobox =>
            'A photobox layout with your selected frame.',
          _ => 'A portrait photo layout with your selected frame.',
        },
    supportedLayouts: List.unmodifiable([type]),
    layouts: Map.unmodifiable({type: layout}),
    previewWidgetName: switch (type) {
      FrameLayoutType.twoPhotos => 'TwoByTwoFramePreview',
      FrameLayoutType.fourLandscapePhotos => 'LandscapeFramePreview',
      _ => 'FourByFourFramePreview',
    },
  );
}

FlipbookFrameDefinition flipbookDefinition(FrameTemplate template) =>
    FlipbookFrameDefinition(
      id: template.id,
      name: template.name,
      description:
          FlipbookFrameConstants.bundledFrames
              .where((frame) => 'flipbook-${frame.id}' == template.id)
              .firstOrNull
              ?.description ??
          'A flipbook layout with your selected frame.',
      previewWidgetName: 'StandardFlipbookFrame',
      layout: FlipbookFrameLayout(
        pageWidth: template.canvasWidth,
        pageHeight: template.canvasHeight,
        isLandscape: true,
        frameAssetPath: FrameArtworkLoader.reference(template.artwork),
        framePositions: List.unmodifiable(
          template.slots.map(
            (s) => FlipbookFramePosition(
              left: s.left,
              top: s.top,
              width: s.width,
              height: s.height,
              rotationDegrees: s.rotationDegrees,
            ),
          ),
        ),
      ),
    );

/// The current event configuration and the accepted customer's frozen view are
/// deliberately separate. Every legacy renderer resolves the same snapshot.
class FrameCatalogRuntime extends ChangeNotifier {
  FrameCatalogRuntime._();
  static final instance = FrameCatalogRuntime._();
  FrameCatalog? catalog;
  FrameCatalog? sessionCatalog;
  KioskMode? sessionMode;
  void replaceCatalog(FrameCatalog value) {
    catalog = value;
    notifyListeners();
  }

  void beginSession(KioskMode mode) {
    final latest = catalog;
    if (latest == null || !latest.isModeUsable(mode)) {
      throw const FrameCatalogException(
        'This experience is disabled or has no enabled frames. Ask staff to update Settings.',
      );
    }
    sessionCatalog = latest;
    sessionMode = mode;
    final classic = latest.templates.where(
      (t) => t.enabled && t.kind != FrameTemplateKind.flipbook,
    );
    FrameConstants.sessionFrames = List.unmodifiable(
      classic.map(classicDefinition),
    );
    FlipbookFrameConstants.sessionFrames = List.unmodifiable(
      latest.customerFrames(KioskMode.flipbook).map(flipbookDefinition),
    );
    notifyListeners();
  }

  void endSession() {
    sessionCatalog = null;
    sessionMode = null;
    FrameConstants.sessionFrames = null;
    FlipbookFrameConstants.sessionFrames = null;
    notifyListeners();
  }

  void resetForTesting() {
    endSession();
    catalog = null;
    FrameArtworkLoader.catalogDirectory = null;
  }

  String? redirect(String path) {
    final latest = catalog;
    if (latest == null || path == '/' || path.startsWith('/settings')) {
      return null;
    }
    final product = path.startsWith('/classic/')
        ? KioskProduct.classic
        : path.startsWith('/keychain/')
        ? KioskProduct.keychain
        : path.startsWith('/flipbook/')
        ? KioskProduct.flipbook
        : null;
    if (product == null) return null;
    final isStart = path.endsWith('/start');
    final accepted = sessionMode;
    if (!isStart && accepted != null && productForMode(accepted) == product) {
      return null;
    }
    if (!latest.isProductUsable(product)) return '/';
    // A direct continuation must first accept a mode and freeze its catalog.
    return isStart ? null : '/${product.name}/start';
  }
}
