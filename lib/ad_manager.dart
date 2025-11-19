import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'subscription_manager.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  final SubscriptionManager _subscriptionManager = SubscriptionManager();

  // Test ad unit IDs (use these during development)
  // Replace with your real ad unit IDs before publishing
  static const String _testBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910';
  
  // Production ad unit IDs (get from AdMob dashboard)
  static const String _prodBannerAdUnitId = 'YOUR_BANNER_AD_UNIT_ID';
  static const String _prodInterstitialAdUnitId = 'YOUR_INTERSTITIAL_AD_UNIT_ID';

  // Use test ads during development
  static const bool _useTestAds = true; // Set to false for production

  String get bannerAdUnitId => _useTestAds ? _testBannerAdUnitId : _prodBannerAdUnitId;
  String get interstitialAdUnitId => _useTestAds ? _testInterstitialAdUnitId : _prodInterstitialAdUnitId;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;

  // Initialize AdMob
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Check if ads should be shown (based on subscription status)
  bool shouldShowAds() {
    return !_subscriptionManager.isAdFree;
  }

  // Load banner ad
  Future<void> loadBannerAd() async {
    if (!shouldShowAds()) return;

    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded');
          _isBannerAdReady = true;
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: $error');
          _isBannerAdReady = false;
          ad.dispose();
          _bannerAd = null;
        },
      ),
    );

    await _bannerAd?.load();
  }

  // Load interstitial ad
  Future<void> loadInterstitialAd() async {
    if (!shouldShowAds()) return;

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('Interstitial ad loaded');
          _interstitialAd = ad;
          _isInterstitialAdReady = true;

          // Set full screen content callback
          _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
              // Preload next interstitial
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Interstitial ad failed to show: $error');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdReady = false;
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  // Get banner ad widget
  Widget? getBannerAdWidget() {
    if (!shouldShowAds() || _bannerAd == null || !_isBannerAdReady) {
      return null;
    }
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  // Show interstitial ad
  Future<void> showInterstitialAd() async {
    if (!shouldShowAds()) return;

    if (_interstitialAd != null && _isInterstitialAdReady) {
      await _interstitialAd?.show();
      _isInterstitialAdReady = false;
      _interstitialAd = null;
    } else {
      print('Interstitial ad not ready');
    }
  }

  // Dispose ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}


