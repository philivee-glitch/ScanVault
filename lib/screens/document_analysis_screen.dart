import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../subscription_manager.dart';
import '../ocr_service.dart';
import '../ai_service.dart';

class DocumentAnalysisScreen extends StatefulWidget {
  final String imagePath;
  final String documentName;

  const DocumentAnalysisScreen({
    super.key,
    required this.imagePath,
    required this.documentName,
  });

  @override
  State<DocumentAnalysisScreen> createState() => _DocumentAnalysisScreenState();
}

class _DocumentAnalysisScreenState extends State<DocumentAnalysisScreen> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final OCRService _ocrService = OCRService();
  final AIService _aiService = AIService();
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _extractedText = '';
  String _summary = '';
  bool _isLoadingOCR = true;
  bool _isLoadingSummary = true;
  bool _isAskingQuestion = false;
  
  final List<ChatMessage> _chatHistory = [];

  @override
  void initState() {
    super.initState();
    _performOCR();
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _performOCR() async {
    // Check if user has premium for OCR
    if (!_subscriptionManager.canUseOCR()) {
      setState(() {
        _extractedText = 'OCR Text Recognition is a premium feature. Upgrade to Premium to extract text from your documents.';
        _isLoadingOCR = false;
        _summary = 'Upgrade to Premium to use AI Analysis.';
        _isLoadingSummary = false;
      });
      return;
    }
    try {
      final result = await _ocrService.extractText(widget.imagePath);
      final text = result?.text ?? '';
      setState(() {
        _extractedText = text;
        _isLoadingOCR = false;
      });
      
      if (text.isNotEmpty) {
        _generateSummary();
      } else {
        setState(() {
          _summary = 'No text could be extracted from this document.';
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      setState(() {
        _extractedText = 'Error extracting text: $e';
        _isLoadingOCR = false;
        _summary = 'Could not analyze document due to OCR error.';
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _generateSummary() async {
    try {
      final summary = await _aiService.summarizeDocument(_extractedText);
      setState(() {
        _summary = summary;
        _isLoadingSummary = false;
      });
    } catch (e) {
      setState(() {
        _summary = 'Error generating summary. Please check your internet connection.';
        _isLoadingSummary = false;
      });
    }
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isAskingQuestion) return;

    // Add user question to chat
    setState(() {
      _chatHistory.add(ChatMessage(
        text: question,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isAskingQuestion = true;
    });

    _questionController.clear();

    FocusScope.of(context).unfocus();
    
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final answer = await _aiService.answerQuestion(_extractedText, question);
      
      setState(() {
        _chatHistory.add(ChatMessage(
          text: answer,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isAskingQuestion = false;
      });

      // Scroll to bottom again
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _chatHistory.add(ChatMessage(
          text: 'Sorry, I couldn\'t answer that question. Please try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isAskingQuestion = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Document Analysis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _extractedText.isEmpty ? null : () {
              Clipboard.setData(ClipboardData(text: _extractedText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Text copied to clipboard')),
              );
            },
            tooltip: 'Copy All Text',
          ),
        ],
      ),
      body: Column(
        children: [
          // Document preview
          Container(
            height: 200,
            color: Colors.grey[200],
            child: Center(
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Colors.blue,
                    tabs: [
                      Tab(text: 'Summary'),
                      Tab(text: 'Ask AI'),
                      Tab(text: 'Full Text'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildSummaryTab(),
                        _buildAskAITab(),
                        _buildFullTextTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.purple),
              SizedBox(width: 8),
              Text(
                'AI-Generated Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingSummary)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing document with AI...'),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Text(
                _summary.isEmpty ? 'No summary available.' : _summary,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.description, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                'Document Info',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoCard('Document Name', widget.documentName),
          _buildInfoCard('Word Count', _extractedText.split(' ').where((w) => w.isNotEmpty).length.toString()),
          _buildInfoCard('Character Count', _extractedText.length.toString()),
        ],
      ),
    );
  }

  Widget _buildAskAITab() {
    return Column(
      children: [
        // Chat history
        Expanded(
          child: _chatHistory.isEmpty
              ? Center(
                  child: Text(
                    'Ask a question below',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16,
                  ),
                  itemCount: _chatHistory.length + (_isAskingQuestion ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _chatHistory.length && _isAskingQuestion) {
                      return _buildTypingIndicator();
                    }
                    return _buildChatBubble(_chatHistory[index]);
                  },
                ),
        ),
        
        // Question input with proper padding for navigation bar
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _questionController,
                      decoration: InputDecoration(
                        hintText: 'Ask a question...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _askQuestion(),
                      enabled: !_isAskingQuestion && _extractedText.isNotEmpty,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _isAskingQuestion || _extractedText.isEmpty ? null : _askQuestion,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('AI is thinking...'),
          ],
      ),
        ),
    );
  }

  Widget _buildFullTextTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Extracted Text',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: _extractedText.isEmpty ? null : () {
                  Clipboard.setData(ClipboardData(text: _extractedText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Text copied to clipboard')),
                  );
                },
                tooltip: 'Copy Text',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingOCR)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Extracting text from document...'),
                ],
              ),
            )
          else
            SelectableText(
              _extractedText.isEmpty ? 'No text extracted from document.' : _extractedText,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.blue.shade900),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}




