import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Cross-platform wrapper for picked images
/// Holds both File (for mobile) and Uint8List (for web) representations
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
  
  /// Get File representation (mobile/desktop only)
  /// Returns null on web
  File? get file {
    if (kIsWeb) return null;
    return File(xFile.path);
  }
  
  /// Get path (mobile/desktop only)
  String get path => xFile.path;
  
  /// Get size in bytes
  int get size => bytes.length;
  
  /// Get size in MB
  double get sizeInMB => size / (1024 * 1024);
}
