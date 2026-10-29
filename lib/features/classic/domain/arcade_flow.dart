import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photocafe_windows/features/classic/presentation/widgets/frames/frame_factory.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/services/bouncy_media_service.dart';
import 'package:photocafe_windows/services/bouncy_session.dart';

final arcadeFlowProvider = Provider<ArcadeFlow>(ArcadeFlow.new);

/// Coordinates the existing photo, print and Bouncy contracts for Arcade.
/// The accepted catalog supplies geometry throughout this customer's session.
class ArcadeFlow {
  final Ref _ref;
  ArcadeFlow(this._ref);

  Future<void> start() async {
    final runtime = FrameCatalogRuntime.instance;
    runtime.beginArcadeSession();
    final frame = runtime.sessionArcadeFrame!;
    try {
      final photos = _ref.read(photoProvider.notifier);
      await photos.clearAllPhotos();
      _ref
          .read(bouncySessionProvider)
          .setMotionEnabled(runtime.sessionBouncyEnabled);
      await photos.setCaptureCount(frame.captureCount);
      final printer = _ref.read(printerProvider.notifier);
      await printer.setLayoutMode(
        frame.classicVariant == ClassicVariant.photobox ? 2 : 4,
      );
      await printer.setLandscapeOrientation(
        frame.classicVariant == ClassicVariant.landscape,
      );
      _ref.read(bouncySessionProvider).classicFilterId = 'no_filter';
      _ref.read(classicBouncyFrameProvider.notifier).state = frame.id;
    } catch (_) {
      runtime.endSession();
      rethrow;
    }
  }

  Future<Uint8List> preparePrint() async {
    final frame = FrameCatalogRuntime.instance.sessionArcadeFrame;
    if (frame == null) throw StateError('The Arcade session has ended.');
    final photos = [..._ref.read(photoProvider).requireValue.photos]
      ..sort((a, b) => a.index.compareTo(b.index));
    final session = _ref.read(bouncySessionProvider);
    if (photos.length != frame.captureCount ||
        !session.valid(photos.map((photo) => photo.captureId)) ||
        photos.indexed.any((entry) => entry.$1 != entry.$2.index)) {
      throw StateError('Complete each shot before continuing to print.');
    }
    session.classicFilterId = 'no_filter';
    _ref.read(classicBouncyFrameProvider.notifier).state = frame.id;
    return session.track(
      FrameFactory.generatePdfForFrame(
        classicDefinition(frame),
        photos,
        frame.classicVariant == ClassicVariant.photobox ? 2 : 4,
        frame.classicVariant == ClassicVariant.landscape,
      ),
    );
  }
}
