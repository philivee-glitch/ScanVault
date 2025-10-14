import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;
import 'enhancement_screen.dart';

class CornerAdjustmentScreen extends StatefulWidget {
  final String imagePath;

  const CornerAdjustmentScreen({super.key, required this.imagePath});

  @override
  State<CornerAdjustmentScreen> createState() => _CornerAdjustmentScreenState();
}

class _CornerAdjustmentScreenState extends State<CornerAdjustmentScreen> {
  late List<Offset> corners;
  img.Image? image;
  Size? imageSize;
  int? draggedCorner;
  bool isProcessing = false;
  bool showPreview = false;
  String? previewPath;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    
    if (decodedImage != null) {
      setState(() {
        image = decodedImage;
        imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
        // Auto-detect document edges
        corners = _detectDocumentCorners(decodedImage);
      });
    }
  }

  List<Offset> _detectDocumentCorners(img.Image image) {
    // Simple edge detection - find the largest bright rectangle
    final w = image.width;
    final h = image.height;
    
    // Start with conservative default positions
    return [
      Offset(w * 0.1, h * 0.1),   // TL
      Offset(w * 0.9, h * 0.1),   // TR
      Offset(w * 0.9, h * 0.9),   // BR
      Offset(w * 0.1, h * 0.9),   // BL
    ];
  }

  Future<void> _generatePreview() async {
    if (image == null) return;
    
    setState(() {
      isProcessing = true;
    });

    try {
      final cropped = await _cropImage();
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/preview_${DateTime.now().millisecondsSinceEpoch}.jpg';
      File(path).writeAsBytesSync(img.encodeJpg(cropped, quality: 85));
      
      setState(() {
        previewPath = path;
        showPreview = true;
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<img.Image> _cropImage() async {
    final topLeft = img.Point(corners[0].dx.round(), corners[0].dy.round());
    final topRight = img.Point(corners[1].dx.round(), corners[1].dy.round());
    final bottomRight = img.Point(corners[2].dx.round(), corners[2].dy.round());
    final bottomLeft = img.Point(corners[3].dx.round(), corners[3].dy.round());

    final topWidth = math.sqrt(
      math.pow(corners[1].dx - corners[0].dx, 2) + 
      math.pow(corners[1].dy - corners[0].dy, 2)
    );
    final bottomWidth = math.sqrt(
      math.pow(corners[2].dx - corners[3].dx, 2) + 
      math.pow(corners[2].dy - corners[3].dy, 2)
    );
    final leftHeight = math.sqrt(
      math.pow(corners[3].dx - corners[0].dx, 2) + 
      math.pow(corners[3].dy - corners[0].dy, 2)
    );
    final rightHeight = math.sqrt(
      math.pow(corners[2].dx - corners[1].dx, 2) + 
      math.pow(corners[2].dy - corners[1].dy, 2)
    );

    final width = ((topWidth + bottomWidth) / 2).round();
    final height = ((leftHeight + rightHeight) / 2).round();

    return img.copyRectify(
      image!,
      topLeft: topLeft,
      topRight: topRight,
      bottomRight: bottomRight,
      bottomLeft: bottomLeft,
      toImage: img.Image(width: width, height: height),
      interpolation: img.Interpolation.cubic,
    );
  }

  Future<void> _cropAndContinue() async {
    if (image == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final transformed = await _cropImage();

      final tempDir = await getTemporaryDirectory();
      final croppedPath = '${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
      File(croppedPath).writeAsBytesSync(img.encodeJpg(transformed, quality: 100));

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancementScreen(imagePath: croppedPath),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(showPreview ? 'Preview' : 'Adjust Corners'),
        leading: showPreview
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    showPreview = false;
                  });
                },
              )
            : null,
        actions: [
          if (!showPreview)
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: isProcessing ? null : _generatePreview,
              tooltip: 'Preview',
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: isProcessing ? null : _cropAndContinue,
            tooltip: 'Continue',
          ),
        ],
      ),
      body: imageSize == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : showPreview && previewPath != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Image.file(
                          File(previewPath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'This is how your document will look after cropping',
                          style: TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final scale = constraints.maxWidth / imageSize!.width;
                    
                    return Stack(
                      children: [
                        Center(
                          child: Image.file(
                            File(widget.imagePath),
                            width: constraints.maxWidth,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                        
                        CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: CornersPainter(
                            corners: corners.map((c) => Offset(c.dx * scale, c.dy * scale)).toList(),
                          ),
                        ),
                        
                        ...List.generate(4, (index) {
                          final corner = Offset(corners[index].dx * scale, corners[index].dy * scale);
                          final labels = ['TL', 'TR', 'BR', 'BL'];
                          
                          return Positioned(
                            left: corner.dx - 30,
                            top: corner.dy - 30,
                            child: GestureDetector(
                              onPanStart: (_) {
                                setState(() {
                                  draggedCorner = index;
                                });
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  final newX = (corner.dx + details.delta.dx) / scale;
                                  final newY = (corner.dy + details.delta.dy) / scale;
                                  corners[index] = Offset(
                                    newX.clamp(0.0, imageSize!.width),
                                    newY.clamp(0.0, imageSize!.height),
                                  );
                                });
                              },
                              onPanEnd: (_) {
                                setState(() {
                                  draggedCorner = null;
                                });
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: draggedCorner == index 
                                      ? Colors.blue.withOpacity(0.9)
                                      : Colors.green.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.6),
                                      blurRadius: 10,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    labels[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Drag corners to document edges • Tap ?? to preview',
                                style: TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}

class CornersPainter extends CustomPainter {
  final List<Offset> corners;

  CornersPainter({required this.corners});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = Colors.green.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(corners[0].dx, corners[0].dy)
      ..lineTo(corners[1].dx, corners[1].dy)
      ..lineTo(corners[2].dx, corners[2].dy)
      ..lineTo(corners[3].dx, corners[3].dy)
      ..close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
