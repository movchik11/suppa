import 'package:flutter/material.dart';
import 'package:supa/models/service_model.dart';
import 'package:supa/screens/user/create_order_screen.dart';

class ServiceSearchDelegate extends SearchDelegate<Service?> {
  final List<Service> services;

  ServiceSearchDelegate(this.services);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context, query);
  }

  Widget _buildList(BuildContext context, String query) {
    final results = services
        .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return Center(
        child: Text(
          'No services found',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      );
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final service = results[index];
        return ListTile(
          title: Text(service.name),
          subtitle: Text('${service.price.toStringAsFixed(2)} TMT'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            close(context, service);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CreateOrderScreen(preSelectedService: service),
              ),
            );
          },
        );
      },
    );
  }
}
