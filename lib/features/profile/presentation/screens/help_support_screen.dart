import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How can we help you?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ).animate().fadeIn(),
            const SizedBox(height: 24),
            _buildSupportItem(
              context,
              'Frequently Asked Questions',
              Icons.question_answer_outlined,
              () {},
            ),
            _buildSupportItem(
              context,
              'Contact Support',
              Icons.email_outlined,
              () {},
            ),
            _buildSupportItem(
              context,
              'Terms of Service',
              Icons.description_outlined,
              () {},
            ),
            _buildSupportItem(
              context,
              'Privacy Policy',
              Icons.privacy_tip_outlined,
              () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title details coming soon')),
            );
        },
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }
}
