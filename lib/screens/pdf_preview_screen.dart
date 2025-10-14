import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';

class PdfPreviewScreen extends StatefulWidget {
  final String pdfPath;
  final String documentName;

  const PdfPreviewScreen({
    super.key,
    required this.pdfPath,
    required this.documentName,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  int currentPage = 0;
  int totalPages = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documentName,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            if (totalPages > 0)
              Text(
                'Page ${currentPage + 1} of $totalPages',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.pdfPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              setState(() {
                totalPages = pages ?? 0;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = 'Error on page ' + page.toString() + ': ' + error.toString();
              });
            },
            onViewCreated: (PDFViewController pdfViewController) {
              // Controller ready
            },
            onPageChanged: (int? page, int? total) {
              setState(() {
                currentPage = page ?? 0;
                totalPages = total ?? 0;
              });
            },
          ),
          if (!isReady && errorMessage.isEmpty)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (errorMessage.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading PDF',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
