import 'package:flutter/material.dart';
import '../subscription_manager.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({Key? key}) : super(key: key);

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  bool _isLoading = false;
  String? _selectedProductId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove Ads'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade600, Colors.orange.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Go Ad-Free!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'All features, zero interruptions',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Premium Features Header
            const Text(
              'Premium Features:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Features List
            _buildFeatureItem(
              icon: Icons.document_scanner,
              title: 'Unlimited Scans',
              description: 'Scan as many documents as you need',
            ),
            _buildFeatureItem(
              icon: Icons.psychology,
              title: 'AI Document Analysis',
              description: 'Smart categorization and key info extraction',
            ),
            _buildFeatureItem(
              icon: Icons.text_fields,
              title: 'OCR Text Recognition',
              description: 'Extract and search text from documents',
            ),
            _buildFeatureItem(
              icon: Icons.tune,
              title: 'Advanced Filters',
              description: 'B&W, Sharp, and more enhancement options',
            ),
            _buildFeatureItem(
              icon: Icons.palette,
              title: 'Image Adjustments',
              description: 'Fine-tune contrast and saturation',
            ),
            _buildFeatureItem(
              icon: Icons.layers,
              title: 'Batch Operations',
              description: 'Manage multiple documents at once',
            ),
            _buildFeatureItem(
              icon: Icons.no_encryption,
              title: 'No Watermarks',
              description: 'Clean, professional PDFs',
            ),
            _buildFeatureItem(
              icon: Icons.folder,
              title: 'Unlimited Folders',
              description: 'Organize documents your way',
            ),
            _buildFeatureItem(
              icon: Icons.support_agent,
              title: 'Priority Support',
              description: 'Get help when you need it',
            ),

            const SizedBox(height: 32),

            // Pricing Header
            const Text(
              'Choose Your Plan:',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Monthly Plan
            _buildPricingCard(
              title: 'Monthly',
              price: '\$2.99',
              period: '/month',
              description: 'Billed monthly',
              productId: SubscriptionManager.monthlyNoAdsProductId,
              isBestValue: false,
            ),

            const SizedBox(height: 16),

            // Yearly Plan (Best Value)
            _buildPricingCard(
              title: 'Yearly',
              price: '\$19.99',
              period: '/year',
              description: 'Save 44% - Best Value!',
              productId: SubscriptionManager.yearlyNoAdsProductId,
              isBestValue: true,
            ),

            const SizedBox(height: 16),

            // Lifetime Plan
            _buildPricingCard(
              title: 'Lifetime',
              price: '\$39.99',
              period: 'one-time',
              description: 'Pay once, own forever',
              productId: SubscriptionManager.lifetimeNoAdsProductId,
              isBestValue: false,
            ),

            const SizedBox(height: 32),

            // Terms
            const Text(
              'All plans include full access to VaultScan features. '
              'Subscriptions auto-renew unless cancelled 24 hours before renewal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            // Restore Purchases Link
            TextButton(
              onPressed: _isLoading ? null : _restorePurchases,
              child: const Text(
                'Restore Purchases',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(
              icon,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green.shade700,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required String price,
    required String period,
    required String description,
    required String productId,
    required bool isBestValue,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedProductId == productId ? Colors.blue.shade700 : (isBestValue ? Colors.amber.shade700 : Colors.grey.shade300),
          width: _selectedProductId == productId ? 3 : (isBestValue ? 3 : 1.5),
        ),
        borderRadius: BorderRadius.circular(16.0),
        color: isBestValue ? Colors.amber.shade50 : Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : () { setState(() => _selectedProductId = productId); _purchaseAdRemoval(productId); },
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                if (isBestValue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: const Text(
                      'BEST VALUE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                if (isBestValue) const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isBestValue ? Colors.amber.shade900 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isBestValue ? Colors.amber.shade900 : Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            period,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _purchaseAdRemoval(String productId) async {
    setState(() => _isLoading = true);

    try {
      final success = await _subscriptionManager.purchaseAdRemoval(productId);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you! Ads removed successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase was cancelled or failed.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);

    try {
      await _subscriptionManager.restorePurchases();
      
      if (!mounted) return;

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
      
      if (_subscriptionManager.isAdFree) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

