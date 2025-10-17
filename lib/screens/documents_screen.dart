import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'pdf_preview_screen.dart';

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
  const DocumentsScreen({Key? key}) : super(key: key);

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
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

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedDocuments.clear();
      }
    });
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
                icon: Icon(Icons.close),
                onPressed: _deselectAll,
              )
            : _selectedFolder != null
                ? IconButton(
                    icon: Icon(Icons.arrow_back),
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
                    icon: Icon(Icons.select_all),
                    onPressed: _selectAll,
                    tooltip: 'Select All',
                  ),
                if (_selectedFolder == null)
                  IconButton(
                    icon: Icon(Icons.drive_file_move),
                    onPressed: _showBatchMoveDialog,
                    tooltip: 'Move to Folder',
                  ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: _showBatchDeleteDialog,
                  tooltip: 'Delete',
                ),
              ]
            : [
                IconButton(
                  icon: Icon(Icons.search),
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
          ? Center(child: CircularProgressIndicator())
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
                    child: Icon(Icons.create_new_folder),
                    mini: true,
                    backgroundColor: Colors.orange,
                  ),
                SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'scan',
                  onPressed: () => Navigator.pop(context),
                  child: Icon(Icons.add),
                  backgroundColor: Colors.blue,
                ),
              ],
            ),
    );
  }

  Widget _buildBody() {
    if (_selectedFolder == null && _folders.isEmpty && _documents.isEmpty) {
      return Center(
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
        padding: EdgeInsets.all(8),
        children: [
          if (_selectedFolder == null && _folders.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Folders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
            ..._folders.map((folder) => _buildFolderCard(folder)),
            if (_documents.isNotEmpty) ...[
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Recent Documents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ],
          ..._documents.map((doc) => _buildDocumentCard(doc)),
        ],
      ),
    );
  }

  Widget _buildFolderCard(String folderName) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Icon(Icons.folder, color: Colors.orange, size: 40),
        title: Text(
          folderName,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Rename'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'rename') {
              _showRenameFolderDialog(folderName);
            } else if (value == 'delete') {
              _deleteFolder(folderName);
            }
          },
        ),
        onTap: () {
          setState(() => _selectedFolder = folderName);
          _loadDocuments();
        },
      ),
    );
  }

  Widget _buildDocumentCard(Document doc) {
    final isSelected = _selectedDocuments.contains(doc.path);
    
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isSelected ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleDocumentSelection(doc.path),
              )
            : Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
        title: Text(
          doc.name.replaceAll('.pdf', ''),
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${_formatDate(doc.date)} • ${_formatSize(doc.size)}',
          style: TextStyle(fontSize: 12),
        ),
        trailing: _isSelectionMode
            ? null
            : PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'open',
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new, size: 20),
                        SizedBox(width: 8),
                        Text('Open'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, size: 20),
                        SizedBox(width: 8),
                        Text('Share'),
                      ],
                    ),
                  ),
                  if (_selectedFolder == null)
                    PopupMenuItem(
                      value: 'move',
                      child: Row(
                        children: [
                          Icon(Icons.drive_file_move, size: 20),
                          SizedBox(width: 8),
                          Text('Move to Folder'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  switch (value) {
                    case 'open':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfPreviewScreen(pdfPath: doc.path),
                        ),
                      );
                      break;
                    case 'share':
                      await Share.shareXFiles([XFile(doc.path)]);
                      break;
                    case 'move':
                      _showMoveToFolderDialog(doc);
                      break;
                    case 'delete':
                      _deleteDocument(doc);
                      break;
                  }
                },
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
            setState(() {
              _isSelectionMode = true;
              _selectedDocuments.add(doc.path);
            });
          }
        },
      ),
    );
  }

  void _showBatchMoveDialog() {
    if (_folders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No folders available. Create a folder first.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move ${_selectedDocuments.length} document(s)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _folders.map((folder) {
            return ListTile(
              leading: Icon(Icons.folder),
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
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _batchMoveToFolder(String folderName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      int moved = 0;

      for (String docPath in _selectedDocuments) {
        final doc = _documents.firstWhere((d) => d.path == docPath);
        final newPath = '${directory.path}/documents/$folderName/${doc.name}';
        await File(doc.path).rename(newPath);
        moved++;
      }

      setState(() {
        _selectedDocuments.clear();
        _isSelectionMode = false;
      });
      
      await _loadDocuments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Moved $moved document(s) to "$folderName"')),
      );
    } catch (e) {
      debugPrint('Batch move error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving documents')),
      );
    }
  }

  void _showBatchDeleteDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Documents'),
        content: Text('Delete ${_selectedDocuments.length} document(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _batchDelete();
    }
  }

  Future<void> _batchDelete() async {
    try {
      int deleted = 0;

      for (String docPath in _selectedDocuments) {
        await File(docPath).delete();
        deleted++;
      }

      setState(() {
        _selectedDocuments.clear();
        _isSelectionMode = false;
      });
      
      await _loadDocuments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $deleted document(s)')),
      );
    } catch (e) {
      debugPrint('Batch delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting documents')),
      );
    }
  }

  void _showCreateFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Folder'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Folder Name',
            hintText: 'e.g., Receipts, Work, Personal',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final folderName = controller.text.trim();
              if (folderName.isNotEmpty) {
                await _createFolder(folderName);
                Navigator.pop(context);
              }
            },
            child: Text('Create'),
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
          SnackBar(content: Text('Folder already exists')),
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
        SnackBar(content: Text('Error creating folder')),
      );
    }
  }

  void _showRenameFolderDialog(String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename Folder'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: 'New Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldName) {
                await _renameFolder(oldName, newName);
                Navigator.pop(context);
              }
            },
            child: Text('Rename'),
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
        SnackBar(content: Text('Error renaming folder')),
      );
    }
  }

  Future<void> _deleteFolder(String folderName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Folder'),
        content: Text('Delete "$folderName" and all its contents?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
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
          SnackBar(content: Text('Folder deleted')),
        );
      } catch (e) {
        debugPrint('Delete folder error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting folder')),
        );
      }
    }
  }

  void _showMoveToFolderDialog(Document doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move to Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _folders.map((folder) {
            return ListTile(
              leading: Icon(Icons.folder),
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
            child: Text('Cancel'),
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
        SnackBar(content: Text('Error moving document')),
      );
    }
  }

  Future<void> _deleteDocument(Document doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Document'),
        content: Text('Delete "${doc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await File(doc.path).delete();
        await _loadDocuments();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document deleted')),
        );
      } catch (e) {
        debugPrint('Delete document error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting document')),
        );
      }
    }
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
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
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
          leading: Icon(Icons.picture_as_pdf, color: Colors.red),
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