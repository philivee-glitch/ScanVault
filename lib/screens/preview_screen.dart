import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'enhancement_screen.dart';

class PreviewScreen extends StatefulWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late List<Offset> corners;
  ui.Image? uiImage;
  bool isLoading = true;
  Size? imageSize;
  img.Image? originalImage;
  int? selectedCornerIndex;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final file = File(widget.imagePath);
    final bytes = await file.readAsBytes();
    
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    
    final image = img.decodeImage(bytes);
    
    if (image != null) {
      final imgWidth = frame.image.width.toDouble();
      final imgHeight = frame.image.height.toDouble();
      
      final detectedCorners = _quickEdgeDetection(image);
      
      setState(() {
        uiImage = frame.image;
        originalImage = image;
        imageSize = Size(imgWidth, imgHeight);
        corners = detectedCorners;
        isLoading = false;
      });
    }
  }

  List<Offset> _quickEdgeDetection(img.Image image) {
    final width = image.width;
    final height = image.height;
    final sampleStep = 20;
    
    int topEdge = 0;
    for (int y = 0; y < height ~/ 3; y += sampleStep) {
      int edgeCount = 0;
      for (int x = width ~/ 4; x < (3 * width) ~/ 4; x += sampleStep) {
        if (_isEdgePixel(image, x, y)) edgeCount++;
      }
      if (edgeCount > 3) {
        topEdge = y;
        break;
      }
    }
    
    int bottomEdge = height;
    for (int y = height - 1; y > (2 * height) ~/ 3; y -= sampleStep) {
      int edgeCount = 0;
      for (int x = width ~/ 4; x < (3 * width) ~/ 4; x += sampleStep) {
        if (_isEdgePixel(image, x, y)) edgeCount++;
      }
      if (edgeCount > 3) {
        bottomEdge = y;
        break;
      }
    }
    
    int leftEdge = 0;
    for (int x = 0; x < width ~/ 3; x += sampleStep) {
      int edgeCount = 0;
      for (int y = height ~/ 4; y < (3 * height) ~/ 4; y += sampleStep) {
        if (_isEdgePixel(image, x, y)) edgeCount++;
      }
      if (edgeCount > 3) {
        leftEdge = x;
        break;
      }
    }
    
    int rightEdge = width;
    for (int x = width - 1; x > (2 * width) ~/ 3; x -= sampleStep) {
      int edgeCount = 0;
      for (int y = height ~/ 4; y < (3 * height) ~/ 4; y += sampleStep) {
        if (_isEdgePixel(image, x, y)) edgeCount++;
      }
      if (edgeCount > 3) {
        rightEdge = x;
        break;
      }
    }
    
    return [
      Offset(leftEdge.toDouble(), topEdge.toDouble()),
      Offset(rightEdge.toDouble(), topEdge.toDouble()),
      Offset(rightEdge.toDouble(), bottomEdge.toDouble()),
      Offset(leftEdge.toDouble(), bottomEdge.toDouble()),
    ];
  }

  bool _isEdgePixel(img.Image image, int x, int y) {
    if (x <= 0 || x >= image.width - 1 || y <= 0 || y >= image.height - 1) return false;
    
    final center = image.getPixel(x, y);
    final left = image.getPixel(x - 1, y);
    final right = image.getPixel(x + 1, y);
    final top = image.getPixel(x, y - 1);
    final bottom = image.getPixel(x, y + 1);
    
    final centerBrightness = (center.r + center.g + center.b) / 3;
    final avgNeighbor = ((left.r + left.g + left.b) + (right.r + right.g + right.b) + 
                         (top.r + top.g + top.b) + (bottom.r + bottom.g + bottom.b)) / 12;
    
    return (centerBrightness - avgNeighbor).abs() > 30;
  }

  Future<void> _cropAndContinue() async {
    if (originalImage == null) return;
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final transformedImage = await _applyPerspectiveTransform(originalImage!, corners);
      
      final tempDir = Directory.systemTemp;
      final croppedPath = '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      File(croppedPath).writeAsBytesSync(img.encodeJpg(transformedImage, quality: 100));
      
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancementScreen(imagePath: croppedPath),
        ),
      );
    } catch (e) {
      print('Error cropping: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<img.Image> _applyPerspectiveTransform(img.Image image, List<Offset> corners) async {
    final sorted = _sortCorners(corners);
    
    final widthTop = _distance(sorted[0], sorted[1]);
    final widthBottom = _distance(sorted[3], sorted[2]);
    final heightLeft = _distance(sorted[0], sorted[3]);
    final heightRight = _distance(sorted[1], sorted[2]);
    
    final outputWidth = math.max(widthTop, widthBottom).toInt();
    final outputHeight = math.max(heightLeft, heightRight).toInt();
    
    final output = img.Image(width: outputWidth, height: outputHeight);
    
    for (int y = 0; y < outputHeight; y++) {
      for (int x = 0; x < outputWidth; x++) {
        final u = x / (outputWidth - 1);
        final v = y / (outputHeight - 1);
        
        final srcPoint = _getPerspectivePoint(sorted, u, v);
        
        final srcX = srcPoint.dx.clamp(0.0, image.width - 1.0);
        final srcY = srcPoint.dy.clamp(0.0, image.height - 1.0);
        
        final x1 = srcX.floor();
        final y1 = srcY.floor();
        final x2 = (x1 + 1).clamp(0, image.width - 1);
        final y2 = (y1 + 1).clamp(0, image.height - 1);
        
        final dx = srcX - x1;
        final dy = srcY - y1;
        
        final p1 = image.getPixel(x1, y1);
        final p2 = image.getPixel(x2, y1);
        final p3 = image.getPixel(x1, y2);
        final p4 = image.getPixel(x2, y2);
        
        final r = ((1 - dx) * (1 - dy) * p1.r + dx * (1 - dy) * p2.r + 
                   (1 - dx) * dy * p3.r + dx * dy * p4.r).clamp(0, 255).toInt();
        final g = ((1 - dx) * (1 - dy) * p1.g + dx * (1 - dy) * p2.g + 
                   (1 - dx) * dy * p3.g + dx * dy * p4.g).clamp(0, 255).toInt();
        final b = ((1 - dx) * (1 - dy) * p1.b + dx * (1 - dy) * p2.b + 
                   (1 - dx) * dy * p3.b + dx * dy * p4.b).clamp(0, 255).toInt();
        
        output.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    
    return output;
  }

  Offset _getPerspectivePoint(List<Offset> corners, double u, double v) {
    final top = Offset.lerp(corners[0], corners[1], u)!;
    final bottom = Offset.lerp(corners[3], corners[2], u)!;
    return Offset.lerp(top, bottom, v)!;
  }

  double _distance(Offset p1, Offset p2) {
    return math.sqrt(math.pow(p2.dx - p1.dx, 2) + math.pow(p2.dy - p1.dy, 2));
  }

  List<Offset> _sortCorners(List<Offset> corners) {
    final sorted = List<Offset>.from(corners);
    sorted.sort((a, b) => a.dy.compareTo(b.dy));
    
    final top = sorted.sublist(0, 2);
    final bottom = sorted.sublist(2, 4);
    
    top.sort((a, b) => a.dx.compareTo(b.dx));
    bottom.sort((a, b) => a.dx.compareTo(b.dx));
    
    return [top[0], top[1], bottom[1], bottom[0]];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              if (isLoading && originalImage != null) ...[
                const SizedBox(height: 20),
                const Text(
                  'Correcting perspective...',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Adjust Corners'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: uiImage != null && imageSize != null
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final imageAspect = imageSize!.width / imageSize!.height;
                        final containerAspect = constraints.maxWidth / constraints.maxHeight;
                        
                        double displayWidth;
                        double displayHeight;
                        
                        if (imageAspect > containerAspect) {
                          displayWidth = constraints.maxWidth;
                          displayHeight = displayWidth / imageAspect;
                        } else {
                          displayHeight = constraints.maxHeight;
                          displayWidth = displayHeight * imageAspect;
                        }
                        
                        return GestureDetector(
                          onPanStart: (details) {
                            _selectCorner(details.localPosition, displayWidth, displayHeight);
                          },
                          onPanUpdate: (details) {
                            if (selectedCornerIndex != null) {
                              _updateSelectedCorner(details.localPosition, displayWidth, displayHeight);
                            }
                          },
                          onPanEnd: (details) {
                            setState(() {
                              selectedCornerIndex = null;
                            });
                          },
                          child: CustomPaint(
                            size: Size(displayWidth, displayHeight),
                            painter: ImagePainter(uiImage!, corners, imageSize!, selectedCornerIndex),
                          ),
                        );
                      },
                    )
                  : Container(),
            ),
          ),
          
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.black,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Drag corners to document edges • No white borders',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.camera_alt, size: 20),
                          label: const Text('Retake'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _cropAndContinue,
                          icon: const Icon(Icons.check, size: 20),
                          label: const Text('Continue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectCorner(Offset position, double displayWidth, double displayHeight) {
    if (imageSize == null) return;
    
    final scaleX = imageSize!.width / displayWidth;
    final scaleY = imageSize!.height / displayHeight;
    final imagePosition = Offset(position.dx * scaleX, position.dy * scaleY);
    
    int closestIndex = 0;
    double minDistance = double.infinity;
    
    for (int i = 0; i < corners.length; i++) {
      final distance = (corners[i] - imagePosition).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    
    if (minDistance < 100) {
      setState(() {
        selectedCornerIndex = closestIndex;
      });
    }
  }

  void _updateSelectedCorner(Offset position, double displayWidth, double displayHeight) {
    if (selectedCornerIndex == null || imageSize == null) return;
    
    final scaleX = imageSize!.width / displayWidth;
    final scaleY = imageSize!.height / displayHeight;
    final imagePosition = Offset(position.dx * scaleX, position.dy * scaleY);
    
    setState(() {
      corners[selectedCornerIndex!] = Offset(
        imagePosition.dx.clamp(0, imageSize!.width),
        imagePosition.dy.clamp(0, imageSize!.height),
      );
    });
  }
}

class ImagePainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> corners;
  final Size imageSize;
  final int? selectedCornerIndex;

  ImagePainter(this.image, this.corners, this.imageSize, this.selectedCornerIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());
    
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final scaledCorners = corners.map((c) => Offset(c.dx * scaleX, c.dy * scaleY)).toList();
    
    final linePaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final path = Path()
      ..moveTo(scaledCorners[0].dx, scaledCorners[0].dy)
      ..lineTo(scaledCorners[1].dx, scaledCorners[1].dy)
      ..lineTo(scaledCorners[2].dx, scaledCorners[2].dy)
      ..lineTo(scaledCorners[3].dx, scaledCorners[3].dy)
      ..close();
    
    canvas.drawPath(path, linePaint);
    
    final overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final selectionPath = Path()
      ..moveTo(scaledCorners[0].dx, scaledCorners[0].dy)
      ..lineTo(scaledCorners[1].dx, scaledCorners[1].dy)
      ..lineTo(scaledCorners[2].dx, scaledCorners[2].dy)
      ..lineTo(scaledCorners[3].dx, scaledCorners[3].dy)
      ..close();
    
    canvas.drawPath(Path.combine(PathOperation.difference, outerPath, selectionPath), overlayPaint);
    
    for (int i = 0; i < scaledCorners.length; i++) {
      final corner = scaledCorners[i];
      final isSelected = i == selectedCornerIndex;
      
      canvas.drawCircle(corner, isSelected ? 22 : 18, Paint()..color = Colors.white);
      canvas.drawCircle(corner, isSelected ? 18 : 14, Paint()..color = (isSelected ? Colors.yellow : Colors.green));
      
      if (isSelected) {
        _drawMagnifier(canvas, corner, size);
      }
    }
  }

  void _drawMagnifier(Canvas canvas, Offset center, Size canvasSize) {
    final magnifierSize = 140.0;
    final magnification = 4.0;
    
    var magnifierPos = Offset(center.dx, center.dy - magnifierSize - 30);
    if (magnifierPos.dy < 0) magnifierPos = Offset(center.dx, center.dy + magnifierSize + 30);
    if (magnifierPos.dx - magnifierSize/2 < 0) magnifierPos = Offset(magnifierSize/2, magnifierPos.dy);
    if (magnifierPos.dx + magnifierSize/2 > canvasSize.width) magnifierPos = Offset(canvasSize.width - magnifierSize/2, magnifierPos.dy);
    
    canvas.drawCircle(magnifierPos, magnifierSize/2, Paint()..color = Colors.white);
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: magnifierPos, radius: magnifierSize/2)));
    canvas.translate(magnifierPos.dx, magnifierPos.dy);
    canvas.scale(magnification);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()), Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height), Paint());
    canvas.restore();
    canvas.drawCircle(magnifierPos, magnifierSize/2, Paint()..color = Colors.yellow..strokeWidth = 4..style = PaintingStyle.stroke);
    
    final crosshair = Paint()..color = Colors.red..strokeWidth = 2;
    canvas.drawLine(Offset(magnifierPos.dx - 12, magnifierPos.dy), Offset(magnifierPos.dx + 12, magnifierPos.dy), crosshair);
    canvas.drawLine(Offset(magnifierPos.dx, magnifierPos.dy - 12), Offset(magnifierPos.dx, magnifierPos.dy + 12), crosshair);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
