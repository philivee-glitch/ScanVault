import 'package:flutter/material.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../subscription_manager.dart';
import '../ad_manager.dart';
import 'corner_adjustment_screen.dart';
import 'enhancement_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final AdManager _adManager = AdManager();
  int _scanCountSinceLastAd = 0;
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final List<String> _scannedImages = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _loadScanCount();
    // Preload interstitial ad for free users
    if (!_subscriptionManager.isPremium) {
      _adManager.loadInterstitialAd();
    }
  }

  Future<void> _loadScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _scanCountSinceLastAd = prefs.getInt('scanCountSinceLastAd') ?? 0;
    });
  }

  Future<void> _saveScanCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('scanCountSinceLastAd', _scanCountSinceLastAd);
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _subscriptionManager.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Document'),
        actions: [
          if (_scannedImages.isNotEmpty)
            TextButton.icon(
              onPressed: _finishScanning,
              icon: const Icon(Icons.check, color: Colors.white),
              label: Text(
                'Done (${_scannedImages.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.document_scanner,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            Text(
              _scannedImages.isEmpty
                  ? 'Ready to Scan'
                  : '${_scannedImages.length} page(s) scanned',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Position your document and tap the button',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isScanning ? null : _scanDocument,
              icon: const Icon(Icons.camera_alt, size: 28),
              label: Text(
                _scannedImages.isEmpty ? 'Start Scanning' : 'Add Another Page',
                style: const TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_scannedImages.isNotEmpty && !isPremium) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, size: 16, color: Colors.amber.shade700),
                    const SizedBox(width: 4),
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
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _finishScanning,
                icon: const Icon(Icons.check),
                label: const Text('Finish & Process'),
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
          await _saveScanCount();
          debugPrint('Scan count: $_scanCountSinceLastAd');
          if (_scanCountSinceLastAd >= 3) {
            _adManager.showInterstitialAd();
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
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Scan error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to scan document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _finishScanning() async {
    if (_scannedImages.isEmpty) return;

    final isPremium = _subscriptionManager.isPremium;

    // Show interstitial ad before navigating (free users only)
    if (!isPremium) {
      debugPrint('Scan count before ad check: $_scanCountSinceLastAd');
      if (_scanCountSinceLastAd >= 3) {
        debugPrint('Showing interstitial ad...');
        _scanCountSinceLastAd = 0;
        _adManager.showInterstitialAd(onAdClosed: _navigateToEnhancement);
        return;
      }
    }
    _navigateToEnhancement();
  }

  void _navigateToEnhancement() {
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
        title: const Row(
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
            const Text(
              'You scanned multiple pages, but only the first page will be saved in the free version.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Premium to unlock:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFeature('Unlimited multi-page scanning'),
            _buildFeature('AI-powered enhancement'),
            _buildFeature('OCR text recognition'),
            _buildFeature('Cloud backup'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Start 3-day FREE trial',
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
            child: const Text('Continue with First Page'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upgrade to Premium for multi-page scans!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Free Trial'),
          ),
        ],
      ),
    );
  }

  void _showMultiPageUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
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
            const Text(
              'Multi-page scanning is a Premium feature.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Premium to unlock:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildFeature('Unlimited multi-page scanning'),
            _buildFeature('AI-powered enhancement'),
            _buildFeature('OCR text recognition'),
            _buildFeature('Cloud backup'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.celebration, color: Colors.green),
                  const SizedBox(width: 8),
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
            child: const Text('Continue with Single Page'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upgrade to Premium for unlimited scans!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Free Trial'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Limit Reached'),
        content: const Text(
          'You have used all 5 free scans for today. Upgrade to Premium for unlimited scans and AI features! Start your 3-day FREE trial now!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Upgrade to Premium for unlimited scans!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Free Trial'),
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
