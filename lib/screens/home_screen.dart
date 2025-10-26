import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../subscription_manager.dart';
import '../permissions_manager.dart';
import 'camera_screen.dart';
import 'documents_screen.dart';
import 'settings_screen.dart';
import 'premium_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  int _remainingScans = 5;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
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
      await prefs.setBool('review_requested', true);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ScanVault Premium'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            _buildStatusCard(),
            SizedBox(height: 24),
            
            // Scan Button
            Expanded(
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
                    'Ready to Scan',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tap the button below to start scanning documents',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _startScanning,
                    icon: Icon(Icons.camera_alt, size: 28),
                    label: Text(
                      'Start Scanning',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DocumentsScreen()),
                      );
                    },
                    icon: Icon(Icons.folder),
                    label: Text('View Documents'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_isPremium) {
      return Card(
        color: Colors.amber.shade50,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$_remainingScans scans remaining this month',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => PremiumScreen()));
                },
                icon: Icon(Icons.upgrade, size: 20),
                label: Text('Upgrade to Premium'),
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
      Navigator.push(context, MaterialPageRoute(builder: (context) => PremiumScreen()));
      return;
    }

    // Check camera permission
    final permissionManager = PermissionsManager();
    final hasPermission = await permissionManager.requestCameraPermission(context);
    
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
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
        MaterialPageRoute(builder: (context) => CameraScreen()),
      ).then((_) async {
        // Reload status when returning from camera
        await _loadUserStatus();
        
        // Check if we should request a review
        await _checkAndRequestReview();
      });
    }
  }
}
