import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'dart:io';
import '../subscription_manager.dart';
// import '../ad_manager.dart';  // TODO: Re-enable with real ads
import 'corner_adjustment_screen.dart';
import 'enhancement_screen.dart';
import 'settings_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  //   final AdManager _adManager = AdManager();
  int _scanCountSinceLastAd = 0;
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  List<String> _scannedImages = [];
  bool _isScanning = false;

    @override
  void initState() {
    super.initState();
    // Preload interstitial ad for free users
    if (!_subscriptionManager.isPremium) {
      //       _adManager.loadInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _subscriptionManager.isPremium;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Document'),
        actions: [
          if (_scannedImages.isNotEmpty)
            TextButton.icon(
              onPressed: _finishScanning,
              icon: Icon(Icons.check, color: Colors.white),
              label: Text(
                'Done (${_scannedImages.length})',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 24),
            Text(
              _scannedImages.isEmpty 
                  ? 'Ready to Scan'
                  : '${_scannedImages.length} page(s) scanned',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Position your document and tap the button',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _scanDocument,
              icon: Icon(Icons.camera_alt, size: 28),
              label: Text(
                _scannedImages.isEmpty ? 'Start Scanning' : 'Add Another Page',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_scannedImages.isNotEmpty && !isPremium) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, size: 16, color: Colors.amber.shade700),
                    SizedBox(width: 4),
                    Text(
                      'Multi-page scanning requires Premium',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_scannedImages.isNotEmpty) ...[
              SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _finishScanning,
                icon: Icon(Icons.check),
                label: Text('Finish & Process'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _scanDocument() async {
    final isPremium = _subscriptionManager.isPremium;
    
    if (!isPremium && _scannedImages.isNotEmpty) {
      _showMultiPageUpgradeDialog();
      return;
    }
    
    final canScan = await _subscriptionManager.canScanToday();
    
    if (!canScan) {
      if (mounted) {
        _showUpgradeDialog();
      }
      return;
    }

    setState(() => _isScanning = true);

    try {
      List<String>? pictures = await CunningDocumentScanner.getPictures(
        noOfPages: isPremium ? 50 : 1,
      );

      if (pictures != null && pictures.isNotEmpty) {
        if (!isPremium && pictures.length > 1) {
          if (mounted) {
            _showMultiPageBlockedDialog();
          }
          pictures = [pictures.first];
        }
        
        await _subscriptionManager.incrementScanCount();

        // Show interstitial ad every 3 scans (free users only)
        if (!isPremium) {
          _scanCountSinceLastAd++;
          if (_scanCountSinceLastAd >= 3) {
            //             _adManager.showInterstitialAd();
            _scanCountSinceLastAd = 0;
          }
        }
        
        setState(() {
          _scannedImages.addAll(pictures!);
        });

        if (mounted) {
          final remaining = await _subscriptionManager.getRemainingScans();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✓ Page ${_scannedImages.length} captured${!isPremium ? ' • $remaining scans left this month' : ''}',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Scan error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to scan document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  void _finishScanning() {
    if (_scannedImages.isEmpty) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancementScreen(
          imagePath: _scannedImages.first,
          additionalPages: _scannedImages.length > 1 
              ? _scannedImages.sublist(1) 
              : null,
        ),
      ),
    );
  }

  void _showMultiPageBlockedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Text('Multi-Page Detected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You scanned multiple pages, but only the first page will be saved.',
              style: TextStyle(fontSize: 15),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.workspace_premium, color: Colors.amber.shade700),
                      SizedBox(width: 8),
                      Text(
                        'Upgrade to Premium',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('Unlock multi-page scanning:'),
                  SizedBox(height: 4),
                  _buildFeature('ðŸ“„ Scan unlimited pages per document'),
                  _buildFeature('â™¾ï¸ Unlimited daily scans'),
                  _buildFeature('🚫 No watermarks'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
            ),
            child: Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _showMultiPageUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Text('Premium Feature'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Multi-page scanning is a Premium feature!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text('With Premium you get:'),
            SizedBox(height: 8),
            _buildFeature('ðŸ“„ Unlimited pages per document'),
            _buildFeature('â™¾ï¸ Unlimited daily scans'),
            _buildFeature('🤖 AI document analysis'),
            _buildFeature('ðŸ” OCR text extraction'),
            _buildFeature('🚫 No watermarks'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  Icon(Icons.celebration, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Upgrade to Premium',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Continue with Single Page'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upgrade to Premium for unlimited scans!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Start Free Trial'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Daily Limit Reached'),
        content: Text(
          'You have used all 5 free scans for today. Upgrade to Premium for unlimited scans and AI features! Start your 7-day FREE trial now!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Upgrade to Premium for unlimited scans!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Start Free Trial'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}



