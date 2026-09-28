import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:second_brain/features/expenses/ocr/receipt_ocr_result.dart';
import 'package:second_brain/features/expenses/ocr/receipt_parser.dart';

/// On-device OCR Service using Google ML Kit Text Recognition.
/// Performs completely local image processing on the Android device.
class ReceiptOcrService {
  final ReceiptParser _parser;
  final ImagePicker _picker;

  ReceiptOcrService({
    ReceiptParser? parser,
    ImagePicker? picker,
  })  : _parser = parser ?? const ReceiptParser(),
        _picker = picker ?? ImagePicker();

  /// Captures a receipt image using the device camera.
  Future<XFile?> captureReceiptCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
    } catch (_) {
      return null;
    }
  }

  /// Selects a receipt image from the device gallery.
  Future<XFile?> pickReceiptGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
    } catch (_) {
      return null;
    }
  }

  /// Processes the image at [filePath] with Google ML Kit Text Recognition,
  /// extracts raw text, and returns a structured [ReceiptOcrResult].
  Future<ReceiptOcrResult> processReceipt(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      return _parser.parse(recognizedText.text);
    } finally {
      await textRecognizer.close();
    }
  }
}
