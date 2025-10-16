import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionManager {
  static const String monthlyProductId = 'scanvault_premium_monthly';
  static const String yearlyProductId = 'scanvault_premium_yearly';
  
  // Pricing
  static const String monthlyPrice = '\$6.99';
  static const String yearlyPrice = '\$49.99';
  static const String yearlySavings = '40%';
  
  // Trial configuration
  static const int trialDays = 7;
  
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isPremium = false;
  bool _isInTrial = false;
  DateTime? _trialEndDate;
  
  bool get isPremium => _isPremium || _isInTrial;
  bool get isInTrial => _isInTrial;
  DateTime? get trialEndDate => _trialEndDate;
  List<ProductDetails> get products => _products;
  bool get isAvailable => _isAvailable;

  Future<void> initialize() async {
    _isAvailable = await _iap.isAvailable();
    
    if (_isAvailable) {
      // Listen to purchase updates
      _subscription = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _subscription?.cancel(),
        onError: (error) => debugPrint('Purchase Error: $error'),
      );

      // Load products
      await _loadProducts();
      
      // Check for existing purchases
      await _checkPurchaseStatus();
      
      // Restore purchases on startup
      await restorePurchases();
    }
    
    // Check trial status
    await _checkTrialStatus();
  }

  Future<void> _loadProducts() async {
    const Set<String> productIds = {
      monthlyProductId,
      yearlyProductId,
    };

    try {
      final ProductDetailsResponse response = 
          await _iap.queryProductDetails(productIds);
      
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      debugPrint('Loaded ${_products.length} products');
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  Future<void> _checkPurchaseStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
  }

  Future<void> _checkTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    final trialStartStr = prefs.getString('trial_start_date');
    final hasUsedTrial = prefs.getBool('has_used_trial') ?? false;
    
    if (trialStartStr != null && !hasUsedTrial) {
      final trialStart = DateTime.parse(trialStartStr);
      _trialEndDate = trialStart.add(Duration(days: trialDays));
      
      if (DateTime.now().isBefore(_trialEndDate!)) {
        _isInTrial = true;
        debugPrint('User is in trial until ${_trialEndDate}');
      } else {
        // Trial expired
        _isInTrial = false;
        await prefs.setBool('has_used_trial', true);
        debugPrint('Trial has expired');
      }
    }
  }

  Future<bool> startTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasUsedTrial = prefs.getBool('has_used_trial') ?? false;
    
    if (hasUsedTrial || _isInTrial || _isPremium) {
      return false; // Already used trial or is premium
    }
    
    // Start trial
    final now = DateTime.now();
    await prefs.setString('trial_start_date', now.toIso8601String());
    _isInTrial = true;
    _trialEndDate = now.add(Duration(days: trialDays));
    
    debugPrint('Trial started! Ends: ${_trialEndDate}');
    return true;
  }

  String getTrialTimeRemaining() {
    if (!_isInTrial || _trialEndDate == null) return '';
    
    final remaining = _trialEndDate!.difference(DateTime.now());
    
    if (remaining.inDays > 0) {
      return '${remaining.inDays} days left';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hours left';
    } else {
      return 'Less than 1 hour left';
    }
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending...');
      } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                 purchaseDetails.status == PurchaseStatus.restored) {
        
        // Verify purchase (in production, verify with your backend)
        final valid = await _verifyPurchase(purchaseDetails);
        
        if (valid) {
          await _deliverProduct(purchaseDetails);
        }
        
        // Complete the purchase
        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      } else if (purchaseDetails.status == PurchaseStatus.error) {
        debugPrint('Purchase error: ${purchaseDetails.error}');
      }
    }
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    // TODO: In production, verify with your backend server
    // For now, we trust the platform
    return true;
  }

  Future<void> _deliverProduct(PurchaseDetails purchaseDetails) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Grant premium access
    await prefs.setBool('is_premium', true);
    await prefs.setString('purchase_id', purchaseDetails.purchaseID ?? '');
    await prefs.setString('product_id', purchaseDetails.productID);
    
    _isPremium = true;
    _isInTrial = false; // End trial if they purchase
    
    debugPrint('Premium access granted!');
  }

  Future<bool> buyProduct(ProductDetails product) async {
    if (!_isAvailable) {
      debugPrint('In-app purchase not available');
      return false;
    }

    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    try {
      final bool success = await _iap.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      return success;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (!_isAvailable) return;

    try {
      await _iap.restorePurchases();
      debugPrint('Purchases restored');
    } catch (e) {
      debugPrint('Restore failed: $e');
    }
  }

  // Scan counter for free tier
  Future<bool> canScanToday() async {
    if (isPremium) return true;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final lastScanDate = prefs.getString('last_scan_date') ?? '';
    final scanCount = prefs.getInt('scan_count') ?? 0;

    if (lastScanDate != today) {
      // Reset counter for new day
      await prefs.setString('last_scan_date', today);
      await prefs.setInt('scan_count', 0);
      return true;
    }

    return scanCount < 5; // Free tier limit
  }

  Future<void> incrementScanCount() async {
    if (isPremium) return; // No limit for premium

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final lastScanDate = prefs.getString('last_scan_date') ?? '';
    
    if (lastScanDate != today) {
      await prefs.setString('last_scan_date', today);
      await prefs.setInt('scan_count', 1);
    } else {
      final scanCount = prefs.getInt('scan_count') ?? 0;
      await prefs.setInt('scan_count', scanCount + 1);
    }
  }

  Future<int> getRemainingScans() async {
    if (isPremium) return 999; // Unlimited

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toString().substring(0, 10);
    final lastScanDate = prefs.getString('last_scan_date') ?? '';
    
    if (lastScanDate != today) {
      return 5;
    }
    
    final scanCount = prefs.getInt('scan_count') ?? 0;
    return 5 - scanCount;
  }

  void dispose() {
    _subscription?.cancel();
  }

  // Show subscription dialog
  static Future<void> showSubscriptionDialog(BuildContext context) async {
    final manager = SubscriptionManager();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 8),
            Text('Upgrade to Premium'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trial banner
              if (!manager.isPremium)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.celebration, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🎉 Start your $trialDays-day FREE trial!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 16),
              
              Text(
                'Premium Features:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              _buildFeature('✨ Unlimited scans per day'),
              _buildFeature('🚫 No watermarks on PDFs'),
              _buildFeature('🔍 OCR text extraction'),
              _buildFeature('📄 Searchable PDFs'),
              _buildFeature('🤖 AI document summarization'),
              _buildFeature('🏷️ Smart categorization'),
              _buildFeature('🔎 AI-powered search'),
              _buildFeature('☁️ Cloud backup (coming soon)'),
              SizedBox(height: 16),
              
              // Pricing
              _buildPricingCard(
                'Monthly Plan',
                monthlyPrice,
                'per month',
                false,
              ),
              SizedBox(height: 8),
              _buildPricingCard(
                'Yearly Plan',
                yearlyPrice,
                'per year (Save $yearlySavings!)',
                true,
              ),
              SizedBox(height: 12),
              
              Text(
                'Cancel anytime. Auto-renews.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Start trial first
              final started = await manager.startTrial();
              if (started && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 $trialDays-day free trial activated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Start Free Trial'),
          ),
        ],
      ),
    );
  }

  static Widget _buildFeature(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 20),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  static Widget _buildPricingCard(
    String title,
    String price,
    String subtitle,
    bool recommended,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: recommended ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: recommended ? Colors.blue : Colors.grey.shade300,
          width: recommended ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (recommended)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}