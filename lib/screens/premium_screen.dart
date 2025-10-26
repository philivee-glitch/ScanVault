import 'package:flutter/material.dart';
import '../subscription_manager.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final SubscriptionManager _subscriptionManager = SubscriptionManager();
  String _selectedPlan = 'yearly'; // monthly, yearly, lifetime

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Premium'),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.workspace_premium, size: 80, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Unlock Premium Features',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Get unlimited access to all features',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Features List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium Features:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildFeature('🔓 Unlimited Scans', 'Scan as many documents as you need'),
                  _buildFeature('🤖 AI Document Analysis', 'Smart categorization and key info extraction'),
                  _buildFeature('📝 OCR Text Recognition', 'Extract and search text from documents'),
                  _buildFeature('🎨 Advanced Filters', 'B&W, Sharp, and more enhancement options'),
                  _buildFeature('🎚️ Image Adjustments', 'Fine-tune contrast and saturation'),
                  _buildFeature('📊 Batch Operations', 'Manage multiple documents at once'),
                  _buildFeature('🚫 No Watermarks', 'Clean, professional PDFs'),
                  _buildFeature('📁 Unlimited Folders', 'Organize documents your way'),
                  _buildFeature('🚀 Priority Support', 'Get help when you need it'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Pricing Plans
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const Text(
                    'Choose Your Plan:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Monthly Plan
                  _buildPricingCard(
                    'Monthly',
                    '\$4.99',
                    'per month',
                    'monthly',
                    isPremium: false,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Yearly Plan (Best Value)
                  _buildPricingCard(
                    'Yearly',
                    '\$29.99',
                    'per year',
                    'yearly',
                    isPremium: true,
                    savings: 'Save 50%',
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Lifetime Plan
                  _buildPricingCard(
                    'Lifetime',
                    '\$59.99',
                    'one-time payment',
                    'lifetime',
                    isPremium: false,
                    savings: 'Best Deal',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Subscribe Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Subscribe Now',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Terms
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Payment will be charged to your account. Subscription automatically renews unless cancelled 24 hours before the end of the current period.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    String title,
    String price,
    String period,
    String planId, {
    bool isPremium = false,
    String? savings,
  }) {
    final isSelected = _selectedPlan == planId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = planId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade50 : Colors.white,
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.amber.withOpacity(0.3), blurRadius: 8, spreadRadius: 2)]
              : [],
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.amber,
                        ),
                      ),
                    )
                  : null,
            ),
            
            const SizedBox(width: 16),
            
            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (savings != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            savings,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    period,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            
            // Price
            Text(
              price,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubscribe() async {
    // Activate premium (honor system for now)
    await _subscriptionManager.setPremiumStatus(true);
    
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Flexible(child: Text('Welcome to Premium!')),
            ],
          ),
          content: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You now have access to all premium features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text('✓ Unlimited scans'),
              const Text('✓ AI Document Analysis'),
              const Text('✓ OCR Text Recognition'),
              const Text('✓ Advanced filters & adjustments'),
              const Text('✓ No watermarks'),
              const Text('✓ And much more!'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Note: Payment processing will be available soon. For now, enjoy all premium features!',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
              ),
              child: const Text('Start Using Premium'),
            ),
          ],
        ),
      );
    }
  }
}
