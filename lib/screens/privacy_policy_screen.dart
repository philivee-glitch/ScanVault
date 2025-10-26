import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VaultScan Premium - Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: ${DateTime.now().year}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            _buildSection(
              'Information We Collect',
              'VaultScan Premium collects and stores documents that you scan using the app. All documents are stored locally on your device and are not transmitted to our servers unless you explicitly choose to use cloud backup features (Premium feature).',
            ),

            _buildSection(
              'How We Use Your Information',
              'We use the information to:\n\n'
              '• Provide document scanning and management services\n'
              '• Process in-app purchases and subscriptions\n'
              '• Improve app functionality and user experience\n'
              '• Provide customer support',
            ),

            _buildSection(
              'Data Storage',
              'All scanned documents are stored locally on your device in the app\'s private storage directory. We do not have access to your documents unless you explicitly share them with us for support purposes.',
            ),

            _buildSection(
              'In-App Purchases',
              'Payment information for in-app purchases is processed securely through Google Play Store. We do not store or have access to your payment card details. Google Play handles all payment processing.',
            ),

            _buildSection(
              'Camera Permission',
              'VaultScan requires camera access to scan documents. The camera is only used when you actively choose to scan a document. We do not access your camera at any other time.',
            ),

            _buildSection(
              'Data Security',
              'We implement appropriate security measures to protect your information. However, no method of electronic storage is 100% secure, and we cannot guarantee absolute security.',
            ),

            _buildSection(
              'Third-Party Services',
              'Our app uses the following third-party services:\n\n'
              '• Google Play Services (for in-app purchases)\n'
              '• Google Play Billing (for subscription management)\n\n'
              'These services have their own privacy policies governing their use of information.',
            ),

            _buildSection(
              'Children\'s Privacy',
              'Our app is not directed to children under 13. We do not knowingly collect personal information from children under 13.',
            ),

            _buildSection(
              'Your Rights',
              'You have the right to:\n\n'
              '• Access your data (all stored locally on your device)\n'
              '• Delete your data (by uninstalling the app or using the clear cache feature)\n'
              '• Cancel your subscription at any time through Google Play Store',
            ),

            _buildSection(
              'Changes to This Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new privacy policy in the app.',
            ),

            _buildSection(
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us at:\n\n'
              'Email: info@codenestle.com.au',
            ),

            const SizedBox(height: 32),
            
            Center(
              child: Text(
                '© ${DateTime.now().year} VaultScan. All rights reserved.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}