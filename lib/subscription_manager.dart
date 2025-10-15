import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionManager {
  static const String monthlySubscriptionId = 'scanvault_premium_monthly';
  static const String yearlySubscriptionId = 'scanvault_premium_yearly';
  static const int freeScansPerDay = 5;
  
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  
  // Check if user has premium subscription
  static Future<bool> isPremium() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user has a valid subscription stored locally
      final subscriptionExpiry = prefs.getInt('subscription_expiry');
      if (subscriptionExpiry != null) {
        final expiryDate = DateTime.fromMillisecondsSinceEpoch(subscriptionExpiry);
        if (DateTime.now().isBefore(expiryDate)) {
          return true;
        }
      }
      
      // Check with Google Play Billing
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        return false;
      }
      
      return false;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }
  
  // Get remaining scans for today
  static Future<int> getRemainingScans() async {
    if (await isPremium()) {
      return 999; // Unlimited for premium users
    }
    
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastScanDate = prefs.getString('last_scan_date') ?? '';
    
    if (lastScanDate != today) {
      // New day, reset counter
      await prefs.setString('last_scan_date', today);
      await prefs.setInt('scans_today', 0);
      return freeScansPerDay;
    }
    
    final scansToday = prefs.getInt('scans_today') ?? 0;
    return freeScansPerDay - scansToday;
  }
  
  // Increment scan count
  static Future<bool> incrementScanCount() async {
    if (await isPremium()) {
      return true; // Always allow for premium users
    }
    
    final remaining = await getRemainingScans();
    if (remaining <= 0) {
      return false; // Limit reached
    }
    
    final prefs = await SharedPreferences.getInstance();
    final scansToday = prefs.getInt('scans_today') ?? 0;
    await prefs.setInt('scans_today', scansToday + 1);
    return true;
  }
  
  // Check if scan limit reached
  static Future<bool> canScan() async {
    if (await isPremium()) {
      return true;
    }
    
    return await getRemainingScans() > 0;
  }
  
  // Get available subscription products
  static Future<List<ProductDetails>> getSubscriptionProducts() async {
    try {
      final bool available = await _inAppPurchase.isAvailable();
      if (!available) {
        return [];
      }
      
      const Set<String> productIds = {
        monthlySubscriptionId,
        yearlySubscriptionId,
      };
      
      final ProductDetailsResponse response = 
          await _inAppPurchase.queryProductDetails(productIds);
      
      if (response.error != null) {
        print('Error loading products: ${response.error}');
        return [];
      }
      
      return response.productDetails;
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }
  
  // Purchase a subscription
  static Future<bool> purchaseSubscription(ProductDetails product) async {
    try {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: product,
      );
      
      return await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
    } catch (e) {
      print('Error purchasing subscription: $e');
      return false;
    }
  }
  
  // Save subscription locally (call this after successful purchase)
  static Future<void> saveSubscription(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Set expiry date based on subscription type
    DateTime expiryDate;
    if (productId == monthlySubscriptionId) {
      expiryDate = DateTime.now().add(const Duration(days: 30));
    } else {
      expiryDate = DateTime.now().add(const Duration(days: 365));
    }
    
    await prefs.setInt('subscription_expiry', expiryDate.millisecondsSinceEpoch);
    await prefs.setString('subscription_type', productId);
  }
  
  // Show limit reached dialog
  static Future<void> showLimitReachedDialog(BuildContext context) async {
    final remaining = await getRemainingScans();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Daily Limit Reached'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_clock, size: 60, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              remaining <= 0
                  ? 'You\'ve used all 5 free scans today!'
                  : 'Free users get 5 scans per day.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const Text(
              '✨ Upgrade to Premium for:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Unlimited scans'),
            const Text('• No watermarks'),
            const Text('• All premium features'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              showSubscriptionDialog(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
  
  // Show subscription dialog
  static Future<void> showSubscriptionDialog(BuildContext context) async {
    final products = await getSubscriptionProducts();
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text(
              'Go Premium!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeature('✓ Unlimited daily scans', true),
                    _buildFeature('✓ No watermarks on PDFs', true),
                    _buildFeature('✓ Batch processing', true),
                    _buildFeature('✓ OCR text recognition', true),
                    _buildFeature('✓ Cloud backup & sync', true),
                    _buildFeature('✓ Priority support', true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Choose your plan:',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              if (products.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Unable to load subscription plans.\nPlease try again later.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...products.map((product) => _buildSubscriptionOption(
                  context,
                  product,
                )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
        ],
      ),
    );
  }
  
  static Widget _buildFeature(String text, [bool isPremium = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isPremium ? Colors.blue[900] : null,
        ),
      ),
    );
  }
  
  static Widget _buildSubscriptionOption(
    BuildContext context,
    ProductDetails product,
  ) {
    final isYearly = product.id == yearlySubscriptionId;
    
    return Card(
      elevation: isYearly ? 4 : 1,
      color: isYearly ? Colors.blue[50] : null,
      child: ListTile(
        title: Row(
          children: [
            Text(
              isYearly ? 'Yearly Plan' : 'Monthly Plan',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isYearly) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SAVE 40%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          isYearly ? 'Best Value!' : 'Flexible monthly billing',
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              product.price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              isYearly ? '/year' : '/month',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        onTap: () async {
          Navigator.pop(context);
          
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );
          
          final success = await purchaseSubscription(product);
          
          if (context.mounted) {
            Navigator.pop(context); // Close loading
            
            if (success) {
              await saveSubscription(product.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🎉 Welcome to Premium! Enjoy unlimited scanning!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Purchase cancelled or failed. Please try again.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}