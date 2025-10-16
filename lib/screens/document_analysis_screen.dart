import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ocr_service.dart';
import '../ai_service.dart';
import '../subscription_manager.dart';

class DocumentAnalysisScreen extends StatefulWidget {
  final String imagePath;
  final String documentName;

  const DocumentAnalysisScreen({
    Key? key,
    required this.imagePath,
    required this.documentName,
  }) : super(key: key);

  @override
  State<DocumentAnalysisScreen> createState() => _DocumentAnalysisScreenState();
}

class _DocumentAnalysisScreenState extends State<DocumentAnalysisScreen> {
  final OCRService _ocrService = OCRService();
  final AIService _aiService = AIService();
  final SubscriptionManager _subscriptionManager = SubscriptionManager();

  OCRResult? _ocrResult;
  AIAnalysisResult? _aiResult;
  bool _isProcessing = true;
  String? _error;
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();
    _processDocument();
  }

  Future<void> _processDocument() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // Step 1: OCR (available to all users)
      _ocrResult = await _ocrService.extractText(widget.imagePath);

      if (_ocrResult == null) {
        setState(() {
          _error = 'Could not extract text from document';
          _isProcessing = false;
        });
        return;
      }

      // Step 2: AI Analysis (Premium only)
      if (_subscriptionManager.isPremium && _ocrResult!.text.isNotEmpty) {
        _aiResult = await _aiService.analyzeDocument(_ocrResult!.text);
        
        // Save analysis for future reference
        if (_aiResult != null) {
          await _aiService.saveAnalysis(
            widget.documentName,
            _aiResult!,
          );
        }
      }

      setState(() {
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error processing document: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Analysis'),
        actions: [
          if (_ocrResult != null)
            IconButton(
              icon: Icon(Icons.save),
              tooltip: 'Save Text',
              onPressed: _saveText,
            ),
          if (_ocrResult != null)
            IconButton(
              icon: Icon(Icons.share),
              tooltip: 'Share Text',
              onPressed: _shareText,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing document...'),
            SizedBox(height: 8),
            Text(
              'Extracting text with OCR',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _processDocument,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_ocrResult == null) {
      return Center(
        child: Text('No text found in document'),
      );
    }

    return Column(
      children: [
        // Premium banner for trial users
        if (_subscriptionManager.isInTrial)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            color: Colors.green.shade50,
            child: Row(
              children: [
                Icon(Icons.celebration, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '🎉 Trial Active: ${_subscriptionManager.getTrialTimeRemaining()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Tab bar
        Container(
          color: Colors.grey[200],
          child: Row(
            children: [
              Expanded(
                child: _buildTab(
                  index: 0,
                  icon: Icons.text_fields,
                  label: 'Text',
                ),
              ),
              Expanded(
                child: _buildTab(
                  index: 1,
                  icon: Icons.auto_awesome,
                  label: 'AI Analysis',
                  isPremium: true,
                ),
              ),
              Expanded(
                child: _buildTab(
                  index: 2,
                  icon: Icons.info_outline,
                  label: 'Details',
                ),
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildTab({
    required int index,
    required IconData icon,
    required String label,
    bool isPremium = false,
  }) {
    final isSelected = _currentTab == index;
    
    return InkWell(
      onTap: () {
        if (isPremium && !_subscriptionManager.isPremium) {
          SubscriptionManager.showSubscriptionDialog(context);
          return;
        }
        setState(() => _currentTab = index);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.blue : Colors.grey[600],
                  size: 20,
                ),
                if (isPremium && !_subscriptionManager.isPremium) ...[
                  SizedBox(width: 4),
                  Icon(Icons.lock, size: 14, color: Colors.amber),
                ],
              ],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildTextTab();
      case 1:
        return _buildAITab();
      case 2:
        return _buildDetailsTab();
      default:
        return Container();
    }
  }

  Widget _buildTextTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                avatar: Icon(Icons.language, size: 16),
                label: Text(_ocrResult!.language),
                backgroundColor: Colors.blue.shade50,
              ),
              SizedBox(width: 8),
              Chip(
                avatar: Icon(Icons.check_circle, size: 16),
                label: Text('${(_ocrResult!.confidence * 100).toStringAsFixed(0)}%'),
                backgroundColor: Colors.green.shade50,
              ),
            ],
          ),
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(_ocrResult!.text),
                  icon: Icon(Icons.copy, size: 18),
                  label: Text('Copy All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saveText,
                  icon: Icon(Icons.save, size: 18),
                  label: Text('Save TXT'),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: SelectableText(
              _ocrResult!.text,
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
          ),
          SizedBox(height: 16),
          
          Text(
            '${_ocrResult!.text.split('\n').length} lines • ${_ocrResult!.text.split(' ').length} words',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildAITab() {
    if (!_subscriptionManager.isPremium) {
      return _buildPremiumUpsell();
    }

    if (_aiResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing document with AI...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _aiResult!.category.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _aiResult!.category.color, width: 2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_aiResult!.category.icon, 
                     color: _aiResult!.category.color,
                     size: 24),
                SizedBox(width: 12),
                Text(
                  _aiResult!.category.name,
                  style: TextStyle(
                    color: _aiResult!.category.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          
          // Summary
          _buildSection(
            'Summary',
            Icons.auto_awesome,
            _aiResult!.summary,
          ),
          
          // Key Information
          if (_aiResult!.keyInfo.isNotEmpty) ...[
            SizedBox(height: 24),
            _buildKeyInfoSection(),
          ],
          
          // Tags
          if (_aiResult!.tags.isNotEmpty) ...[
            SizedBox(height: 24),
            Text(
              'Tags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _aiResult!.tags.map((tag) => Chip(
                label: Text(tag),
                backgroundColor: Colors.blue.shade50,
                avatar: Icon(Icons.tag, size: 16),
              )).toList(),
            ),
          ],
          
          SizedBox(height: 24),
          
          // Confidence indicator
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'AI Confidence: ${(_aiResult!.confidence * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            content,
            style: TextStyle(fontSize: 15, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildKeyInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: _aiResult!.keyInfo.entries.map((entry) => Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      '${entry.key}:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    final structuredData = _ocrService.extractStructuredData(_ocrResult!.text);
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            'Document Info',
            Icons.info_outline,
            [
              'Name: ${widget.documentName}',
              'Language: ${_ocrResult!.language}',
              'Words: ${_ocrResult!.text.split(' ').length}',
              'Lines: ${_ocrResult!.text.split('\n').length}',
              'Characters: ${_ocrResult!.text.length}',
            ],
          ),
          
          if (structuredData['emails']!.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildDetailCard(
              'Email Addresses',
              Icons.email,
              structuredData['emails']!,
            ),
          ],
          
          if (structuredData['phones']!.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildDetailCard(
              'Phone Numbers',
              Icons.phone,
              structuredData['phones']!,
            ),
          ],
          
          if (structuredData['amounts']!.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildDetailCard(
              'Amounts',
              Icons.attach_money,
              structuredData['amounts']!,
            ),
          ],
          
          if (structuredData['dates']!.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildDetailCard(
              'Dates',
              Icons.calendar_today,
              structuredData['dates']!,
            ),
          ],
          
          if (structuredData['urls']!.isNotEmpty) ...[
            SizedBox(height: 16),
            _buildDetailCard(
              'URLs',
              Icons.link,
              structuredData['urls']!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard(String title, IconData icon, List<String> items) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('• $item'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumUpsell() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 80,
              color: Colors.amber,
            ),
            SizedBox(height: 24),
            Text(
              'AI-Powered Analysis',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Upgrade to Premium to unlock:\n\n'
              '• Smart document categorization\n'
              '• AI-generated summaries\n'
              '• Automatic key info extraction\n'
              '• Intelligent tagging\n'
              '• Advanced search',
              style: TextStyle(fontSize: 16, height: 1.8),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => SubscriptionManager.showSubscriptionDialog(context),
              icon: Icon(Icons.workspace_premium),
              label: Text('Start 7-Day Free Trial'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Text copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveText() async {
    final saved = await _ocrService.saveTextToFile(
      _ocrResult!.text,
      widget.documentName,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saved ? '✓ Text saved as TXT file' : '✗ Failed to save'),
          backgroundColor: saved ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _shareText() {
    // TODO: Implement share functionality
    // This would use the share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share feature coming soon!')),
    );
  }
}