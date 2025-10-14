import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../ad_helper.dart';

enum FilterType { original, blackWhite, grayscale, colorEnhanced }

class EnhancementScreen extends StatefulWidget {
  final String imagePath;
  final List<String>? allPages;

  const EnhancementScreen({
    super.key, 
    required this.imagePath,
    this.allPages,
  });

  @override
  State<EnhancementScreen> createState() => _EnhancementScreenState();
}

class _EnhancementScreenState extends State<EnhancementScreen> {
  FilterType selectedFilter = FilterType.original;
  double brightness = 0;
  double contrast = 100;
  int rotation = 0;
  img.Image? originalImage;
  String? displayImagePath;
  bool isProcessing = false;
  bool showAdvanced = false;
  int currentPageIndex = 0;
  List<String> processedPages = [];

  @override
  void initState() {
    super.initState();
    if (widget.allPages != null) {
      processedPages = List.from(widget.allPages!);
      currentPageIndex = processedPages.length - 1;
    }
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    
    if (image != null) {
      setState(() {
        originalImage = image;
        displayImagePath = widget.imagePath;
      });
    }
  }

  Future<void> _updatePreview() async {
    if (originalImage == null) return;
    
    setState(() {
      isProcessing = true;
    });

    img.Image result = img.Image.from(originalImage!);
    
    if (rotation != 0) {
      result = img.copyRotate(result, angle: rotation);
    }
    
    switch (selectedFilter) {
      case FilterType.blackWhite:
        result = img.grayscale(result);
        result = img.contrast(result, contrast: 150);
        break;
      case FilterType.grayscale:
        result = img.grayscale(result);
        break;
      case FilterType.colorEnhanced:
        result = img.adjustColor(result, saturation: 1.5, contrast: 1.2, brightness: 1.1);
        break;
      case FilterType.original:
        break;
    }
    
    if (contrast != 100 && selectedFilter == FilterType.original) {
      result = img.contrast(result, contrast: contrast);
    }
    
    if (brightness != 0) {
      final brightnessValue = brightness.toInt();
      for (int y = 0; y < result.height; y++) {
        for (int x = 0; x < result.width; x++) {
          final pixel = result.getPixel(x, y);
          final r = (pixel.r + brightnessValue).clamp(0, 255).toInt();
          final g = (pixel.g + brightnessValue).clamp(0, 255).toInt();
          final b = (pixel.b + brightnessValue).clamp(0, 255).toInt();
          result.setPixelRgba(x, y, r, g, b, pixel.a.toInt());
        }
      }
    }
    
    final tempDir = await getTemporaryDirectory();
    final path = '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    File(path).writeAsBytesSync(img.encodeJpg(result, quality: 95));
    
    setState(() {
      displayImagePath = path;
      isProcessing = false;
    });
  }

  Future<List<String>> _getFolders() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/documents');
      
      if (await docsDir.exists()) {
        final entities = docsDir.listSync();
        return entities
            .whereType<Directory>()
            .map((d) => d.path.split('/').last)
            .toList();
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }

  Future<void> _saveDocument() async {
    if (displayImagePath == null) return;

    final folders = await _getFolders();
    
    String? targetFolder;
    
    if (folders.isNotEmpty && mounted) {
      targetFolder = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save to Folder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_open),
                title: const Text('Root (No folder)'),
                onTap: () => Navigator.pop(context, ''),
              ),
              ...folders.map((folder) => ListTile(
                    leading: const Icon(Icons.folder),
                    title: Text(folder),
                    onTap: () => Navigator.pop(context, folder),
                  )),
            ],
          ),
        ),
      );
      
      if (targetFolder == null) return;
    } else {
      targetFolder = '';
    }
    
    setState(() {
      isProcessing = true;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/documents');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }
      
      final savePath = targetFolder.isEmpty 
          ? docsDir.path 
          : '${docsDir.path}/$targetFolder';
      
      processedPages[currentPageIndex] = displayImagePath!;
      
      final pdf = pw.Document();
      
      for (final pagePath in processedPages) {
        final imageBytes = await File(pagePath).readAsBytes();
        final image = pw.MemoryImage(imageBytes);
        
        final img.Image? imgData = img.decodeImage(imageBytes);
        if (imgData != null) {
          final pageWidth = imgData.width.toDouble();
          final pageHeight = imgData.height.toDouble();
          
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat(pageWidth, pageHeight),
              margin: pw.EdgeInsets.zero,
              build: (pw.Context context) {
                return pw.Image(image, fit: pw.BoxFit.fill);
              },
            ),
          );
        }
      }
      
      final pdfPath = '$savePath/doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
      await File(pdfPath).writeAsBytes(await pdf.save());
      
      if (!mounted) return;
      
      final folderMsg = targetFolder.isEmpty ? '' : ' to $targetFolder';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Document saved$folderMsg ( page)'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Show interstitial ad after saving document (frequency-capped: every 3rd save)
      AdHelper.showInterstitialAdAfterSave();
      
      Navigator.popUntil(context, (route) => route.isFirst);
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _rotateImage() {
    setState(() {
      rotation = (rotation + 90) % 360;
    });
    _updatePreview();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final pageCount = processedPages.length;
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(pageCount > 1 ? 'Page  of $pageCount' : 'Enhance'),
        actions: [
          if (pageCount > 1)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$pageCount pages',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.check_circle),
            onPressed: isProcessing ? null : _saveDocument,
            tooltip: 'Save PDF',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.black,
              child: Center(
                child: isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : displayImagePath != null
                        ? Image.file(File(displayImagePath!), fit: BoxFit.contain)
                        : Container(),
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.grey[900],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip('Original', FilterType.original),
                _buildFilterChip('B&W', FilterType.blackWhite),
                _buildFilterChip('Gray', FilterType.grayscale),
                _buildFilterChip('Color+', FilterType.colorEnhanced),
              ],
            ),
          ),
          
          Container(
            color: Colors.grey[850],
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickAction(
                        Icons.rotate_right,
                        'Rotate',
                        _rotateImage,
                      ),
                      _buildQuickAction(
                        showAdvanced ? Icons.expand_less : Icons.tune,
                        showAdvanced ? 'Less' : 'Adjust',
                        () {
                          setState(() {
                            showAdvanced = !showAdvanced;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                
                if (showAdvanced)
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 8),
                        _buildSlider(
                          'Brightness',
                          Icons.brightness_6,
                          brightness,
                          -50,
                          50,
                          (value) => setState(() => brightness = value),
                          _updatePreview,
                        ),
                        const SizedBox(height: 8),
                        _buildSlider(
                          'Contrast',
                          Icons.contrast,
                          contrast,
                          50,
                          150,
                          (value) => setState(() => contrast = value),
                          _updatePreview,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, FilterType filter) {
    final isSelected = selectedFilter == filter;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = filter;
        });
        _updatePreview();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[800],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    VoidCallback onChangeEnd,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const Spacer(),
            Text(
              value.toInt().toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).toInt(),
          onChanged: onChanged,
          onChangeEnd: (val) => onChangeEnd(),
        ),
      ],
    );
  }
}
