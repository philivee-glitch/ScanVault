import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

class ImageProcessor {
  static Future<String> applyFilter(String imagePath, String filter) async {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return imagePath;

    switch (filter) {
      case 'B&W':
        image = img.grayscale(image);
        image = img.contrast(image, contrast: 150);
        break;
      case 'Grayscale':
        image = img.grayscale(image);
        break;
      case 'Color+':
        image = img.adjustColor(image, saturation: 1.3);
        break;
      default:
        break;
    }

    final processedFile = File(imagePath.replaceAll('.jpg', '_filtered.jpg'));
    await processedFile.writeAsBytes(img.encodeJpg(image));

    return processedFile.path;
  }

  static Future<String> adjustBrightness(String imagePath, double brightness) async {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return imagePath;

    image = img.adjustColor(image, brightness: brightness / 100);

    final processedFile = File(imagePath.replaceAll('.jpg', '_brightness.jpg'));
    await processedFile.writeAsBytes(img.encodeJpg(image));

    return processedFile.path;
  }

  static Future<String> adjustContrast(String imagePath, double contrast) async {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return imagePath;

    image = img.adjustColor(image, contrast: contrast);

    final processedFile = File(imagePath.replaceAll('.jpg', '_contrast.jpg'));
    await processedFile.writeAsBytes(img.encodeJpg(image));

    return processedFile.path;
  }

  static Future<String> rotateImage(String imagePath, int degrees) async {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);

    if (image == null) return imagePath;

    image = img.copyRotate(image, angle: degrees.toDouble());

    final processedFile = File(imagePath.replaceAll('.jpg', '_rotated.jpg'));
    await processedFile.writeAsBytes(img.encodeJpg(image));

    return processedFile.path;
  }

  static double calculateDistance(Point<double> p1, Point<double> p2) {
    return sqrt(
        (p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y));
  }
}