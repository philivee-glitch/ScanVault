import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'pdf_preview_screen.dart';
import '../subscription_manager.dart';

class Document {
  final String name;
  final String path;
  final DateTime date;
  final int size;
  final String? folder;

  Document({
    required this.name,
    required this.path,
    required this.date,
    required this.size,
    this.folder,
  });
}

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  List<Document> _documents = [];
  List<String> _folders = [];
  bool _isLoading = true;
  String? _selectedFolder;

  // Multi-select mode
  bool _isSelectionMode = false;
  Set<String> _selectedDocuments = {};

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final docDir = Directory('${directory.path}/documents');

      if (!await docDir.exists()) {
        await docDir.create(recursive: true);
      }

      // Load folders
      final folders = <String>[];
      await for (var entity in docDir.list()) {
        if (entity is Directory) {
          folders.add(entity.path.split('/').last.split('\\').last);
        }
      }

      // Load documents
      final documents = <Document>[];

      if (_selectedFolder == null) {
        // Load documents from root
        await for (var entity in docDir.list()) {
          if (entity is File && entity.path.endsWith('.pdf')) {
            final stat = await entity.stat();
            documents.add(Document(
              name: entity.path.split('/').last.split('\\').last,
              path: entity.path,
              date: stat.modified,
              size: stat.size,
              folder: null,
            ));
          }
        }
      } else {
        // Load documents from selected folder
        final folderDir = Directory('${docDir.path}/$_selectedFolder');
        if (await folderDir.exists()) {
          await for (var entity in folderDir.list()) {
            if (entity is File && entity.path.endsWith('.pdf')) {
              final stat = await entity.stat();
              documents.add(Document(
                name: entity.path.split('/').last.split('\\').last,
                path: entity.path,
                date: stat.modified,
                size: stat.size,
                folder: _selectedFolder,
              ));
            }
          }
        }
      }

      documents.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _documents = documents;
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load documents error: $e');
      setState(() => _isLoading = false);
    }
  }

    });
  }

  void _showPremiumFeatureDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Feature'),
          ],
        ),
        content: Text(
          '$featureName is a premium feature.\n\nUpgrade to Premium for:\n• Unlimited scans\n• Batch operations\n• AI Analysis & OCR\n• No watermarks\n• And more!\n\nOnly \$4.99/month',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium purchase coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _toggleDocumentSelection(String path) {
    setState(() {
      if (_selectedDocuments.contains(path)) {
        _selectedDocuments.remove(path);
      } else {
        _selectedDocuments.add(path);
      }

      // Exit selection mode if nothing selected
      if (_selectedDocuments.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedDocuments = _documents.map((doc) => doc.path).toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedDocuments.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode
            ? '${_selectedDocuments.length} selected'
            : _selectedFolder ?? 'Documents'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _deselectAll,
              )
            : _selectedFolder != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() => _selectedFolder = null);
                      _loadDocuments();
                    },
                  )
                : null,
        actions: _isSelectionMode
            ? [
                if (_selectedDocuments.length < _documents.length)
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: _selectAll,
                    tooltip: 'Select All',
                  ),
                if (_selectedFolder == null)
                  IconButton(
                    icon: const Icon(Icons.drive_file_move),
                    onPressed: _showBatchMoveDialog,
                    tooltip: 'Move to Folder',
                  ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: _showBatchDeleteDialog,
                  tooltip: 'Delete',
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: DocumentSearchDelegate(_documents),
                    );
                  },
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _isSelectionMode
          ? null
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_selectedFolder == null)
                  FloatingActionButton(
                    heroTag: 'create_folder',
                    onPressed: _showCreateFolderDialog,
                    mini: true,
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.create_new_folder),
                  ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'scan',
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
    );
  }

  Widget _buildBody() {
    if (_selectedFolder == null && _folders.isEmpty && _documents.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 100, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No documents yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Scan your first document to get started',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          if (_selectedFolder == null && _folders.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Folders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ..._folders.map((folder) => Card(
              child: ListTile(
                leading: const Icon(Icons.folder, color: Colors.orange, size: 32),
                title: Text(folder, style: const TextStyle(fontWeight: FontWeight.w500)),
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.edit, size: 20),
                        title: Text('Rename'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _showRenameFolderDialog(folder);
                        });
                      },
                    ),
                    PopupMenuItem(
                      child: const ListTile(
                        leading: Icon(Icons.delete, size: 20, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onTap: () {
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _deleteFolder(folder);
                        });
                      },
                    ),
                  ],
                ),
                onTap: () {
                  setState(() => _selectedFolder = folder);
                  _loadDocuments();
                },
              ),
            )),
            const SizedBox(height: 16),
            const Divider(),
          ],
          if (_documents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _selectedFolder == null ? 'Recent Documents' : 'Documents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ..._documents.map((doc) => Card(
              child: ListTile(
                leading: _isSelectionMode
                    ? Checkbox(
                        value: _selectedDocuments.contains(doc.path),
                        onChanged: (value) => _toggleDocumentSelection(doc.path),
                      )
                    : const Icon(Icons.picture_as_pdf, color: Colors.red, size: 32),
                title: Text(doc.name),
                subtitle: Text('${_formatDate(doc.date)} | ${_formatSize(doc.size)}'),
                trailing: _isSelectionMode
                    ? null
                    : PopupMenuButton(
                        icon: const Icon(Icons.more_vert),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: const ListTile(
                              leading: Icon(Icons.visibility, size: 20),
                              title: Text('View'),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 100), () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PdfPreviewScreen(pdfPath: doc.path),
                                  ),
                                );
                              });
                            },
                          ),
                          PopupMenuItem(
                            child: const ListTile(
                              leading: Icon(Icons.smart_toy, size: 20, color: Colors.blue),
                              title: Text('AI Analysis'),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 100), () {
                                _showAIAnalysisOption(doc);
                              });
                            },
                          ),
                          PopupMenuItem(
                            child: const ListTile(
                              leading: Icon(Icons.edit, size: 20),
                              title: Text('Rename'),
                              contentPadding: EdgeInsets.zero,
                            ),

                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 100), () {
                                _showRenameDocumentDialog(doc);
                              });
                            },
                          ),
                          PopupMenuItem(
                            child: const ListTile(
                              leading: Icon(Icons.share, size: 20),
                              title: Text('Share'),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 100), () {
                                Share.shareXFiles([XFile(doc.path)]);
                              });
                            },
                          ),
                          if (_selectedFolder == null)
                            PopupMenuItem(
                              child: const ListTile(
                                leading: Icon(Icons.drive_file_move, size: 20),
                                title: Text('Move to Folder'),
                                contentPadding: EdgeInsets.zero,
                              ),
                              onTap: () {
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  _showMoveToFolderDialog(doc);
                                });
                              },
                            ),
                          PopupMenuItem(
                            child: const ListTile(
                              leading: Icon(Icons.delete, size: 20, color: Colors.red),
                              title: Text('Delete', style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                            onTap: () {
                              Future.delayed(const Duration(milliseconds: 100), () {
                                _deleteDocument(doc);
                              });
                            },
                          ),
                        ],
                      ),
                onTap: () {
                  if (_isSelectionMode) {
                    _toggleDocumentSelection(doc.path);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfPreviewScreen(pdfPath: doc.path),
                      ),
                    );
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    setState(() => _isSelectionMode = true);
                    _toggleDocumentSelection(doc.path);
                  }
                },
              ),
            )),
          ] else if (_selectedFolder != null) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.folder_open, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'This folder is empty',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showBatchMoveDialog() {
    if (_folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No folders available. Create a folder first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move ${_selectedDocuments.length} documents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _folders.map((folder) {
            return ListTile(
              leading: const Icon(Icons.folder),
              title: Text(folder),
              onTap: () async {
                await _batchMoveToFolder(folder);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _batchMoveToFolder(String folderName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      
      for (String path in _selectedDocuments) {
        final file = File(path);
        final fileName = path.split('/').last.split('\\').last;
        final newPath = '${directory.path}/documents/$folderName/$fileName';
        await file.rename(newPath);
      }

      setState(() {
        _selectedDocuments.clear();
        _isSelectionMode = false;
      });
      
      await _loadDocuments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Moved to "$folderName"')),
      );
    } catch (e) {
      debugPrint('Batch move error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error moving documents')),
      );
    }
  }

  void _showBatchDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Documents'),
        content: Text('Delete ${_selectedDocuments.length} selected documents?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _batchDelete();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _batchDelete() async {
    try {
      for (String path in _selectedDocuments) {
        await File(path).delete();
      }

      setState(() {
        _selectedDocuments.clear();
        _isSelectionMode = false;
      });
      
      await _loadDocuments();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Documents deleted')),
      );
    } catch (e) {
      debugPrint('Batch delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting documents')),
      );
    }
  }

  void _showCreateFolderDialog() {
    // Check folder limit
    if (_folders.length >= _subscriptionManager.getMaxFolders()) {
      _showPremiumFeatureDialog('Unlimited Folders');
      return;
    }
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder Name',
            hintText: 'Enter folder name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final folderName = controller.text.trim();
              if (folderName.isNotEmpty) {
                await _createFolder(folderName);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createFolder(String folderName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final folderDir = Directory('${directory.path}/documents/$folderName');

      if (await folderDir.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder "$folderName" already exists')),
        );
        return;
      }

      await folderDir.create(recursive: true);
      await _loadDocuments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder "$folderName" created')),
      );
    } catch (e) {
      debugPrint('Create folder error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error creating folder')),
      );
    }
  }

  void _showRenameFolderDialog(String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                await _renameFolder(oldName, newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameFolder(String oldName, String newName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final oldDir = Directory('${directory.path}/documents/$oldName');
      final newDir = Directory('${directory.path}/documents/$newName');

      if (await newDir.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folder "$newName" already exists')),
        );
        return;
      }

      await oldDir.rename(newDir.path);
      await _loadDocuments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Folder renamed to "$newName"')),
      );
    } catch (e) {
      debugPrint('Rename folder error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error renaming folder')),
      );
    }
  }

  void _showRenameDocumentDialog(Document doc) {
    final currentName = doc.name.replaceAll('.pdf', '');
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Name',
            suffixText: '.pdf',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != currentName) {
                await _renameDocument(doc, newName);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  Future<void> _renameDocument(Document doc, String newName) async {
    try {
      final file = File(doc.path);
      final directory = file.parent.path;
      final newPath = '$directory/$newName.pdf';

      if (await File(newPath).exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('A document with name "$newName.pdf" already exists')),
        );
        return;
      }

      await file.rename(newPath);
      await _loadDocuments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Document renamed to "$newName.pdf"')),
      );
    } catch (e) {
      debugPrint('Rename document error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error renaming document')),
      );
    }
  }

  Future<void> _deleteFolder(String folderName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder'),
        content: Text('Delete "$folderName" and all its contents?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final folderDir = Directory('${directory.path}/documents/$folderName');
        await folderDir.delete(recursive: true);
        await _loadDocuments();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Folder deleted')),
        );
      } catch (e) {
        debugPrint('Delete folder error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting folder')),
        );
      }
    }
  }

  void _showMoveToFolderDialog(Document doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _folders.map((folder) {
            return ListTile(
              leading: const Icon(Icons.folder),
              title: Text(folder),
              onTap: () async {
                await _moveToFolder(doc, folder);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _moveToFolder(Document doc, String folderName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final newPath = '${directory.path}/documents/$folderName/${doc.name}';
      await File(doc.path).rename(newPath);
      await _loadDocuments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Moved to "$folderName"')),
      );
    } catch (e) {
      debugPrint('Move document error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error moving document')),
      );
    }
  }

  Future<void> _deleteDocument(Document doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${doc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await File(doc.path).delete();
        await _loadDocuments();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
      } catch (e) {
        debugPrint('Delete document error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting document')),
        );
      }
    }
  }


  void _showAIAnalysisOption(Document doc) {
    // For PDF documents, we need to extract the first page as an image
    // Since we don't have the original image, show a dialog explaining this
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.blue),
            SizedBox(width: 8),
            Text('AI Analysis'),
          ],
        ),
        content: const Text(
          'AI Analysis works best with the original scanned image.\n\n'
          'To analyze this document:\n'
          '1. Scan a new document\n'
          '2. Select "AI Analysis" from the preview screen\n\n'
          'Would you like to scan a new document now?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to scan
            },
            child: const Text('Scan New Document'),
          ),
        ],
      ),
    );
  }
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class DocumentSearchDelegate extends SearchDelegate<Document?> {
  final List<Document> documents;

  DocumentSearchDelegate(this.documents);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = documents.where((doc) {
      return doc.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final doc = results[index];
        return ListTile(
          leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
          title: Text(doc.name),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfPreviewScreen(pdfPath: doc.path),
              ),
            );
          },
        );
      },
    );
  }
}
