import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Uses the PDFium already shipped by the Windows printing plugin. No window,
/// printer or native Flutter application is started by these pixel tests.
class HeadlessPdfRasterizer {
  static const _path = 'build/windows/x64/pdfium-src/bin/pdfium.dll';
  static bool get available => Platform.isWindows && File(_path).existsSync();
  final DynamicLibrary _pdf = DynamicLibrary.open(_path);
  final DynamicLibrary _kernel = DynamicLibrary.open('kernel32.dll');

  HeadlessPdfRasterizer() {
    _pdf.lookupFunction<Void Function(), void Function()>('FPDF_InitLibrary')();
  }

  img.Image render(Uint8List bytes, {int width = 620, int height = 922}) {
    final allocate = _kernel
        .lookupFunction<
          Pointer<Void> Function(Uint32, IntPtr),
          Pointer<Void> Function(int, int)
        >('LocalAlloc');
    final free = _kernel
        .lookupFunction<
          Pointer<Void> Function(Pointer<Void>),
          Pointer<Void> Function(Pointer<Void>)
        >('LocalFree');
    final memory = allocate(0, bytes.length);
    if (memory == nullptr) throw StateError('Unable to allocate PDF input.');
    memory.cast<Uint8>().asTypedList(bytes.length).setAll(0, bytes);
    final document = _pdf
        .lookupFunction<
          Pointer<Void> Function(Pointer<Void>, Int32, Pointer<Char>),
          Pointer<Void> Function(Pointer<Void>, int, Pointer<Char>)
        >('FPDF_LoadMemDocument')(memory, bytes.length, nullptr);
    if (document == nullptr) {
      free(memory);
      throw StateError('Unable to load PDF.');
    }
    final page = _pdf
        .lookupFunction<
          Pointer<Void> Function(Pointer<Void>, Int32),
          Pointer<Void> Function(Pointer<Void>, int)
        >('FPDF_LoadPage')(document, 0);
    final bitmap = _pdf
        .lookupFunction<
          Pointer<Void> Function(Int32, Int32, Int32),
          Pointer<Void> Function(int, int, int)
        >('FPDFBitmap_Create')(width, height, 1);
    try {
      _pdf.lookupFunction<
        Void Function(Pointer<Void>, Int32, Int32, Int32, Int32, Uint32),
        void Function(Pointer<Void>, int, int, int, int, int)
      >('FPDFBitmap_FillRect')(bitmap, 0, 0, width, height, 0xffffffff);
      _pdf.lookupFunction<
        Void Function(
          Pointer<Void>,
          Pointer<Void>,
          Int32,
          Int32,
          Int32,
          Int32,
          Int32,
          Int32,
        ),
        void Function(
          Pointer<Void>,
          Pointer<Void>,
          int,
          int,
          int,
          int,
          int,
          int,
        )
      >('FPDF_RenderPageBitmap')(bitmap, page, 0, 0, width, height, 0, 0);
      final stride = _pdf
          .lookupFunction<
            Int32 Function(Pointer<Void>),
            int Function(Pointer<Void>)
          >('FPDFBitmap_GetStride')(bitmap);
      final buffer = _pdf
          .lookupFunction<
            Pointer<Uint8> Function(Pointer<Void>),
            Pointer<Uint8> Function(Pointer<Void>)
          >('FPDFBitmap_GetBuffer')(bitmap);
      return img.Image.fromBytes(
        width: width,
        height: height,
        bytes: Uint8List.fromList(buffer.asTypedList(stride * height)).buffer,
        rowStride: stride,
        numChannels: 4,
        order: img.ChannelOrder.bgra,
      );
    } finally {
      _pdf.lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('FPDFBitmap_Destroy')(bitmap);
      _pdf.lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('FPDF_ClosePage')(page);
      _pdf.lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('FPDF_CloseDocument')(document);
      free(memory);
    }
  }
}
