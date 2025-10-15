import 'package:flutter/material.dart';
import 'camera_screen.dart';
import 'documents_screen.dart';
import '../subscription_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isPremium = false;
  int remainingScans = 5;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    final premium = await SubscriptionManager.isPremium();
    final remaining = await SubscriptionManager.getRemainingScans();
    
    setState(() {
      isPremium = premium;
      remainingScans = remaining;
      isLoading = false;
    });
  }

  Future<void> _startScanning() async {
    // Check if user can scan
    final canScan = await SubscriptionManager.canScan();
    
    if (!canScan && mounted) {
      // Show limit reached dialog
      SubscriptionManager.showLimitReachedDialog(context);
      return;
    }
    
    // Navigate to camera
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(camera: null),
      ),
    );
    
    // Reload subscription status when returning
    if (result != null) {
      _loadSubscriptionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // ScanVault Logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.document_scanner,
                  size: 80,
                  color: Colors.blue,
                ),
              ),
              
              const SizedBox(height: 30),
              
              // App Title with Premium Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ScanVault',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (isPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 10),
              
              // Subtitle
              const Text(
                'Professional Document Scanner',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                ),
              ),
              
              const SizedBox(height: 15),
              
              // Scan Counter or Premium Badge
              if (isLoading)
                const CircularProgressIndicator(color: Colors.white)
              else if (isPremium)
                const Text(
                  '✨ Unlimited Scans • No Watermarks ✨',
                  style: TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$remainingScans / 5 scans remaining today',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              
              const Spacer(flex: 1),
              
              // Start Scanning Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ElevatedButton(
                  onPressed: _startScanning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 60),
                  ),
                  child: const Text(
                    'Start Scanning',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // My Documents Link
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DocumentsScreen(),
                    ),
                  );
                  // Reload when returning
                  _loadSubscriptionStatus();
                },
                child: const Text(
                  'My Documents',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
              
              // Upgrade Button for Free Users
              if (!isPremium && !isLoading) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => SubscriptionManager.showSubscriptionDialog(context),
                  icon: const Icon(Icons.star, color: Colors.amberAccent),
                  label: const Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}