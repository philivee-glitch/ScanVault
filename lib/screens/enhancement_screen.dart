import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import '../subscription_manager.dart';
import 'document_analysis_screen.dart';
import 'documents_screen.dart';
import 'pdf_preview_screen.dart';

class EnhancementScreen extends StatefulWidget {
  final String imagePath;
  final List<String>? additionalPages;

  const EnhancementScreen({
    Key? key,
    required this.imagePath,
    this.additionalPages,
  }) : super(key: key);

  @override
  State<EnhancementScreen> createState() => _EnhancementScreenState();
}

class _EnhancementScreenState extends State<EnhancementScreen> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();

  String _currentFilter = 'Original';
  double _contrast = 1.0;
  int _rotation = 0;
  bool _isProcessing = false;
  String? _processedImagePath;
  List<String> _allPages = [];

  final List<String> _filters = ['Original', 'B&W', 'Grayscale', 'Color+'];

  @override
  void initState() {
    super.initState();
    _processedImagePath = widget.imagePath;
    _allPages = [widget.imagePath, ...(widget.additionalPages ?? [])];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enhance Document'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Image preview - takes most of the space
          Expanded(
            child: Container(
              color: Colors.grey[200],
              child: Center(
                child: _isProcessing
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Processing...', style: TextStyle(color: Colors.grey[600])),
                        ],
                      )
                    : _processedImagePath != null
                        ? Image.file(
                            File(_processedImagePath!),
                            fit: BoxFit.contain,
                          )
                        : Icon(Icons.image, size: 100, color: Colors.grey),
              ),
            ),
          ),

          // Controls - compact, no scrolling needed
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
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
                Text('Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _currentFilter == filter;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter, style: TextStyle(fontSize: 13)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _currentFilter = filter);
                              _applyEnhancements();
                            }
                          },
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Contrast - compact
                Row(
                  children: [
                    Text('Contrast', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Expanded(
                      child: Slider(
                        value: _contrast,
                        min: 0.5,
                        max: 2.0,
                        divisions: 30,
                        onChanged: (value) {
                          setState(() => _contrast = value);
                        },
                        onChangeEnd: (value) => _applyEnhancements(),
                      ),
                    ),
                    Text(_contrast.toStringAsFixed(1), style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                
                SizedBox(height: 8),
                
                // Rotation buttons - compact
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _rotation = (_rotation - 90) % 360);
                          _applyEnhancements();
                        },
                        icon: Icon(Icons.rotate_left, size: 18),
                        label: Text('Left', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _rotation = (_rotation + 90) % 360);
                          _applyEnhancements();
                        },
                        icon: Icon(Icons.rotate_right, size: 18),
                        label: Text('Right', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                // SAVE BUTTON - always visible
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _showSaveOptions,
                    icon: Icon(Icons.save, size: 22),
                    label: Text(
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
      final bytes = await File(widget.imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) return;

      // Apply rotation first
      if (_rotation != 0) {
        image = img.copyRotate(image, angle: _rotation.toDouble());
      }

      // Apply filter
      switch (_currentFilter) {
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
      }

      // Apply contrast adjustment
      if (_contrast != 1.0) {
        image = img.adjustColor(image, contrast: _contrast);
      }

      final tempDir = await getTemporaryDirectory();
      final processedFile = File('${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await processedFile.writeAsBytes(img.encodeJpg(image, quality: 95));

      setState(() {
        _processedImagePath = processedFile.path;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Enhancement error: $e');
      setState(() => _isProcessing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error applying enhancements'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showSaveOptions() async {
    final directory = await getApplicationDocumentsDirectory();
    final docDir = Directory('${directory.path}/documents');

    if (!await docDir.exists()) {
      await docDir.create(recursive: true);
    }

    // Load available folders
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
            Expanded(child: Text('Save Document')),
            IconButton(
              icon: Icon(Icons.close, size: 20),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Cancel',
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose where to save:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.folder_outlined, color: Colors.blue),
              title: Text('Documents (Root)'),
              onTap: () {
                Navigator.pop(context);
                _savePDF(null);
              },
            ),
            if (folders.isNotEmpty) ...[
              Divider(),
              ...folders.map((folder) => ListTile(
                leading: Icon(Icons.folder, color: Colors.orange),
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
                        opacity: 0.3,
                        child: pw.Text(
                          'ScanVault',
                          style: pw.TextStyle(
                            fontSize: 24,
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
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Expanded(child: Text('PDF Saved!')),
            IconButton(
              icon: Icon(Icons.close, size: 20),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DocumentsScreen()),
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
            Text('Your document has been saved successfully.'),
            if (folderName != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.folder, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Saved in: $folderName',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16),
            Text(
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
                MaterialPageRoute(builder: (context) => DocumentsScreen()),
              );
            },
            child: Text('Done'),
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
            icon: Icon(Icons.visibility),
            label: Text('View PDF'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentAnalysisScreen(
                    imagePath: _processedImagePath!,
                    documentName: fileName,
                  ),
                ),
              );
            },
            icon: Icon(Icons.text_fields),
            label: Text('Extract Text'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
