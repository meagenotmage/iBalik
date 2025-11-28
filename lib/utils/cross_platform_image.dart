import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'image_picker_data.dart';

/// Cross-platform image widget that works on web, mobile, and desktop
/// Automatically chooses the correct image source based on platform
class CrossPlatformImage extends StatelessWidget {
  final ImagePickerData? imageData;
  final String? networkUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final Widget? loadingWidget;

  const CrossPlatformImage({
    super.key,
    this.imageData,
    this.networkUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorWidget,
    this.loadingWidget,
  }) : assert(imageData != null || networkUrl != null,
            'Either imageData or networkUrl must be provided');

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (networkUrl != null) {
      // Display network image (already uploaded to Supabase)
      imageWidget = Image.network(
        networkUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return loadingWidget ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
        },
      );
    } else if (imageData != null) {
      // Display picked image (before upload)
      if (kIsWeb) {
        // Web: Use Image.memory with Uint8List
        imageWidget = Image.memory(
          imageData!.bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ??
                Container(
                  width: width,
                  height: height,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
          },
        );
      } else {
        // Mobile/Desktop: Use Image.file
        final file = imageData!.file;
        if (file != null) {
          imageWidget = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ??
                  Container(
                    width: width,
                    height: height,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
            },
          );
        } else {
          // Fallback to memory if file is not available
          imageWidget = Image.memory(
            imageData!.bytes,
            width: width,
            height: height,
            fit: fit,
          );
        }
      }
    } else {
      // Should not reach here due to assertion
      imageWidget = Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    // Apply border radius if provided
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
