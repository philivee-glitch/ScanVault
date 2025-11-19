import 'package:flutter/material.dart';
import '../subscription_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          // Subscription Status Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _subscriptionManager.isAdFree 
                  ? Colors.amber.shade50 
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _subscriptionManager.isAdFree 
                    ? Colors.amber.shade200 
                    : Colors.blue.shade200,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _subscriptionManager.isAdFree ? Icons.star : Icons.free_breakfast,
                      color: _subscriptionManager.isAdFree 
                          ? Colors.amber.shade700 
                          : Colors.blue.shade700,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _subscriptionManager.isAdFree 
                                ? 'Premium - Ad Free' 
                                : 'Free - Supported by ads',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _subscriptionManager.isAdFree 
                                  ? Colors.amber.shade900 
                                  : Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subscriptionManager.isAdFree
                                ? 'Thank you for your support!'
                                : 'All features available',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!_subscriptionManager.isAdFree) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/premium');
                      },
                      icon: const Icon(Icons.block),
                      label: const Text('Remove Ads'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(),

          // Features Section
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Available Features',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          _buildFeatureItem(
            icon: Icons.document_scanner,
            title: 'Unlimited Scans',
            subtitle: 'Scan as many documents as you need',
          ),
          _buildFeatureItem(
            icon: Icons.text_fields,
            title: 'OCR Text Recognition',
            subtitle: 'Extract text from your documents',
          ),
          _buildFeatureItem(
            icon: Icons.psychology,
            title: 'AI Document Analysis',
            subtitle: 'Get insights about your documents',
          ),
          _buildFeatureItem(
            icon: Icons.layers,
            title: 'Batch Operations',
            subtitle: 'Process multiple documents at once',
          ),

          const Divider(),

          // Actions Section
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Purchases'),
            subtitle: const Text('Restore previous ad removal purchase'),
            onTap: () async {
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              await _subscriptionManager.restorePurchases();
              
              if (!mounted) return;
              
              // Close loading
              Navigator.pop(context);

              // Show result
              setState(() {});
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _subscriptionManager.isAdFree
                      ? 'Purchases restored successfully!'
                      : 'No previous purchases found'
                  ),
                ),
              );
            },
          ),

          const Divider(),

          // App Info
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About VaultScan'),
            subtitle: const Text('Version 1.4.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'VaultScan',
                applicationVersion: '1.4.0',
                applicationIcon: const Icon(Icons.document_scanner, size: 48),
                children: const [
                  Text('Professional document scanner with AI-powered features.'),
                ],
              );
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              Navigator.pushNamed(context, '/privacy');
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () {
              Navigator.pushNamed(context, '/terms');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.green.shade700),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.check_circle, color: Colors.green.shade700),
    );
  }
}
