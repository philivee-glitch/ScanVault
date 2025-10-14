import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'upgrade_manager.dart';

class AdHelper {
  // Toggle between test and production ads
  static const bool isTestMode = true; // Set to false for production
  
  // Test Ad Unit IDs (provided by Google)
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testAppOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';
  
  // Your Production AdMob Ad Unit IDs
  static const String prodBannerAdUnitId = 'ca-app-pub-9349326189536065/7646031315';
  static const String prodInterstitialAdUnitId = 'ca-app-pub-9349326189536065/3028129450';
  static const String prodAppOpenAdUnitId = 'YOUR_APP_OPEN_ID_HERE'; // Add when ready
  
  // Get the correct Ad Unit ID based on mode
  static String get bannerAdUnitId => isTestMode ? testBannerAdUnitId : prodBannerAdUnitId;
  static String get interstitialAdUnitId => isTestMode ? testInterstitialAdUnitId : prodInterstitialAdUnitId;
  static String get appOpenAdUnitId => isTestMode ? testAppOpenAdUnitId : prodAppOpenAdUnitId;
  
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static bool _interstitialAdLoaded = false;
  static AppOpenAd? _appOpenAd;
  static bool _isShowingAppOpenAd = false;
  
  // Counter for interstitial frequency cap
  static int _saveCounter = 0;
  static const int _interstitialFrequency = 3; // Show every 3rd save
  
  // Context for showing upgrade dialog
  static BuildContext? _context;
  
  static void setContext(BuildContext context) {
    _context = context;
  }

  // Load Banner Ad
  static BannerAd loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) async {
          print('Banner ad loaded (Test Mode: $isTestMode)');
          // Track ad view for upgrade prompt
          if (await UpgradeManager.checkAdsSeenPrompt()) {
            _showUpgradePromptIfContext('You\'ve been seeing ads. Want an ad-free experience?');
          }
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
    return _bannerAd!;
  }

  // Load Interstitial Ad
  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAdLoaded = true;
          print('Interstitial ad loaded (Test Mode: $isTestMode)');
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _interstitialAdLoaded = false;
        },
      ),
    );
  }

  // Show Interstitial Ad with frequency cap
  static void showInterstitialAdAfterSave() {
    _saveCounter++;
    print('Save counter: $_saveCounter');
    
    // Show ad every 3rd save
    if (_saveCounter >= _interstitialFrequency) {
      _saveCounter = 0; // Reset counter
      showInterstitialAd();
    }
  }

  // Show Interstitial Ad
  static void showInterstitialAd() async {
    // Check if user is premium
    if (await UpgradeManager.isPremiumUser()) {
      print('Premium user - skipping ad');
      return;
    }
    
    if (_interstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) async {
          print('Interstitial ad showed');
          // Track ad view for upgrade prompt
          if (await UpgradeManager.checkAdsSeenPrompt()) {
            _showUpgradePromptIfContext('Tired of ads interrupting your workflow?');
          }
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAdLoaded = false;
          // Load next ad
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAdLoaded = false;
          loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
    } else {
      print('Interstitial ad not ready yet');
      // Load ad for next time
      loadInterstitialAd();
    }
  }

  // Load App Open Ad
  static void loadAppOpenAd() {
    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          print('App Open ad loaded (Test Mode: $isTestMode)');
        },
        onAdFailedToLoad: (error) {
          print('App Open ad failed to load: $error');
        },
      ),
    );
  }

  // Show App Open Ad
  static void showAppOpenAdIfAvailable() async {
    // Check if user is premium
    if (await UpgradeManager.isPremiumUser()) {
      print('Premium user - skipping app open ad');
      return;
    }
    
    if (_appOpenAd == null || _isShowingAppOpenAd) {
      loadAppOpenAd();
      return;
    }
    
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) async {
        _isShowingAppOpenAd = true;
        print('App Open ad showed');
        // Track ad view for upgrade prompt
        if (await UpgradeManager.checkAdsSeenPrompt()) {
          _showUpgradePromptIfContext('Start your session ad-free with Premium!');
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('App Open ad failed to show: $error');
        _isShowingAppOpenAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
  }

  // Helper to show upgrade prompt if context is available
  static void _showUpgradePromptIfContext(String reason) {
    if (_context != null && _context!.mounted) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (_context != null && _context!.mounted) {
          UpgradeManager.showUpgradeDialog(_context!, reason: reason);
        }
      });
    }
  }

  // Dispose Banner Ad
  static void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
}
