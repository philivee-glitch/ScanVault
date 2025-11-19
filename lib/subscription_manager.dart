import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Ad removal product IDs (not feature unlocks)
  static const String monthlyNoAdsProductId = 'vaultscan.noads.monthly';
  static const String yearlyNoAdsProductId = 'vaultscan.noads.yearly';
  static const String lifetimeNoAdsProductId = 'vaultscan.noads.lifetime';

  bool _isAdFree = false;
  List<ProductDetails> _products = [];

  // Getter for ad-free status (replaces isPremium)
  bool get isAdFree => _isAdFree;
  
  // For backwards compatibility, keep isPremium but it now means "ad-free"
  bool get isPremium => _isAdFree;

  List<ProductDetails> get products => _products;

  // Initialize subscription manager
  Future<void> initialize() async {
    // Check if IAP is available
    final bool available = await _iap.isAvailable();
    if (!available) {
      print('In-app purchases not available');
      await _loadLocalStatus();
      return;
    }

    // Listen to purchase updates
    final Stream<List<PurchaseDetails>> purchaseUpdated = _iap.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription?.cancel(),
      onError: (error) => print('Purchase stream error: $error'),
    );

    // Load products
    await _loadProducts();
    
    // Restore previous purchases
    await restorePurchases();
  }

  // Load available products from App Store
  Future<void> _loadProducts() async {
    final Set<String> productIds = {
      monthlyNoAdsProductId,
      yearlyNoAdsProductId,
      lifetimeNoAdsProductId,
    };

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails(productIds);
      
      if (response.error != null) {
        print('Error loading products: ${response.error}');
        return;
      }

      _products = response.productDetails;
      print('Loaded ${_products.length} products');
    } catch (e) {
      print('Exception loading products: $e');
    }
  }

  // Load ad-free status from local storage
  Future<void> _loadLocalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isAdFree = prefs.getBool('is_ad_free') ?? false;
  }

  // Save ad-free status to local storage
  Future<void> _saveLocalStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_ad_free', _isAdFree);
  }

  // Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        // Verify purchase and unlock ad-free
        _unlockAdFree();
      }

      // Complete the purchase
      if (purchaseDetails.pendingCompletePurchase) {
        _iap.completePurchase(purchaseDetails);
      }
    }
  }

  // Unlock ad-free status
  Future<void> _unlockAdFree() async {
    _isAdFree = true;
    await _saveLocalStatus();
    print('Ad-free unlocked!');
  }

  // Purchase ad removal
  Future<bool> purchaseAdRemoval(String productId) async {
    final ProductDetails? productDetails = _products.firstWhere(
      (product) => product.id == productId,
      orElse: () => throw Exception('Product not found'),
    );

    if (productDetails == null) {
      print('Product not found: $productId');
      return false;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: productDetails,
    );

    try {
      // For subscriptions (monthly/yearly)
      if (productId == monthlyNoAdsProductId || productId == yearlyNoAdsProductId) {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      } 
      // For lifetime (one-time purchase)
      else {
        return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }
    } catch (e) {
      print('Purchase error: $e');
      return false;
    }
  }

  // Restore previous purchases
  Future<void> restorePurchases() async {
    try {
      await _iap.restorePurchases();
      // The _onPurchaseUpdate will handle the restored purchases
    } catch (e) {
      print('Restore purchases error: $e');
    }
  }

  // Dispose subscription
  void dispose() {
    _subscription?.cancel();
  }

  // Backwards compatibility methods - all features are now free
  bool canScanToday() => true; // Always allow scanning
  int getRemainingScans() => 999; // Unlimited
  Future<void> incrementScanCount() async {} // No-op, no limits
  bool canUseOCR() => true; // Always allow OCR
  bool canUseAI() => true; // Always allow AI
  bool canUseBatchOperations() => true; // Always allow batch
  int getMaxFolders() => 999; // Unlimited folders
  
  // For testing: manually set ad-free status
  Future<void> setAdFreeForTesting(bool isAdFree) async {
    _isAdFree = isAdFree;
    await _saveLocalStatus();
  }
}


