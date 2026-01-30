import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lottie/lottie.dart';

class SOSScreen extends StatelessWidget {
  const SOSScreen({super.key});

  Future<void> _makeCall(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    await launchUrl(launchUri);
  }

  Future<void> _shareLocation() async {
    // Simulation of sharing location via WhatsApp
    final message =
        "SOS! I need roadside assistance at my current location: https://maps.google.com/?q=current_location";
    final url = "https://wa.me/?text=${Uri.encodeComponent(message)}";
    await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMERGENCY ASSISTANCE'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Lottie.asset(
              'assets/animations/scanning_docs.json', // Placeholder or dedicated SOS animation
              height: 150,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.warning_amber_rounded,
                size: 100,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Emergency roadside help is one tap away',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildSOSButton(
              context,
              'Towing Service',
              'Fast vehicle recovery',
              Icons.local_shipping,
              Colors.orange,
              () => _makeCall('12345678'),
            ),
            const SizedBox(height: 16),
            _buildSOSButton(
              context,
              'Call Police',
              'Report an accident',
              Icons.policy,
              Colors.redAccent,
              () => _makeCall('911'),
            ),
            const SizedBox(height: 16),
            _buildSOSButton(
              context,
              'Technical Support',
              'Advice on car issues',
              Icons.support_agent,
              Colors.blue,
              () => _makeCall('87654321'),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _shareLocation,
              icon: const Icon(Icons.share_location),
              label: const Text('SHARE MY LOCATION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 60),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSOSButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(51)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.call, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
