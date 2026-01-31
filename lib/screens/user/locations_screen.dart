import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class LocationsScreen extends StatelessWidget {
  const LocationsScreen({super.key});

  final List<Map<String, dynamic>> _branches = const [
    {
      'name': 'mainBranch',
      'address': '123 Ashgabat St, Center',
      'lat': 37.96,
      'lng': 58.32,
      'phone': '+993 12 345678',
      'hours': '08:00 - 20:00',
    },
    {
      'name': 'westBranch',
      'address': '45 West Industrial Zone',
      'lat': 37.92,
      'lng': 58.28,
      'phone': '+993 12 876543',
      'hours': '09:00 - 18:00',
    },
  ];

  Future<void> _openInMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ourBranches'.tr())),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _branches.length,
        itemBuilder: (context, index) {
          final branch = _branches[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.location_on, color: Colors.white),
                  ),
                  title: Text(
                    (branch['name'] as String).tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(branch['address']),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                branch['phone'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                branch['hours'],
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _openInMaps(branch['lat'], branch['lng']),
                        icon: const Icon(Icons.directions, size: 18),
                        label: Text('navigate'.tr()),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
