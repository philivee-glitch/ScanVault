import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'enhancement_screen.dart';

class CameraScreen extends StatefulWidget {
  final dynamic camera;
  
  const CameraScreen({super.key, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  List<String> scannedPages = [];
  bool hasScanned = false;
  
  Future<void> _scanDocument() async {
    try {
      List<String> pictures = await CunningDocumentScanner.getPictures(
        noOfPages: 10, // Allow up to 10 pages
      ) ?? [];
      
      if (pictures.isEmpty) {
        if (!hasScanned && mounted) {
          Navigator.pop(context); // Go back if user cancelled on first scan
        }
        return;
      }
      
      setState(() {
        scannedPages.addAll(pictures);
        hasScanned = true;
      });
      
      if (!mounted) return;
      
      // Go to enhancement with all scanned pages
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancementScreen(
            imagePath: scannedPages.last,
            allPages: scannedPages,
          ),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!hasScanned) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scanDocument();
      });
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: scannedPages.isNotEmpty
          ? AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(' page scanned'),
            )
          : null,
      body: scannedPages.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: scannedPages.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          leading: Image.file(
                            File(scannedPages[index]),
                            width: 60,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                          title: Text('Page '),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                scannedPages.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _scanDocument,
                          icon: const Icon(Icons.add),
                          label: const Text('Add More Pages'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: scannedPages.isEmpty
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EnhancementScreen(
                                        imagePath: scannedPages.last,
                                        allPages: scannedPages,
                                      ),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.check),
                          label: const Text('Continue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
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
}
