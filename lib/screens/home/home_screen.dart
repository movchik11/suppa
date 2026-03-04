import 'package:flutter/material.dart';
import 'package:supa/screens/user/tabs/services_tab.dart';
import 'package:supa/screens/user/tabs/garage_tab.dart';
import 'package:supa/cubits/service_cubit.dart';
import 'package:supa/utils/service_search_delegate.dart';
import 'package:supa/screens/user/tabs/history_tab.dart';
import 'package:supa/screens/user/tabs/profile_tab.dart';
import 'package:supa/screens/user/tabs/assistant_tab.dart';
import 'package:supa/screens/auth/login_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/profile_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supa/components/glass_container.dart';
import 'package:supa/screens/user/tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderCubit>().subscribeToOrders();
    });
  }

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
      'settings'.tr(),
    ];

    return BlocListener<AuthCubit, AuthCubitState>(
      listener: (context, state) {
        if (state is AuthInitial || state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          centerTitle: true,
          title: Text(titles[_selectedIndex]),
          actions: [
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
                    child: Text('sortPriceAsc'.tr()),
                  ),
                  PopupMenuItem(
                    value: 'price_desc',
                    child: Text('sortPriceDesc'.tr()),
                  ),
                  PopupMenuItem(
                    value: 'duration_asc',
                    child: Text('sortDurationAsc'.tr()),
                  ),
                  PopupMenuItem(
                    value: 'duration_desc',
                    child: Text('sortDurationDesc'.tr()),
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
              const SizedBox(width: 8),
            ],
            if (_selectedIndex == 4) ...[
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'settings'.tr(),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsTab(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        drawer: Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: ListView(
            padding: EdgeInsets.zero,
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
                leading: const Icon(
                  Icons.home_repair_service,
                  color: Colors.blue,
                ),
                title: Text('services'.tr()),
                onTap: () {
                  setState(() => _selectedIndex = 0);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.smart_toy, color: Colors.purple),
                title: Text('assistant'.tr()),
                onTap: () {
                  setState(() => _selectedIndex = 1);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.garage, color: Colors.orange),
                title: Text('garage'.tr()),
                onTap: () {
                  setState(() => _selectedIndex = 2);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.green),
                title: Text('history'.tr()),
                onTap: () {
                  setState(() => _selectedIndex = 3);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.teal),
                title: Text('profile'.tr()),
                onTap: () {
                  setState(() => _selectedIndex = 4);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.blueGrey),
                title: Text('settings'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsTab(),
                    ),
                  );
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
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GlassContainer(
              borderRadius: BorderRadius.circular(24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BottomNavigationBar(
                  currentIndex: _selectedIndex,
                  onTap: (index) => setState(() => _selectedIndex = index),
                  type: BottomNavigationBarType.fixed,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  selectedItemColor: Colors.blue,
                  unselectedItemColor: Theme.of(context).hintColor,
                  showUnselectedLabels: true,
                  selectedFontSize: 10,
                  unselectedFontSize: 10,
                  iconSize: 22,
                  items: [
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Icon(Icons.home_repair_service),
                      ),
                      label: 'services'.tr(),
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Icon(Icons.smart_toy),
                      ),
                      label: 'assistant'.tr(),
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Icon(Icons.garage),
                      ),
                      label: 'garage'.tr(),
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Icon(Icons.history),
                      ),
                      label: 'history'.tr(),
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 2),
                        child: Icon(Icons.person),
                      ),
                      label: 'profile'.tr(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
