import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';
import '../subscription_manager.dart';
import '../permissions_manager.dart';
import 'camera_screen.dart';
import 'documents_screen.dart';
import 'settings_screen.dart';
import 'premium_screen.dart';
import '../ad_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  final AdManager _adManager = AdManager();
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  final InAppReview _inAppReview = InAppReview.instance;
  int _remainingScans = 5;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
    _loadBannerAd();
  }

    void _loadBannerAd() {
    if (!_isPremium) {
      _adManager.loadBannerAd((ad) {
        setState(() {
          _bannerAd = ad;
          _isBannerAdLoaded = true;
        });
      });
    }
  }

  Future<void> _loadUserStatus() async {
    final remaining = await _subscriptionManager.getRemainingScans();
    final premium = _subscriptionManager.isPremium;
    
    setState(() {
      _remainingScans = remaining;
      _isPremium = premium;
    });
  }

  Future<void> _checkAndRequestReview() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get total scans completed
    final totalScans = prefs.getInt('total_scans_completed') ?? 0;
    final reviewRequested = prefs.getBool('review_requested') ?? false;
    
    // Increment total scans
    final newTotal = totalScans + 1;
    await prefs.setInt('total_scans_completed', newTotal);
    
    // Show review after 5 scans, only once
    if (newTotal == 5 && !reviewRequested) {
      await _requestReview();
      await prefs.setBool('review_requested', true);
    }
  }

  Future<void> _requestReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        _inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('Error requesting review: $e');
      // Fail silently - don't disrupt user experience
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScanVault Premium'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            _buildStatusCard(),
            const SizedBox(height: 24),
            
            // Scan Button
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.document_scanner,
                    size: 100,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Ready to Scan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap the button below to start scanning documents',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _startScanning,
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text(
                      'Start Scanning',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const DocumentsScreen()),
                      );
                    },
                    icon: const Icon(Icons.folder),
                    label: const Text('View Documents'),
                  ),
                ],
              ),
            ),
                ],
          ),
        ),
        bottomNavigationBar: !_isPremium && _isBannerAdLoaded && _bannerAd != null
            ? SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            : null,
      );
    }

    Widget _buildStatusCard() {
    if (_isPremium) {
      return Card(
        color: Colors.amber.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Premium Active',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (false) // Trial not implemented
                      Text(
                        'Trial: ${"N/A"}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      )
                    else
                      Text(
                        'Unlimited scans, AI features',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$_remainingScans scans remaining this month',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
                },
                icon: const Icon(Icons.upgrade, size: 20),
                label: const Text('Upgrade to Premium'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _startScanning() async {
    // Check if user can scan
    final canScan = await _subscriptionManager.canScanToday();
    
    if (!canScan) {
      // Show upgrade dialog
      Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
      return;
    }

    // Check camera permission
    final permissionManager = PermissionsManager();
    final hasPermission = await permissionManager.requestCameraPermission(context);
    
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to scan documents'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Navigate to camera screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
      ).then((_) async {
        // Reload status when returning from camera
        await _loadUserStatus();
        
        // Check if we should request a review
        await _checkAndRequestReview();
      });
    }
  }
}






