import 'package:flutter/material.dart';
import 'package:supa/screens/user/tabs/services_tab.dart';
import 'package:supa/screens/user/tabs/garage_tab.dart';
import 'package:supa/screens/user/tabs/history_tab.dart';
import 'package:supa/screens/user/tabs/profile_tab.dart';
import 'package:supa/screens/user/tabs/assistant_tab.dart';
import 'package:supa/screens/user/create_order_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/profile_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const ServicesTab(),
    const AssistantTab(),
    const GarageTab(),
    const HistoryTab(),
    const ProfileTab(),
  ];

  final List<String> _titles = [
    'Our Services',
    'AI Assistant',
    'My Garage',
    'Order History',
    'My Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(_titles[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.add_shopping_cart, color: Colors.blue),
              tooltip: 'Book Service',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateOrderScreen(),
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 4),
              child: BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  String? avatarUrl;
                  if (state is ProfileLoaded)
                    avatarUrl = state.profile.avatarUrl;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.withAlpha(51),
                      backgroundImage: avatarUrl != null
                          ? CachedNetworkImageProvider(avatarUrl)
                          : null,
                      child: avatarUrl == null
                          ? const Icon(Icons.person, size: 18)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
      body: _selectedIndex == 2
          ? GarageTab(
              onNavigateToServices: () => setState(() => _selectedIndex = 0),
            )
          : _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Services'),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_car),
            label: 'Garage',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
