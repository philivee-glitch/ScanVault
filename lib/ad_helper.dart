import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  // Your AdMob Ad Unit IDs
  static const String bannerAdUnitId = 'ca-app-pub-9349326189536065/7646031315';
  static const String interstitialAdUnitId = 'ca-app-pub-9349326189536065/3028129450';
  
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
          print('Banner ad loaded');
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
          print('Interstitial ad loaded');
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
