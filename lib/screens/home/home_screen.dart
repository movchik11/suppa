import 'package:flutter/material.dart';
import 'package:supa/screens/user/tabs/services_tab.dart';
import 'package:supa/screens/user/tabs/garage_tab.dart';
import 'package:supa/cubits/service_cubit.dart';
import 'package:supa/utils/service_search_delegate.dart';
import 'package:supa/screens/user/tabs/history_tab.dart';
import 'package:supa/screens/user/tabs/profile_tab.dart';
import 'package:supa/screens/user/tabs/assistant_tab.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/profile_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
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
          PopupMenuButton<Locale>(
            icon: const Icon(Icons.language),
            onSelected: (locale) {
              context.setLocale(locale);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: Locale('en'), child: Text('English')),
              const PopupMenuItem(value: Locale('ru'), child: Text('Русский')),
              const PopupMenuItem(
                value: Locale('tk'),
                child: Text('Türkmençe'),
              ),
            ],
          ),
          if (_selectedIndex == 0) ...[
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                final state = context.read<ServiceCubit>().state;
                if (state is ServicesLoaded) {
                  showSearch(
                    context: context,
                    delegate: ServiceSearchDelegate(state.services),
                  );
                }
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (val) =>
                  context.read<ServiceCubit>().sortServices(val),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'price_asc',
                  child: Text('Price: Low to High'),
                ),
                PopupMenuItem(
                  value: 'price_desc',
                  child: Text('Price: High to Low'),
                ),
                PopupMenuItem(
                  value: 'duration_asc',
                  child: Text('Duration: Short to Long'),
                ),
                PopupMenuItem(
                  value: 'duration_desc',
                  child: Text('Duration: Long to Short'),
                ),
              ],
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                context.watch<ThemeCubit>().state
                    ? Icons.dark_mode
                    : Icons.light_mode,
                color: Colors.orange,
              ),
              tooltip: 'Toggle Theme',
              onPressed: () => context.read<ThemeCubit>().toggleTheme(),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 4),
              child: BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  String? avatarUrl;
                  if (state is ProfileLoaded) {
                    avatarUrl = state.profile.avatarUrl;
                  }
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
        selectedItemColor: Colors.blue,
        unselectedItemColor: Theme.of(context).hintColor,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_repair_service),
            label: 'services'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.smart_toy),
            label: 'assistant'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.garage),
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
