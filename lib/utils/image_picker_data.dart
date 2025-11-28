import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// Cross-platform wrapper for picked images
/// Holds XFile and Uint8List (bytes) for use across all platforms
class ImagePickerData {
  final XFile xFile;
  final Uint8List bytes;
  final String name;
  
  ImagePickerData({
    required this.xFile,
    required this.bytes,
    required this.name,
  });
  
  /// Create ImagePickerData from XFile
  static Future<ImagePickerData> fromXFile(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    return ImagePickerData(
      xFile: xFile,
      bytes: bytes,
      name: xFile.name,
    );
  }
  
  /// Get path (mobile/desktop only)
  String get path => xFile.path;
  
  /// Get size in bytes
  int get size => bytes.length;
  
  /// Get size in MB
  double get sizeInMB => size / (1024 * 1024);
}
