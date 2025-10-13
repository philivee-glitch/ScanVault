import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // Toggle between test and production ads
  static const bool isTestMode = true; // Set to false for production
  
  // Test Ad Unit IDs (provided by Google)
  static const String testBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';
  
  // Your Production AdMob Ad Unit IDs
  static const String prodBannerAdUnitId = 'ca-app-pub-9349326189536065/7646031315';
  static const String prodInterstitialAdUnitId = 'ca-app-pub-9349326189536065/3028129450';
  
  // Get the correct Ad Unit ID based on mode
  static String get bannerAdUnitId => isTestMode ? testBannerAdUnitId : prodBannerAdUnitId;
  static String get interstitialAdUnitId => isTestMode ? testInterstitialAdUnitId : prodInterstitialAdUnitId;
  
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static bool _interstitialAdLoaded = false;

  // Load Banner Ad
  static BannerAd loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded (Test Mode: $isTestMode)');
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

  // Show Interstitial Ad
  static void showInterstitialAd() {
    if (_interstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAdLoaded = false;
          // Load next ad
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
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

  // Dispose Banner Ad
  static void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }
}