import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_provider.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';
import 'package:photocafe_windows/widgets/event_design.dart';

/// One reversible choice for all photos in the accepted customer's session.
class MirrorPhotosSwitch extends ConsumerWidget {
  final bool enabled;
  final bool keychain;
  const MirrorPhotosSwitch({
    super.key,
    this.enabled = true,
    this.keychain = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) => SwitchListTile(
    key: const ValueKey('mirror-photos'),
    contentPadding: EdgeInsets.zero,
    activeThumbColor: EventDesign.red,
    activeTrackColor: Colors.white,
    inactiveThumbColor: Colors.white,
    inactiveTrackColor: EventDesign.red,
    trackOutlineColor: const WidgetStatePropertyAll(Colors.white),
    title: const Text(
      'Mirror photos',
      style: TextStyle(
        fontFamily: EventDesign.body,
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    subtitle: Text(
      keychain
          ? 'All photos in all four designs'
          : 'Flip every photo left to right',
      style: const TextStyle(
        fontFamily: EventDesign.body,
        color: Colors.white,
        fontSize: 12,
      ),
    ),
    value: ref.watch(sessionMirrorPhotosProvider),
    onChanged: enabled
        ? FrameCatalogRuntime.instance.setSessionMirrorPhotos
        : null,
  );
}
