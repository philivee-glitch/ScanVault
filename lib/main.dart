import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:scanvault_app/ad_helper.dart';
import 'package:scanvault_app/upgrade_manager.dart';
import 'package:scanvault_app/screens/documents_screen.dart';
import 'package:scanvault_app/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  
  // Pre-load interstitial and app open ads
  AdHelper.loadInterstitialAd();
  AdHelper.loadAppOpenAd();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _lastAdShownTime;
  static const Duration _adCooldown = Duration(minutes: 15);
  bool _hasCheckedAppOpenPrompt = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAppOpenPrompt();
  }

  Future<void> _checkAppOpenPrompt() async {
    // Wait a bit for the app to fully load
    await Future.delayed(Duration(seconds: 1));
    
    if (!_hasCheckedAppOpenPrompt && mounted) {
      _hasCheckedAppOpenPrompt = true;
      
      // Check if we should show upgrade prompt based on app opens
      if (await UpgradeManager.checkAppOpenPrompt()) {
        if (mounted) {
          UpgradeManager.showUpgradeDialog(
            context,
            reason: 'Welcome back! Enjoying ScanVault? Go ad-free!',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // Show app open ad only if cooldown period has passed
      if (_lastAdShownTime == null ||
          DateTime.now().difference(_lastAdShownTime!) > _adCooldown) {
        AdHelper.showAppOpenAdIfAvailable();
        _lastAdShownTime = DateTime.now();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set context for AdHelper to show upgrade prompts
    AdHelper.setContext(context);
    
    return MaterialApp(
      title: 'ScanVault',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}