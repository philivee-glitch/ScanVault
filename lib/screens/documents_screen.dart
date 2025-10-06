import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'pdf_preview_screen.dart';
import '../ad_helper.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<String> folders = ['All Documents'];
  String selectedFolder = 'All Documents';
  List<FileSystemEntity> documents = [];
  List<FileSystemEntity> filteredDocuments = [];
  bool isLoading = true;
  bool isSearching = false;
  bool isSelectionMode = false;
  Set<String> selectedDocuments = {};
  TextEditingController searchController = TextEditingController();
  
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadFolders();
    _loadDocuments();
    searchController.addListener(_filterDocuments);
    _loadBannerAd();
    AdHelper.loadInterstitialAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdHelper.loadBannerAd();
    setState(() {
      _isBannerAdLoaded = true;
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _filterDocuments() {
    final query = searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        filteredDocuments = documents;
      });
    } else {
      setState(() {
        filteredDocuments = documents.where((doc) {
          final fileName = doc.path.split('/').last.toLowerCase();
          return fileName.contains(query);
        }).toList();
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        selectedDocuments.clear();
      }
    });
  }

  void _toggleDocumentSelection(String path) {
    setState(() {
      if (selectedDocuments.contains(path)) {
        selectedDocuments.remove(path);
      } else {
        selectedDocuments.add(path);
      }
    });
  }

  void _selectAll() {
    setState(() {
      selectedDocuments = filteredDocuments.map((doc) => doc.path).toSet();
    });
  }

  Future<void> _batchDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Documents'),
        content: Text('Are you sure you want to delete ${selectedDocuments.length} document(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final path in selectedDocuments) {
        await File(path).delete();
      }
      
      setState(() {
        isSelectionMode = false;
        selectedDocuments.clear();
      });
      
      _loadDocuments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents deleted'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _batchMove() async {
    final targetFolder = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: folders
              .where((f) => f != 'All Documents')
              .map((folder) => ListTile(
                    title: Text(folder),
                    leading: const Icon(Icons.folder),
                    onTap: () => Navigator.pop(context, folder),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (targetFolder != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        
        for (final path in selectedDocuments) {
          final fileName = path.split('/').last;
          final newPath = '${appDir.path}/documents/$targetFolder/$fileName';
          await File(path).copy(newPath);
          await File(path).delete();
        }
        
        setState(() {
          isSelectionMode = false;
          selectedDocuments.clear();
        });
        
        _loadDocuments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Documents moved to $targetFolder'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadFolders() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/documents');
      
      if (await docsDir.exists()) {
        final entities = docsDir.listSync();
        final folderNames = entities
            .whereType<Directory>()
            .map((d) => d.path.split('/').last)
            .toList();
        
        setState(() {
          folders = ['All Documents', ...folderNames];
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  Future<void> _loadDocuments() async {
    setState(() {
      isLoading = true;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${appDir.path}/documents');
      
      if (await docsDir.exists()) {
        List<FileSystemEntity> allFiles = [];
        
        if (selectedFolder == 'All Documents') {
          allFiles = await _getAllPdfs(docsDir);
        } else {
          final folderDir = Directory('${docsDir.path}/$selectedFolder');
          if (await folderDir.exists()) {
            allFiles = folderDir
                .listSync()
                .where((f) => f.path.endsWith('.pdf'))
                .toList();
          }
        }
        
        allFiles.sort((a, b) => 
          b.statSync().modified.compareTo(a.statSync().modified)
        );
        
        setState(() {
          documents = allFiles;
          filteredDocuments = allFiles;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<FileSystemEntity>> _getAllPdfs(Directory dir) async {
    List<FileSystemEntity> pdfs = [];
    
    await for (var entity in dir.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.pdf')) {
        pdfs.add(entity);
      }
    }
    
    return pdfs;
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();
    
    final folderName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Folder name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (folderName != null && folderName.isNotEmpty) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final folderDir = Directory('${appDir.path}/documents/$folderName');
        await folderDir.create(recursive: true);
        
        await _loadFolders();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Folder "$folderName" created'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _previewDocument(FileSystemEntity doc) async {
    final fileName = doc.path.split('/').last.replaceAll('.pdf', '');
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfPreviewScreen(
          pdfPath: doc.path,
          documentName: fileName,
        ),
      ),
    );
  }

  Future<void> _shareDocument(FileSystemEntity doc) async {
    try {
      final result = await Share.shareXFiles(
        [XFile(doc.path)],
        text: 'Sharing document: ',
      );
      
      if (result.status == ShareResultStatus.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document shared successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _renameDocument(FileSystemEntity doc) async {
    final currentName = doc.path.split('/').last.replaceAll('.pdf', '');
    final controller = TextEditingController(text: currentName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Document name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      try {
        final directory = doc.parent.path;
        final newPath = '$directory/$newName.pdf';
        
        await (doc as File).rename(newPath);
        _loadDocuments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Renamed to "$newName"'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _moveToFolder(FileSystemEntity doc) async {
    final fileName = doc.path.split('/').last;
    
    final targetFolder = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: folders
              .where((f) => f != 'All Documents')
              .map((folder) => ListTile(
                    title: Text(folder),
                    leading: const Icon(Icons.folder),
                    onTap: () => Navigator.pop(context, folder),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (targetFolder != null) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final newPath = '${appDir.path}/documents/$targetFolder/$fileName';
        await (doc as File).copy(newPath);
        await doc.delete();
        
        _loadDocuments();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Moved to $targetFolder'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _openDocument(String path) async {
    await OpenFile.open(path);
  }

  Future<void> _deleteDocument(FileSystemEntity doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await doc.delete();
      _loadDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search documents...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
              )
            : isSelectionMode
                ? Text('${selectedDocuments.length} selected')
                : const Text('My Documents'),
        backgroundColor: Colors.blue,
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: 'Select all',
            ),
            IconButton(
              icon: const Icon(Icons.drive_file_move),
              onPressed: selectedDocuments.isEmpty ? null : _batchMove,
              tooltip: 'Move',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: selectedDocuments.isEmpty ? null : _batchDelete,
              tooltip: 'Delete',
            ),
          ] else ...[
            IconButton(
              icon: Icon(isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  isSearching = !isSearching;
                  if (!isSearching) {
                    searchController.clear();
                  }
                });
              },
            ),
            if (!isSearching)
              IconButton(
                icon: const Icon(Icons.checklist),
                onPressed: _toggleSelectionMode,
                tooltip: 'Select',
              ),
            if (!isSearching)
              IconButton(
                icon: const Icon(Icons.create_new_folder),
                onPressed: _createFolder,
                tooltip: 'New Folder',
              ),
            if (!isSearching)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _loadFolders();
                  _loadDocuments();
                },
              ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (!isSearching && !isSelectionMode)
            Container(
              height: 60,
              color: Colors.grey[200],
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: folders.length,
                itemBuilder: (context, index) {
                  final folder = folders[index];
                  final isSelected = folder == selectedFolder;
                  
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ChoiceChip(
                      label: Text(folder),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedFolder = folder;
                        });
                        _loadDocuments();
                      },
                      avatar: folder != 'All Documents' 
                          ? const Icon(Icons.folder, size: 18)
                          : null,
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDocuments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              searchController.text.isNotEmpty 
                                  ? 'No documents found'
                                  : 'No documents yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchController.text.isNotEmpty
                                  ? 'Try a different search term'
                                  : 'Tap "Start Scanning" to create your first document',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredDocuments.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocuments[index];
                          final fileName = doc.path.split('/').last.replaceAll('.pdf', '');
                          final stat = doc.statSync();
                          final date = stat.modified;
                          final isSelected = selectedDocuments.contains(doc.path);
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            color: isSelected ? Colors.blue[50] : null,
                            child: ListTile(
                              leading: isSelectionMode
                                  ? Checkbox(
                                      value: isSelected,
                                      onChanged: (val) => _toggleDocumentSelection(doc.path),
                                    )
                                  : const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                              title: Text(
                                fileName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${(stat.size / 1024).toStringAsFixed(1)} KB • ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                              ),
                              trailing: isSelectionMode
                                  ? null
                                  : PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'preview',
                                          child: Row(
                                            children: [
                                              Icon(Icons.visibility, color: Colors.purple),
                                              SizedBox(width: 8),
                                              Text('Preview'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'share',
                                          child: Row(
                                            children: [
                                              Icon(Icons.share, color: Colors.blue),
                                              SizedBox(width: 8),
                                              Text('Share'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'rename',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit),
                                              SizedBox(width: 8),
                                              Text('Rename'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'move',
                                          child: Row(
                                            children: [
                                              Icon(Icons.drive_file_move),
                                              SizedBox(width: 8),
                                              Text('Move to folder'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'preview') {
                                          _previewDocument(doc);
                                        } else if (value == 'share') {
                                          _shareDocument(doc);
                                        } else if (value == 'rename') {
                                          _renameDocument(doc);
                                        } else if (value == 'delete') {
                                          _deleteDocument(doc);
                                        } else if (value == 'move') {
                                          _moveToFolder(doc);
                                        }
                                      },
                                    ),
                              onTap: isSelectionMode
                                  ? () => _toggleDocumentSelection(doc.path)
                                  : () => _previewDocument(doc),
                            ),
                          );
                        },
                      ),
          ),
          if (_isBannerAdLoaded && _bannerAd != null)
            Container(
              height: 50,
              alignment: Alignment.center,
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }
}
