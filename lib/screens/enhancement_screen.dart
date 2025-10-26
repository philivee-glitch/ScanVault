import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import '../subscription_manager.dart';
import 'documents_screen.dart';
import 'pdf_preview_screen.dart';
import 'premium_screen.dart';
import 'document_analysis_screen.dart';

class EnhancementScreen extends StatefulWidget {
  final String imagePath;
  final List<String>? additionalPages;

  const EnhancementScreen({
    super.key,
    required this.imagePath,
    this.additionalPages,
  });

  @override
  State<EnhancementScreen> createState() => _EnhancementScreenState();
}

class _EnhancementScreenState extends State<EnhancementScreen> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  String _currentFilter = 'Original';
  int _rotation = 0;
  bool _isProcessing = false;
  String? _processedImagePath;

  final List<String> _filters = ['Original', 'B&W', 'Grayscale', 'Sharp'];

  @override
  void initState() {
    super.initState();
    _processedImagePath = widget.imagePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhance Document'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Image preview
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: _isProcessing
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text('Processing...', style: TextStyle(color: Colors.grey[600])),
                        ],
                      )
                    : _processedImagePath != null
                        ? Image.file(
                            File(_processedImagePath!),
                            fit: BoxFit.contain,
                          )
                        : const Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filters
                const Text('Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _currentFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter, style: const TextStyle(fontSize: 13)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _currentFilter = filter);
                              _applyEnhancements();
                            }
                          },
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                const SizedBox(height: 12),

                const SizedBox(height: 12),

                // Rotation
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _rotation = (_rotation - 90) % 360);
                          _applyEnhancements();
                        },
                        icon: const Icon(Icons.rotate_left, size: 18),
                        label: const Text('Left', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _rotation = (_rotation + 90) % 360);
                          _applyEnhancements();
                        },
                        icon: const Icon(Icons.rotate_right, size: 18),
                        label: const Text('Right', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                

                const SizedBox(height: 12),
                
                // AI ANALYSIS BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _navigateToAIAnalysis,
                    icon: const Icon(Icons.smart_toy, size: 22),
                    label: const Text(
                      'AI ANALYSIS',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _showSaveOptions,
                    icon: const Icon(Icons.save, size: 22),
                    label: const Text(
                      'SAVE DOCUMENT',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyEnhancements() async {
    setState(() => _isProcessing = true);

    try {
      // Process in background to avoid UI lag
      final result = await _processImage(
        widget.imagePath,
        _currentFilter,
        1.0,
          1.0,
        _rotation,
      );

      setState(() {
        _processedImagePath = result;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Enhancement error: $e');
      setState(() => _isProcessing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error applying enhancements'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Optimized image processing - runs in isolate for better performance
  


    Future<String> _processImage(
    String imagePath,
    String filter,
    double contrast,
    double saturation,
    int rotation,
  ) async {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');
    
    // Apply rotation first (fast operation)
    if (rotation != 0) {
      image = img.copyRotate(image, angle: rotation.toDouble());
    }
    
    // Apply contrast and saturation BEFORE filters (except for B&W)
    if (filter != 'B&W' && (contrast != 1.0 || saturation != 1.0)) {
      image = img.adjustColor(
        image,
        contrast: contrast,
        saturation: saturation,
      );
    }
    
    // Apply filter
    switch (filter) {
      case 'B&W':
        // For B&W, apply contrast first to the color image
        if (contrast != 1.0) {
          image = img.adjustColor(image, contrast: contrast);
        }
        // Convert to grayscale
        image = img.grayscale(image);
        // Apply threshold for pure black and white
        for (int y = 0; y < image.height; y++) {
          for (int x = 0; x < image.width; x++) {
            final pixel = image.getPixel(x, y);
            final luminance = img.getLuminance(pixel);
            final newColor = luminance > 128 ? img.ColorRgb8(255, 255, 255) : img.ColorRgb8(0, 0, 0);
            image.setPixel(x, y, newColor);
          }
        }
        break;
      case 'Grayscale':
        image = img.grayscale(image);
        break;
      case 'Sharp':
        image = img.adjustColor(image, contrast: 1.3);
        break;
    }
    
    // Save with good quality but fast encoding
    final tempDir = await getTemporaryDirectory();
    final processedFile = File('${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await processedFile.writeAsBytes(img.encodeJpg(image, quality: 90));
    return processedFile.path;
  }

  void _navigateToAIAnalysis() {
    if (_processedImagePath == null) return;
    
    // Check if user has premium
    if (!_subscriptionManager.canUseAI()) {
      _showPremiumDialog();
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentAnalysisScreen(
          imagePath: _processedImagePath!,
          documentName: 'Scanned Document',
        ),
      ),
    );
  }

  void _showPremiumDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PremiumScreen()),
    );
  }
  Future<void> _showSaveOptions() async {
    final directory = await getApplicationDocumentsDirectory();
    final docDir = Directory('${directory.path}/documents');

    if (!await docDir.exists()) {
      await docDir.create(recursive: true);
    }

    final folders = <String>[];
    await for (var entity in docDir.list()) {
      if (entity is Directory) {
        folders.add(entity.path.split('/').last.split('\\').last);
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Save Document')),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Cancel',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose where to save:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.folder_outlined, color: Colors.blue),
              title: const Text('Documents (Root)'),
              onTap: () {
                Navigator.pop(context);
                _savePDF(null);
              },
            ),
            if (folders.isNotEmpty) ...[
              const Divider(),
              ...folders.map((folder) => ListTile(
                leading: const Icon(Icons.folder, color: Colors.orange),
                title: Text(folder),
                onTap: () {
                  Navigator.pop(context);
                  _savePDF(folder);
                },
              )),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _savePDF(String? folderName) async {
    if (_processedImagePath == null) return;

    setState(() => _isProcessing = true);

    try {
      final pdf = pw.Document();
      final allPages = [_processedImagePath!, ...(widget.additionalPages ?? [])];

      for (String pagePath in allPages) {
        final imageBytes = await File(pagePath).readAsBytes();
        final decodedImage = img.decodeImage(imageBytes);
        
        if (decodedImage == null) continue;

        final image = pw.MemoryImage(imageBytes);

        final pageFormat = PdfPageFormat(
          decodedImage.width.toDouble(),
          decodedImage.height.toDouble(),
          marginAll: 0,
        );

        pdf.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  pw.Positioned.fill(
                    child: pw.Image(
                      image, 
                      fit: pw.BoxFit.cover,
                    ),
                  ),
                  if (!_subscriptionManager.isPremium)
                    pw.Positioned(
                      bottom: 30,
                      right: 30,
                      child: pw.Opacity(
                        opacity: 0.25,
                        child: pw.Text(
                          'ScanVault',
                          style: pw.TextStyle(
                            fontSize: 72,
                            color: PdfColors.grey700,
                            fontWeight: pw.FontWeight.bold,
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

      final directory = await getApplicationDocumentsDirectory();
      final savePath = folderName != null
          ? '${directory.path}/documents/$folderName'
          : '${directory.path}/documents';

      final saveDir = Directory(savePath);
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }

      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('$savePath/$fileName');
      await file.writeAsBytes(await pdf.save());

      setState(() => _isProcessing = false);

      if (mounted) {
        _showSuccessDialog(file.path, fileName, folderName);
      }
    } catch (e) {
      debugPrint('Save PDF error: $e');
      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String pdfPath, String fileName, String? folderName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Expanded(child: Text('PDF Saved!')),
            IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DocumentsScreen()),
                );
              },
              tooltip: 'Close',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your document has been saved successfully.'),
            if (folderName != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.folder, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text(
                      'Saved in: $folderName',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'What would you like to do next?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DocumentsScreen()),
              );
            },
            child: const Text('Done'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfPreviewScreen(pdfPath: pdfPath),
                ),
              );
            },
            icon: const Icon(Icons.visibility),
            label: const Text('View PDF'),
          ),
        ],
      ),
    );
  }
}










