import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photocafe_windows/features/keychain/domain/data/models/keychain_models.dart';

class KeychainSessionNotifier extends Notifier<KeychainSessionState> {
  @override
  KeychainSessionState build() => KeychainSessionState.initial();

  void reset() {
    state = KeychainSessionState.initial();
  }

  void setVariantFrame(int variantIndex, String frameId) {
    _checkVariantIndex(variantIndex);
    KeychainFrameCatalog.byId(frameId);
    final variants = List<KeychainVariantSelection>.from(state.variants);
    variants[variantIndex] = variants[variantIndex].copyWith(frameId: frameId);
    state = state.copyWith(variants: variants);
  }

  void setVariantFilter(int variantIndex, String filterId) {
    _checkVariantIndex(variantIndex);
    KeychainFilterCatalog.byId(filterId);
    final variants = List<KeychainVariantSelection>.from(state.variants);
    variants[variantIndex] = variants[variantIndex].copyWith(
      filterId: filterId,
    );
    state = state.copyWith(variants: variants);
  }

  void setDesignIndex(int designIndex) {
    if (designIndex < 0 || designIndex >= keychainVariantCount) {
      throw ArgumentError.value(
        designIndex,
        'designIndex',
        'must be between 0 and ${keychainVariantCount - 1}',
      );
    }
    state = state.copyWith(designIndex: designIndex);
  }

  void enterReview() {
    state = state.copyWith(isReview: true);
  }

  void returnToDesignFour() {
    state = state.copyWith(
      designIndex: keychainVariantCount - 1,
      isReview: false,
    );
  }

  void _checkVariantIndex(int variantIndex) {
    if (variantIndex < 0 || variantIndex >= keychainVariantCount) {
      throw RangeError.range(
        variantIndex,
        0,
        keychainVariantCount - 1,
        'variantIndex',
      );
    }
  }
}

final keychainSessionProvider =
    NotifierProvider<KeychainSessionNotifier, KeychainSessionState>(
      KeychainSessionNotifier.new,
    );
