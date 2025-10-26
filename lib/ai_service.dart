import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DocumentCategory {
  final String name;
  final IconData icon;
  final Color color;

  DocumentCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class AIAnalysisResult {
  final String summary;
  final DocumentCategory category;
  final Map<String, String> keyInfo;
  final List<String> tags;
  final double confidence;

  AIAnalysisResult({
    required this.summary,
    required this.category,
    required this.keyInfo,
    required this.tags,
    required this.confidence,
  });
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  // TODO: Replace with your Anthropic API key
  // Get your key at: https://console.anthropic.com/
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY_HERE';
  static const String _apiUrl = 'https://api.anthropic.com/v1/messages';

  // Document categories
  static final Map<String, DocumentCategory> categories = {
    'invoice': DocumentCategory(
      name: 'Invoice',
      icon: Icons.receipt_long,
      color: Colors.orange,
    ),
    'receipt': DocumentCategory(
      name: 'Receipt',
      icon: Icons.receipt,
      color: Colors.green,
    ),
    'contract': DocumentCategory(
      name: 'Contract',
      icon: Icons.description,
      color: Colors.blue,
    ),
    'letter': DocumentCategory(
      name: 'Letter',
      icon: Icons.mail,
      color: Colors.purple,
    ),
    'id_document': DocumentCategory(
      name: 'ID Document',
      icon: Icons.badge,
      color: Colors.red,
    ),
    'form': DocumentCategory(
      name: 'Form',
      icon: Icons.assignment,
      color: Colors.teal,
    ),
    'report': DocumentCategory(
      name: 'Report',
      icon: Icons.analytics,
      color: Colors.indigo,
    ),
    'other': DocumentCategory(
      name: 'Other',
      icon: Icons.insert_drive_file,
      color: Colors.grey,
    ),
  };

  Future<AIAnalysisResult?> analyzeDocument(String text) async {
    if (_apiKey == 'YOUR_ANTHROPIC_API_KEY_HERE') {
      // Fallback to local analysis if no API key
      return _localAnalysis(text);
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content': _buildAnalysisPrompt(text),
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['content'][0]['text'];
        
        return _parseAIResponse(content);
      } else {
        debugPrint('AI API Error: ${response.statusCode} - ${response.body}');
        return _localAnalysis(text);
      }
    } catch (e) {
      debugPrint('AI Analysis Error: $e');
      return _localAnalysis(text);
    }
  }

  String _buildAnalysisPrompt(String text) {
    return '''Analyze this document and provide:
1. A concise summary (2-3 sentences max)
2. Document category: invoice, receipt, contract, letter, id_document, form, report, or other
3. Key information extracted (dates, amounts, names, etc.)
4. Relevant tags (3-5 keywords)

Document text:
"""
$text
"""

Respond in this JSON format:
{
  "summary": "Brief summary here",
  "category": "category_name",
  "key_info": {
    "date": "if found",
    "amount": "if found",
    "company": "if found",
    "reference": "if found"
  },
  "tags": ["tag1", "tag2", "tag3"],
  "confidence": 0.95
}''';
  }

  AIAnalysisResult _parseAIResponse(String response) {
    try {
      // Extract JSON from response
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0)!;
        final data = jsonDecode(jsonStr);
        
        final categoryName = data['category'] as String;
        final category = categories[categoryName] ?? categories['other']!;
        
        return AIAnalysisResult(
          summary: data['summary'] as String,
          category: category,
          keyInfo: Map<String, String>.from(data['key_info'] ?? {}),
          tags: List<String>.from(data['tags'] ?? []),
          confidence: (data['confidence'] as num).toDouble(),
        );
      }
    } catch (e) {
      debugPrint('Error parsing AI response: $e');
    }
    
    // Fallback
    return _localAnalysis(response);
  }

  AIAnalysisResult _localAnalysis(String text) {
    // Simple local analysis without AI
    final lowercaseText = text.toLowerCase();
    
    // Detect category
    DocumentCategory category = categories['other']!;
    
    if (lowercaseText.contains('invoice') || 
        lowercaseText.contains('bill') ||
        lowercaseText.contains('due date')) {
      category = categories['invoice']!;
    } else if (lowercaseText.contains('receipt') || 
               lowercaseText.contains('transaction')) {
      category = categories['receipt']!;
    } else if (lowercaseText.contains('contract') || 
               lowercaseText.contains('agreement')) {
      category = categories['contract']!;
    } else if (lowercaseText.contains('dear') || 
               lowercaseText.contains('sincerely')) {
      category = categories['letter']!;
    } else if (lowercaseText.contains('passport') || 
               lowercaseText.contains('license') ||
               lowercaseText.contains('id card')) {
      category = categories['id_document']!;
    } else if (lowercaseText.contains('report') || 
               lowercaseText.contains('analysis')) {
      category = categories['report']!;
    }

    // Generate simple summary
    final words = text.split(' ');
    final summary = words.length > 20
        ? '${words.take(20).join(' ')}...'
        : text;

    // Extract basic info
    final keyInfo = <String, String>{};
    
    // Try to find dates
    final datePattern = RegExp(r'\b\d{1,2}[/-]\d{1,2}[/-]\d{2,4}\b');
    final dateMatch = datePattern.firstMatch(text);
    if (dateMatch != null) {
      keyInfo['date'] = dateMatch.group(0)!;
    }

    // Try to find amounts
    final amountPattern = RegExp(r'[\$â‚¬Â£]\s?\d+(?:,\d{3})*(?:\.\d{2})?');
    final amountMatch = amountPattern.firstMatch(text);
    if (amountMatch != null) {
      keyInfo['amount'] = amountMatch.group(0)!;
    }

    return AIAnalysisResult(
      summary: summary,
      category: category,
      keyInfo: keyInfo,
      tags: [category.name.toLowerCase()],
      confidence: 0.70,
    );
  }

  Future<String?> generateSummary(String text, {int maxLength = 200}) async {
    if (text.length <= maxLength) return text;

    if (_apiKey == 'YOUR_ANTHROPIC_API_KEY_HERE') {
      // Simple local truncation
      return '${text.substring(0, maxLength)}...';
    }

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-5-sonnet-20241022',
          'max_tokens': 200,
          'messages': [
            {
              'role': 'user',
              'content': 'Summarize this document in 2-3 concise sentences:\n\n$text',
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'];
      }
    } catch (e) {
      debugPrint('Summary generation error: $e');
    }

    return '${text.substring(0, maxLength)}...';
  }

  Future<String> summarizeDocument(String text) async {
    if (text.isEmpty) {
      return 'No text available to summarize.';
    }

    // Use existing analyzeDocument method for detailed summary
    try {
      final result = await analyzeDocument(text);
      if (result != null) {
        final buffer = StringBuffer();
        buffer.writeln('${result.category.name}, Other\n');
        buffer.writeln(result.summary);
        
        if (result.keyInfo.isNotEmpty) {
          buffer.writeln('\nKey Details:');
          result.keyInfo.forEach((key, value) {
            buffer.writeln('${key.toUpperCase()}: $value');
          });
        }
        
        if (result.tags.isNotEmpty) {
          buffer.writeln('\nTags: ${result.tags.join(', ')}');
        }
        
        buffer.writeln('\nConfidence: ${(result.confidence * 100).toStringAsFixed(0)}%');
        
        return buffer.toString();
      }
    } catch (e) {
      debugPrint('Summarize error: $e');
    }

    // Fallback to basic summary
    final sentences = text.split(RegExp(r'[.!?]+'));
    final goodSentences = sentences.map((s) => s.trim()).where((s) => s.length > 10).take(5);
    
    if (goodSentences.isEmpty) {
      return 'Document text is too short to summarize effectively.';
    }
    
    return '${goodSentences.join('. ')}.';
  }

  Future<String> answerQuestion(String documentText, String question) async {
    if (documentText.isEmpty) {
      return 'No document text available to answer questions.';
    }

    try {
      final lowerQuestion = question.toLowerCase();
      
      // Handle common question patterns
      if (lowerQuestion.contains('what') && (lowerQuestion.contains('about') || lowerQuestion.contains('document'))) {
        final result = await analyzeDocument(documentText);
        if (result != null) {
          return 'This is a ${result.category.name}. ${result.summary}';
        }
        
        // Fallback
        final sentences = documentText.split(RegExp(r'[.!?]+'));
        final firstSentences = sentences.take(2).map((s) => s.trim()).where((s) => s.isNotEmpty).join('. ');
        return 'Based on the document: $firstSentences.';
      }
      
      if (lowerQuestion.contains('summarize') || lowerQuestion.contains('summary')) {
        return await summarizeDocument(documentText);
      }
      
      if (lowerQuestion.contains('date')) {
        final datePattern = RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}');
        final dates = datePattern.allMatches(documentText).map((m) => m.group(0)).toSet();
        if (dates.isNotEmpty) {
          return 'Dates mentioned: ${dates.join(', ')}';
        }
        return 'No dates found in this document.';
      }
      
      if (lowerQuestion.contains('amount') || lowerQuestion.contains('price') || lowerQuestion.contains('cost')) {
        final amountPattern = RegExp(r'[\$â‚¬Â£]\s?\d+(?:,\d{3})*(?:\.\d{2})?');
        final amounts = amountPattern.allMatches(documentText).map((m) => m.group(0)).toSet();
        if (amounts.isNotEmpty) {
          return 'Amounts mentioned: ${amounts.join(', ')}';
        }
        return 'No monetary amounts found in this document.';
      }
      
      // Keyword search in document
      final keywords = question.split(' ').where((w) => w.length > 3 && !['what', 'when', 'where', 'which', 'this', 'that', 'does'].contains(w.toLowerCase())).toList();
      
      if (keywords.isNotEmpty) {
        final sentences = documentText.split(RegExp(r'[.!?]+'));
        final relevantSentences = <String>[];
        
        for (final sentence in sentences) {
          final lowerSentence = sentence.toLowerCase();
          for (final keyword in keywords) {
            if (lowerSentence.contains(keyword.toLowerCase()) && sentence.trim().length > 20) {
              relevantSentences.add(sentence.trim());
              break;
            }
          }
          if (relevantSentences.length >= 2) break;
        }
        
        if (relevantSentences.isNotEmpty) {
          return 'Based on the document:\n\n${relevantSentences.join('.\n\n')}.';
        }
      }
      
      return 'I couldn\'t find specific information about that. Try asking:\n\n• "What is this document about?"\n• "Summarize this document"\n• "What dates are mentioned?"\n• "What amounts are in this document?"';
    } catch (e) {
      debugPrint('Answer question error: $e');
      return 'Error processing your question. Please try rephrasing it.';
    }
  }

  Future<List<String>> smartSearch(String query, List<String> documents) async {
    // Simple keyword matching for now
    // In production, this would use AI-powered semantic search
    
    final queryWords = query.toLowerCase().split(' ');
    final matches = <String>[];

    for (var doc in documents) {
      final docLower = doc.toLowerCase();
      int matchCount = 0;
      
      for (var word in queryWords) {
        if (docLower.contains(word)) {
          matchCount++;
        }
      }
      
      if (matchCount > 0) {
        matches.add(doc);
      }
    }

    return matches;
  }

  // Save analysis results
  Future<void> saveAnalysis(String documentId, AIAnalysisResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'analysis_$documentId';
    
    final data = jsonEncode({
      'summary': result.summary,
      'category': result.category.name,
      'key_info': result.keyInfo,
      'tags': result.tags,
      'confidence': result.confidence,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    await prefs.setString(key, data);
  }

  // Load saved analysis
  Future<AIAnalysisResult?> loadAnalysis(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'analysis_$documentId';
    final data = prefs.getString(key);
    
    if (data == null) return null;
    
    try {
      final json = jsonDecode(data);
      final categoryName = json['category'] as String;
      final category = categories.values.firstWhere(
        (cat) => cat.name == categoryName,
        orElse: () => categories['other']!,
      );
      
      return AIAnalysisResult(
        summary: json['summary'],
        category: category,
        keyInfo: Map<String, String>.from(json['key_info']),
        tags: List<String>.from(json['tags']),
        confidence: json['confidence'],
      );
    } catch (e) {
      debugPrint('Error loading analysis: $e');
      return null;
    }
  }

  // Show AI analysis dialog
  static Future<void> showAnalysisDialog(
    BuildContext context,
    AIAnalysisResult result,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            SizedBox(width: 8),
            Text('AI Analysis'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: result.category.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: result.category.color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(result.category.icon, 
                         size: 20, 
                         color: result.category.color),
                    const SizedBox(width: 8),
                    Text(
                      result.category.name,
                      style: TextStyle(
                        color: result.category.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Summary
              const Text(
                'Summary',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.summary,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 16),
              
              // Key Information
              if (result.keyInfo.isNotEmpty) ...[
                const Text(
                  'Key Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...result.keyInfo.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          '${entry.key}:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(entry.value),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 16),
              ],
              
              // Tags
              if (result.tags.isNotEmpty) ...[
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: result.tags.map((tag) => Chip(
                    label: Text(tag),
                    backgroundColor: Colors.blue.shade50,
                    labelStyle: const TextStyle(fontSize: 12),
                  )).toList(),
                ),
                const SizedBox(height: 16),
              ],
              
              // Confidence
              Row(
                children: [
                  const Icon(Icons.verified, size: 16, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    'Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}


