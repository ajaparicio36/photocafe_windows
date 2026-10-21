import 'package:flutter_test/flutter_test.dart';
import 'package:photocafe_windows/features/classic/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/flipbook/presentation/constants/frame_constants.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_models.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_repository.dart';
import 'package:photocafe_windows/features/frame_catalog/domain/frame_catalog_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => FrameCatalogRuntime.instance.resetForTesting());

  test(
    'migrated and staff-edited stock frames retain customer descriptions',
    () async {
      final catalog = await bundledFrameCatalog();
      // An active session must not replace the stock metadata lookup source.
      FrameConstants.sessionFrames = [];
      FlipbookFrameConstants.sessionFrames = [];
      for (final original in FrameConstants.allBundledFrames) {
        final template = catalog.byId(original.id);
        expect(
          classicDefinition(template).description,
          original.description,
          reason: original.id,
        );
        final edited = template.copyWith(
          name: 'Staff renamed frame',
          revision: 42,
          bundled: false,
        );
        expect(
          classicDefinition(edited).description,
          original.description,
          reason: '${original.id} after staff edit',
        );
        expect(FrameTemplate.fromJson(edited.toJson()).revision, 42);
      }
      for (final original in FlipbookFrameConstants.bundledFrames) {
        final template = catalog.byId('flipbook-${original.id}');
        expect(
          flipbookDefinition(template).description,
          original.description,
          reason: original.id,
        );
        final edited = template.copyWith(
          name: 'Staff renamed frame',
          revision: 42,
          bundled: false,
        );
        expect(
          flipbookDefinition(edited).description,
          original.description,
          reason: '${original.id} after staff edit',
        );
        expect(FrameTemplate.fromJson(edited.toJson()).revision, 42);
      }
    },
  );

  test(
    'custom frames describe their layout without exposing staff revisions',
    () async {
      final catalog = await bundledFrameCatalog();
      final expected = {
        FrameTemplateKind.classicPortrait:
            'A portrait photo layout with your selected frame.',
        FrameTemplateKind.classicLandscape:
            'A landscape photo layout with your selected frame.',
        FrameTemplateKind.classicPhotobox:
            'A photobox layout with your selected frame.',
        FrameTemplateKind.flipbook:
            'A flipbook layout with your selected frame.',
      };
      for (final kind in FrameTemplateKind.values) {
        final source = catalog.templates.firstWhere(
          (frame) => frame.kind == kind,
        );
        final custom = source.copyWith(
          id: 'custom-${kind.name}',
          revision: 27,
          bundled: false,
        );
        final description = kind == FrameTemplateKind.flipbook
            ? flipbookDefinition(custom).description
            : classicDefinition(custom).description;
        expect(description, expected[kind]);
        expect(description, isNot(contains('Revision')));
        expect(FrameTemplate.fromJson(custom.toJson()).revision, 27);
      }
    },
  );
}
