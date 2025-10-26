import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VaultScan Premium - Terms of Service',
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
              'Agreement to Terms',
              'By downloading, installing, or using VaultScan Premium ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.',
            ),

            _buildSection(
              'License',
              'We grant you a limited, non-exclusive, non-transferable, revocable license to use the App for personal, non-commercial purposes in accordance with these Terms.',
            ),

            _buildSection(
              'Free Tier Features',
              'The free version of VaultScan includes:\n\n'
              '• 5 scans per day\n'
              '• Basic PDF export\n'
              '• Auto edge detection\n'
              '• Basic filters\n'
              '• Watermark on exports\n\n'
              'Free tier does not include OCR, cloud sync, or batch processing features.',
            ),

            _buildSection(
              'Premium Subscription',
              'Premium subscriptions provide:\n\n'
              '• Unlimited daily scans\n'
              '• No watermarks on PDFs\n'
              '• All premium features\n'
              '• Priority support\n\n'
              'Subscriptions are available as monthly or yearly plans.',
            ),

            _buildSection(
              'Billing and Payments',
              'Subscriptions are billed through your Google Play account. Payment will be charged to your Google Play account at confirmation of purchase. Subscriptions automatically renew unless auto-renew is turned off at least 24 hours before the end of the current period.',
            ),

            _buildSection(
              'Cancellation and Refunds',
              'You may cancel your subscription at any time through your Google Play account settings. Cancellation will take effect at the end of the current billing period. Refunds are handled according to Google Play Store policies.',
            ),

            _buildSection(
              'User Content',
              'You retain all rights to documents you scan using the App. We do not claim ownership of your scanned documents. You are responsible for ensuring you have the right to scan and store any documents.',
            ),

            _buildSection(
              'Prohibited Uses',
              'You agree not to:\n\n'
              '• Use the App for any illegal purpose\n'
              '• Scan documents you do not have permission to scan\n'
              '• Attempt to reverse engineer or modify the App\n'
              '• Share your premium account with others\n'
              '• Use the App to violate any third-party rights',
            ),

            _buildSection(
              'Disclaimer of Warranties',
              'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR COMPLETELY SECURE.',
            ),

            _buildSection(
              'Limitation of Liability',
              'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING FROM YOUR USE OF THE APP.',
            ),

            _buildSection(
              'Data Loss',
              'While we strive to protect your data, we are not responsible for any loss of documents or data. We recommend regularly backing up important documents.',
            ),

            _buildSection(
              'Changes to Terms',
              'We reserve the right to modify these Terms at any time. Changes will be effective immediately upon posting in the App. Your continued use of the App after changes constitutes acceptance of the new Terms.',
            ),

            _buildSection(
              'Termination',
              'We may terminate or suspend your access to the App at any time, without prior notice or liability, for any reason, including breach of these Terms.',
            ),

            _buildSection(
              'Governing Law',
              'These Terms shall be governed by and construed in accordance with the laws of Australia, without regard to its conflict of law provisions.',
            ),

            _buildSection(
              'Contact Information',
              'For questions about these Terms, please contact us at:\n\n'
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