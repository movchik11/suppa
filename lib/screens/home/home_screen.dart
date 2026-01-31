import 'package:flutter/material.dart';
import 'package:supa/screens/user/tabs/services_tab.dart';
import 'package:supa/screens/user/tabs/garage_tab.dart';
import 'package:supa/screens/user/tabs/history_tab.dart';
import 'package:supa/screens/user/tabs/profile_tab.dart';
import 'package:supa/screens/user/tabs/assistant_tab.dart';
import 'package:supa/screens/user/create_order_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/profile_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/cubits/auth_cubit.dart';
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

  @override
  Widget build(BuildContext context) {
    final List<String> titles = [
      'services'.tr(),
      'assistant'.tr(),
      'garage'.tr(),
      'history'.tr(),
      'profile'.tr(),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(titles[_selectedIndex]),
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
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withAlpha(204),
              ),
              child: BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  String name = 'New User';
                  String email = '';
                  String? avatarUrl;
                  if (state is ProfileLoaded) {
                    name = state.profile.displayName ?? 'New User';
                    email = state.profile.email;
                    avatarUrl = state.profile.avatarUrl;
                  }
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        backgroundImage: avatarUrl != null
                            ? CachedNetworkImageProvider(avatarUrl)
                            : null,
                        child: avatarUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 30,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.room_service),
              title: Text('services'.tr()),
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: Text('assistant'.tr()),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_car),
              title: Text('garage'.tr()),
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text('history'.tr()),
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('profile'.tr()),
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                'logout'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                context.read<AuthCubit>().logout();
              },
            ),
          ],
        ),
      ),
      body: _selectedIndex == 2
          ? GarageTab(
              onNavigateToServices: () => setState(() => _selectedIndex = 0),
            )
          : _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).hintColor,
        backgroundColor: Theme.of(context).cardColor,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.room_service),
            label: 'services'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.smart_toy),
            label: 'assistant'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.directions_car),
            label: 'garage'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: 'history'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: 'profile'.tr(),
          ),
        ],
      ),
    );
  }
}
