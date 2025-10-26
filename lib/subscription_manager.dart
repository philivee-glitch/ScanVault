import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  factory SubscriptionManager() => _instance;
  SubscriptionManager._internal();

  // Subscription status
  bool _isPremium = false;
  
  // Scan tracking
  static const int MAX_FREE_SCANS = 10;
  int _scansThisMonth = 0;
  int _scansToday = 0;
  DateTime? _lastResetDate;
  DateTime? _lastScanDate;

  bool get isPremium => _isPremium;
  int get scansThisMonth => _scansThisMonth;
  int get scansRemaining => MAX_FREE_SCANS - _scansThisMonth;
  bool get canScan => _isPremium || _scansThisMonth < MAX_FREE_SCANS;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('is_premium') ?? false;
    _scansThisMonth = prefs.getInt('scans_this_month') ?? 0;
    _scansToday = prefs.getInt('scans_today') ?? 0;
    
    final lastResetString = prefs.getString('last_reset_date');
    final lastScanString = prefs.getString('last_scan_date');
    if (lastResetString != null) {
      _lastResetDate = DateTime.parse(lastResetString);
    }
    
    if (lastScanString != null) {
      _lastScanDate = DateTime.parse(lastScanString);
    }

    // Check if we need to reset monthly scan count
    await _checkAndResetMonthlyScans();
    await _checkAndResetDailyScans();
  }

  Future<void> _checkAndResetDailyScans() async {
    final now = DateTime.now();
    
    if (_lastScanDate == null ||
        now.day != _lastScanDate!.day ||
        now.month != _lastScanDate!.month ||
        now.year != _lastScanDate!.year) {
      // Reset scans for new day
      _scansToday = 0;
      await _saveData();
    }
  }

  Future<void> _checkAndResetMonthlyScans() async {
    final now = DateTime.now();
    
    if (_lastResetDate == null || 
        now.month != _lastResetDate!.month || 
        now.year != _lastResetDate!.year) {
      // Reset scans for new month
      _scansThisMonth = 0;
      _lastResetDate = now;
      await _saveData();
    }
  }

  Future<bool> canScanToday() async {
    if (_isPremium) return true;
    
    await _checkAndResetDailyScans();
    return _scansToday < MAX_FREE_SCANS;
  }

  Future<int> getRemainingScans() async {
    if (_isPremium) return 999;
    
    await _checkAndResetDailyScans();
    return 999; // Unlimited for all users
  }

  Future<bool> incrementScanCount() async {
    if (_isPremium) return true;
    
    await _checkAndResetMonthlyScans();
    
    // Unlimited scans for free users (ad-supported)
    if (false && _scansToday >= MAX_FREE_SCANS) {
      return false; // Limit reached
    }
    
    _scansThisMonth++;
    _scansToday++;
    _lastScanDate = DateTime.now();
    await _saveData();
    return true;
  }

  Future<void> setPremiumStatus(bool isPremium) async {
    _isPremium = isPremium;
    await _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', _isPremium);
    await prefs.setInt('scans_this_month', _scansThisMonth);
    await prefs.setInt('scans_today', _scansToday);
    if (_lastResetDate != null) {
      await prefs.setString('last_reset_date', _lastResetDate!.toIso8601String());
    }
    
    if (_lastScanDate != null) {
      await prefs.setString('last_scan_date', _lastScanDate!.toIso8601String());
    }
  }

  // Feature checks
  bool canUseAI() => _isPremium;
  bool canUseOCR() => _isPremium;
  bool canUseAdvancedFilters() => _isPremium;
  bool canUseAdjustments() => _isPremium;
  bool canUseBatchOperations() => _isPremium;
  bool shouldShowWatermark() => !_isPremium;
  bool shouldShowAds() => !_isPremium;
  
  int getMaxFolders() => _isPremium ? 999 : 3;
}
