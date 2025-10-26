import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:share_plus/share_plus.dart';
import 'documents_screen.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String pdfPath;

  const PdfPreviewScreen({super.key, required this.pdfPath});

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  int? totalPages;
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Preview'),
        actions: [
          if (totalPages != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('${currentPage + 1}/$totalPages'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _sharePdf(),
            tooltip: 'Share PDF',
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DocumentsScreen()),
              );
            },
            tooltip: 'Go to Documents',
          ),
        ],
      ),
      body: File(widget.pdfPath).existsSync()
          ? PDFView(
              filePath: widget.pdfPath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
              pageSnap: true,
              onRender: (pages) {
                setState(() {
                  totalPages = pages;
                });
              },
              onPageChanged: (page, total) {
                setState(() {
                  currentPage = page ?? 0;
                });
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading PDF: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('PDF file not found'),
                ],
              ),
            ),
    );
  }

  void _sharePdf() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.pdfPath)],
        text: 'Scanned document from ScanVault',
      );
    } catch (e) {
      debugPrint('Share error: $e');
    }
  }
}