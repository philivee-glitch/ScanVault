import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpgradeManager {
  static const String _keyAppOpenCount = 'app_open_count';
  static const String _keyAdsSeenCount = 'ads_seen_count';
  static const String _keyLastPromptDate = 'last_prompt_date';
  static const String _keyPremiumPurchased = 'premium_purchased';
  
  static const int appOpenThreshold = 5; // Show after 5 app opens
  static const int adsSeenThreshold = 3; // Show after 3 ads seen
  static const int daysBetweenPrompts = 2; // Don't show more than once every 2 days

  // Check if user has purchased premium
  static Future<bool> isPremiumUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPremiumPurchased) ?? false;
  }

  // Set premium status (call this after successful purchase)
  static Future<void> setPremiumPurchased(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPremiumPurchased, value);
  }

  // Increment app open counter and check if we should show prompt
  static Future<bool> checkAppOpenPrompt() async {
    if (await isPremiumUser()) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyAppOpenCount) ?? 0) + 1;
    await prefs.setInt(_keyAppOpenCount, count);
    
    print('App opened $count times');
    
    if (count >= appOpenThreshold) {
      if (await _shouldShowPrompt()) {
        await prefs.setInt(_keyAppOpenCount, 0); // Reset counter
        return true;
      }
    }
    return false;
  }

  // Increment ads seen counter and check if we should show prompt
  static Future<bool> checkAdsSeenPrompt() async {
    if (await isPremiumUser()) return false;
    
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_keyAdsSeenCount) ?? 0) + 1;
    await prefs.setInt(_keyAdsSeenCount, count);
    
    print('Ads seen: $count times');
    
    if (count >= adsSeenThreshold) {
      if (await _shouldShowPrompt()) {
        await prefs.setInt(_keyAdsSeenCount, 0); // Reset counter
        return true;
      }
    }
    return false;
  }

  // Check if enough time has passed since last prompt
  static Future<bool> _shouldShowPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPromptStr = prefs.getString(_keyLastPromptDate);
    
    if (lastPromptStr == null) return true;
    
    final lastPrompt = DateTime.parse(lastPromptStr);
    final daysSince = DateTime.now().difference(lastPrompt).inDays;
    
    return daysSince >= daysBetweenPrompts;
  }

  // Update last prompt date
  static Future<void> _updateLastPromptDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastPromptDate, DateTime.now().toIso8601String());
  }

  // Show upgrade dialog
  static Future<void> showUpgradeDialog(BuildContext context, {String? reason}) async {
    await _updateLastPromptDate();
    
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
            SizedBox(width: 8),
            Text('Upgrade to Premium'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reason != null) ...[
              Text(
                reason,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              SizedBox(height: 16),
            ],
            Text(
              '✨ Remove all ads',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '🚀 Unlock premium features',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '💾 Unlimited storage',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              '🎯 Priority support',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'One-time payment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            Center(
              child: Text(
                '\$4.99',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement in-app purchase here
              _handleUpgradeAction(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text('Upgrade Now', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  // Handle upgrade button press
  static void _handleUpgradeAction(BuildContext context) {
    // TODO: Implement Google Play In-App Purchase
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('In-App Purchase will be implemented soon!'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
    
    // For testing purposes, you can uncomment this to simulate purchase:
    // setPremiumPurchased(true);
  }

  // Reset all counters (for testing)
  static Future<void> resetCounters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAppOpenCount);
    await prefs.remove(_keyAdsSeenCount);
    await prefs.remove(_keyLastPromptDate);
    await prefs.remove(_keyPremiumPurchased);
    print('All counters reset');
  }
}
