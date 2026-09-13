import 'package:photocafe_windows/features/classic/presentation/constants/filter_constants.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';

/// Number of completed designs in a Keychain session.
const int keychainVariantCount = 4;

/// The independent frame/filter choice for one Keychain quadrant.
class KeychainVariantSelection {
  final String frameId;
  final String filterId;

  const KeychainVariantSelection({
    required this.frameId,
    required this.filterId,
  });

  KeychainVariantSelection copyWith({String? frameId, String? filterId}) {
    return KeychainVariantSelection(
      frameId: frameId ?? this.frameId,
      filterId: filterId ?? this.filterId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is KeychainVariantSelection &&
        other.frameId == frameId &&
        other.filterId == filterId;
  }

  @override
  int get hashCode => Object.hash(frameId, filterId);
}

/// Riverpod state for the Keychain design flow.
///
/// The constructor rejects every count other than four. Repeated frame/filter
/// pairs are intentionally allowed; each list entry belongs to its quadrant.
class KeychainSessionState {
  final List<KeychainVariantSelection> variants;
  final int designIndex;
  final bool isReview;

  KeychainSessionState({
    required List<KeychainVariantSelection> variants,
    this.designIndex = 0,
    this.isReview = false,
  }) : variants = List.unmodifiable(variants) {
    if (this.variants.length != keychainVariantCount) {
      throw ArgumentError.value(
        this.variants.length,
        'variants',
        'Keychain sessions require exactly $keychainVariantCount variants',
      );
    }
    if (designIndex < 0 || designIndex >= keychainVariantCount) {
      throw ArgumentError.value(
        designIndex,
        'designIndex',
        'must be between 0 and ${keychainVariantCount - 1}',
      );
    }
  }

  factory KeychainSessionState.initial() {
    final initialFrame = KeychainFrameCatalog.allClassicFrames.first.id;
    return KeychainSessionState(
      variants: [
        for (var index = 0; index < keychainVariantCount; index++)
          KeychainVariantSelection(
            frameId: initialFrame,
            filterId: 'no_filter',
          ),
      ],
    );
  }

  KeychainSessionState copyWith({
    List<KeychainVariantSelection>? variants,
    int? designIndex,
    bool? isReview,
  }) {
    return KeychainSessionState(
      variants: variants ?? this.variants,
      designIndex: designIndex ?? this.designIndex,
      isReview: isReview ?? this.isReview,
    );
  }
}

/// The active Classic frame definitions. Keychain intentionally shares this
/// list so narrowing the Classic picker also narrows Keychain without a
/// second catalog drifting out of sync.
class KeychainFrameCatalog {
  const KeychainFrameCatalog._();

  static List<FrameDefinition> get allClassicFrames {
    final frames = FrameConstants.availableFrames;
    if (frames.isEmpty) {
      throw StateError('Keychain requires at least one active Classic frame.');
    }
    return List.unmodifiable(frames);
  }

  static FrameDefinition byId(String frameId) {
    return allClassicFrames.firstWhere(
      (frame) => frame.id == frameId,
      orElse: () => throw ArgumentError.value(
        frameId,
        'frameId',
        'is not a Classic frame definition',
      ),
    );
  }
}

class KeychainFilterCatalog {
  const KeychainFilterCatalog._();

  static List<FilterDefinition> get allFilters =>
      FilterConstants.filterDefinitions;

  static FilterDefinition byId(String filterId) {
    return allFilters.firstWhere(
      (filter) => filter.id == filterId,
      orElse: () => throw ArgumentError.value(
        filterId,
        'filterId',
        'is not a Classic filter definition',
      ),
    );
  }
}
