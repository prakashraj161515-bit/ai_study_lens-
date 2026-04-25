import 'package:flutter/material.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Premium')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.star, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Unlock Full Potential',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildFeatureRow('Unlimited Scans'),
            _buildFeatureRow('Advanced AI Explanations'),
            _buildFeatureRow('Full MCQ Generator'),
            _buildFeatureRow('Ad-Free Experience'),
            const SizedBox(height: 32),
            _buildPricingCard('₹99 / month', false),
            const SizedBox(height: 16),
            _buildPricingCard('₹500 / 6 months', false),
            const SizedBox(height: 16),
            _buildPricingCard('₹900 / year', true),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPricingCard(String price, bool isBestValue) {
    return Card(
      elevation: isBestValue ? 4 : 1,
      color: isBestValue ? Colors.blue[50] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isBestValue ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                if (isBestValue)
                  const Text('Best Value', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isBestValue ? Colors.blue : Colors.grey[800],
                foregroundColor: Colors.white,
              ),
              child: const Text('Subscribe'),
            )
          ],
        ),
      ),
    );
  }
}
