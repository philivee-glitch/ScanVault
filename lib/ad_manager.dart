import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'subscription_manager.dart';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  final SubscriptionManager _subscriptionManager = SubscriptionManager();

  // Platform-specific Ad Unit IDs
  static String get _bannerAdUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-9349326189536065/3756929133'; // iOS Real
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Android Test (update on Windows)
    }
    return '';
  }

  static String get _interstitialAdUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-9349326189536065/6466852957'; // iOS Real
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Android Test (update on Windows)
    }
    return '';
  }

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // Banner Ad
  void loadBannerAd(Function(BannerAd) onAdLoaded) {
    if (_subscriptionManager.isPremium) return;

    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdReady = true;
          onAdLoaded(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          _isBannerAdReady = false;
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  Widget getBannerAdWidget() {
    if (_subscriptionManager.isPremium || !_isBannerAdReady || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdReady = false;
  }

  // Interstitial Ad
  void loadInterstitialAd() {
    if (_subscriptionManager.isPremium) return;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd(); // Load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: $error');
              ad.dispose();
              _isInterstitialAdReady = false;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (_subscriptionManager.isPremium || !_isInterstitialAdReady) {
      onAdClosed?.call();
      return;
    }

    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isInterstitialAdReady = false;
        loadInterstitialAd();
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isInterstitialAdReady = false;
        loadInterstitialAd();
        onAdClosed?.call();
      },
    );

    _interstitialAd?.show();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }

  void dispose() {
    disposeBannerAd();
    _interstitialAd?.dispose();
  }
}
