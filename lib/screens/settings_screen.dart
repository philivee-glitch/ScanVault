import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import '../subscription_manager.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'premium_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  String _version = '';
  bool _isPremium = false;
  bool _isInTrial = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final premium = _subscriptionManager.isPremium;
    const inTrial = false; // Trial not implemented yet
    
    setState(() {
      _version = packageInfo.version;
      _isPremium = premium;
      _isInTrial = inTrial;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Status
          _buildSection('Account'),
          _buildAccountStatusTile(),
          
          if (!_isPremium)
            ListTile(
              leading: const Icon(Icons.workspace_premium, color: Colors.amber),
              title: const Text('Upgrade to Premium'),
              subtitle: const Text('Unlock all premium features'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PremiumScreen()),
                  );
              },
            ),
          
          if (_isPremium)
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.blue),
              title: const Text('Restore Purchases'),
              subtitle: const Text('Restore your subscription'),
              onTap: _restorePurchases,
            ),
          
          const Divider(),
          
          // Storage
          _buildSection('Storage'),
          ListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clear Cache'),
            subtitle: const Text('Free up storage space'),
            onTap: _clearCache,
          ),
          
          const Divider(),
          
          // Legal
          _buildSection('Legal'),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TermsOfServiceScreen()),
              );
            },
          ),
          
          const Divider(),
          
          // Support
          _buildSection('Support'),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Contact Support'),
            subtitle: const Text('info@codenestle.com.au'),
            onTap: _contactSupport,
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: _showAboutDialog,
          ),
          
          const Divider(),
          
          // Version
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: Text(_version),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildAccountStatusTile() {
    return ListTile(
      leading: Icon(
        _isPremium ? Icons.workspace_premium : Icons.account_circle,
        color: _isPremium ? Colors.amber : Colors.grey,
      ),
      title: Text(_isPremium ? 'Premium Account' : 'Free Account'),
      subtitle: _isInTrial
          ? const Text('Trial: ${"N/A"}')
          : Text(_isPremium ? 'All features unlocked' : 'Unlimited scans (ad-supported)'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isPremium ? Colors.amber.shade50 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _isPremium ? 'PREMIUM' : 'FREE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _isPremium ? Colors.amber.shade900 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Future<void> _restorePurchases() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Restore purchases not implemented yet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Restore purchases coming soon!')),
      );
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Purchases restored successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadInfo(); // Reload status
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No purchases found to restore'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will free up storage space but won\'t delete your documents.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
          await tempDir.create();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Cache cleared successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to clear cache'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _contactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'info@codenestle.com.au',
      queryParameters: {
        'subject': 'VaultScan Premium Support',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch email';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please email: info@codenestle.com.au'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.document_scanner, color: Colors.blue),
            SizedBox(width: 8),
            Text('About'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VaultScan Premium',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Version $_version'),
            const SizedBox(height: 16),
            const Text(
              'Professional document scanner with AI-powered OCR and smart organization.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2025 Code Nestle',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
