import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class DocumentsListScreen extends StatefulWidget {
  const DocumentsListScreen({super.key});

  @override
  State<DocumentsListScreen> createState() => _DocumentsListScreenState();
}

class _DocumentsListScreenState extends State<DocumentsListScreen> {
  List<FileSystemEntity> documents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/documents');
      
      if (await docsDir.exists()) {
        final files = docsDir.listSync();
        // Only get PDF files
        final pdfFiles = files.where((file) => file.path.endsWith('.pdf')).toList();
        pdfFiles.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
        
        setState(() {
          documents = pdfFiles;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading documents: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteDocument(String path) async {
    try {
      final file = File(path);
      await file.delete();
      
      // Also delete associated image
      final imagePath = path.replaceAll('.pdf', '.jpg');
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      
      _loadDocuments();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting: $e')),
      );
    }
  }

  Future<void> _shareDocument(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      
      await Printing.sharePdf(
        bytes: bytes,
        filename: path.split('/').last,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: $e')),
      );
    }
  }

  Future<void> _previewDocument(String path) async {
    try {
      final file = File(path);
      final bytes = await file.readAsBytes();
      
      await Printing.layoutPdf(
        onLayout: (format) async => bytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}// ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Saved Documents'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : documents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No documents yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Scan your first document to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDocuments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      final stat = doc.statSync();
                      final fileName = doc.path.split('/').last;
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                          title: Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _formatDate(stat.modified),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'open':
                                  _previewDocument(doc.path);
                                  break;
                                case 'share':
                                  _shareDocument(doc.path);
                                  break;
                                case 'delete':
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Document'),
                                      content: const Text('Are you sure you want to delete this document?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _deleteDocument(doc.path);
                                          },
                                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'open',
                                child: Row(
                                  children: [
                                    Icon(Icons.open_in_new),
                                    SizedBox(width: 10),
                                    Text('Open'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'share',
                                child: Row(
                                  children: [
                                    Icon(Icons.share),
                                    SizedBox(width: 10),
                                    Text('Share/Email'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 10),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _previewDocument(doc.path),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
