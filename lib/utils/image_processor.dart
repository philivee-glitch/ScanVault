import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;

class ImageProcessor {
  // Apply perspective transformation
  static Future<img.Image> applyPerspectiveTransform(
    img.Image image,
    List<Offset> corners,
  ) async {
    // Sort corners: top-left, top-right, bottom-right, bottom-left
    final sortedCorners = _sortCorners(corners);
    
    // Calculate destination dimensions
    final width = _distance(sortedCorners[0], sortedCorners[1]).toInt();
    final height = _distance(sortedCorners[0], sortedCorners[3]).toInt();
    
    // Create output image
    final output = img.Image(width: width, height: height);
    
    // Apply perspective transform
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final srcPoint = _getSourcePoint(
          x.toDouble(),
          y.toDouble(),
          sortedCorners,
          width.toDouble(),
          height.toDouble(),
        );
        
        if (srcPoint.dx >= 0 && srcPoint.dx < image.width &&
            srcPoint.dy >= 0 && srcPoint.dy < image.height) {
          final pixel = image.getPixel(srcPoint.dx.toInt(), srcPoint.dy.toInt());
          output.setPixel(x, y, pixel);
        }
      }
    }
    
    return output;
  }

  // Apply black and white filter
  static img.Image applyBlackWhite(img.Image image) {
    final bw = img.grayscale(image);
    return img.contrast(bw, contrast: 150);
  }

  // Apply grayscale filter
  static img.Image applyGrayscale(img.Image image) {
    return img.grayscale(image);
  }

  // Apply color enhancement
  static img.Image applyColorEnhancement(img.Image image) {
    var enhanced = img.adjustColor(image, saturation: 1.3);
    enhanced = img.contrast(enhanced, contrast: 120);
    return enhanced;
  }

  // Adjust brightness
  static img.Image adjustBrightness(img.Image image, double brightness) {
    return img.brightness(image, brightness: brightness);
  }

  // Adjust contrast
  static img.Image adjustContrast(img.Image image, double contrast) {
    return img.contrast(image, contrast: contrast);
  }

  // Rotate image
  static img.Image rotateImage(img.Image image, int angle) {
    return img.copyRotate(image, angle: angle);
  }

  // Helper: Sort corners in order
  static List<Offset> _sortCorners(List<Offset> corners) {
    corners.sort((a, b) => a.dy.compareTo(b.dy));
    
    final top = corners.sublist(0, 2);
    final bottom = corners.sublist(2, 4);
    
    top.sort((a, b) => a.dx.compareTo(b.dx));
    bottom.sort((a, b) => a.dx.compareTo(b.dx));
    
    return [top[0], top[1], bottom[1], bottom[0]];
  }

  // Helper: Calculate distance between two points
  static double _distance(Offset p1, Offset p2) {
    return ((p2.dx - p1.dx) * (p2.dx - p1.dx) + 
            (p2.dy - p1.dy) * (p2.dy - p1.dy)).sqrt();
  }

  // Helper: Get source point for perspective transform
  static Offset _getSourcePoint(
    double x,
    double y,
    List<Offset> corners,
    double width,
    double height,
  ) {
    final u = x / width;
    final v = y / height;
    
    final topLeft = corners[0];
    final topRight = corners[1];
    final bottomRight = corners[2];
    final bottomLeft = corners[3];
    
    final top = Offset(
      topLeft.dx + (topRight.dx - topLeft.dx) * u,
      topLeft.dy + (topRight.dy - topLeft.dy) * u,
    );
    
    final bottom = Offset(
      bottomLeft.dx + (bottomRight.dx - bottomLeft.dx) * u,
      bottomLeft.dy + (bottomRight.dy - bottomLeft.dy) * u,
    );
    
    return Offset(
      top.dx + (bottom.dx - top.dx) * v,
      top.dy + (bottom.dy - top.dy) * v,
    );
  }
}

class Offset {
  final double dx;
  final double dy;

  Offset(this.dx, this.dy);
}
