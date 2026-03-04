import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/cubits/profile_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:supa/models/profile_model.dart';
import 'package:supa/screens/auth/login_screen.dart';
import 'package:supa/screens/user/locations_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/components/app_loading_indicator.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('profileUpdated'.tr())));
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          context.read<ProfileCubit>().fetchProfile();
          return const AppLoadingIndicator();
        }

        if (state is ProfileLoaded || state is ProfileActionSuccess) {
          final profile = (state is ProfileLoaded)
              ? state.profile
              : (context.read<ProfileCubit>().state as ProfileLoaded).profile;

          return Scaffold(
            appBar: AppBar(
              title: Text('settings'.tr()),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: RefreshIndicator(
              onRefresh: () => context.read<ProfileCubit>().fetchProfile(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader(context, 'preferences'.tr()),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withAlpha(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.contact_mail,
                                color: Colors.blue,
                                size: 20,
                              ),
                            ),
                            title: Text('preferredContact'.tr()),
                            subtitle: Text(profile.preferredContact),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => _showContactPicker(context, profile),
                          ),
                          Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor.withAlpha(30),
                          ),
                          SwitchListTile(
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.notifications,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                            title: Text('notifications'.tr()),
                            value: profile.notificationsEnabled,
                            activeThumbColor: Colors.blue,
                            onChanged: (val) {
                              context.read<ProfileCubit>().updateProfile(
                                notificationsEnabled: val,
                                displayName: profile.displayName,
                                phoneNumber: profile.phoneNumber,
                                existingAvatarUrl: profile.avatarUrl,
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor.withAlpha(30),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.language,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                            title: Text('language'.tr()),
                            subtitle: Text(
                              context.locale.languageCode == 'en'
                                  ? 'English'
                                  : context.locale.languageCode == 'ru'
                                  ? 'Русский'
                                  : 'Türkmençe',
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => _showLanguagePicker(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'about'.tr()),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withAlpha(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.purple,
                                size: 20,
                              ),
                            ),
                            title: Text('ourBranches'.tr()),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LocationsScreen(),
                                ),
                              );
                            },
                          ),
                          Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor.withAlpha(30),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.support_agent,
                                color: Colors.teal,
                                size: 20,
                              ),
                            ),
                            title: Text('contactUs'.tr()),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => _showContactSupport(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'legal'.tr()),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor.withAlpha(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.privacy_tip,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: Text('privacyPolicy'.tr()),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () =>
                                _showLegalDoc(context, 'privacyPolicy'),
                          ),
                          Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor.withAlpha(30),
                          ),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.description,
                                color: Colors.grey,
                                size: 20,
                              ),
                            ),
                            title: Text('termsOfService'.tr()),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () =>
                                _showLegalDoc(context, 'termsOfService'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionHeader(context, 'appearance'.tr()),
                    _buildAppThemesSection(context),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withAlpha(20),
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.red.withAlpha(50)),
                          ),
                        ),
                        onPressed: () {
                          context.read<AuthCubit>().logout();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout),
                        label: Text(
                          'logout'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is ProfileError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<ProfileCubit>().fetchProfile(),
                  child: Text('retry'.tr()),
                ),
              ],
            ),
          );
        }

        return const AppLoadingIndicator();
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).hintColor,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildAppThemesSection(BuildContext context) {
    final isLightMode = context.watch<ThemeCubit>().state;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(20)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withAlpha(30),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isLightMode ? Icons.light_mode : Icons.dark_mode,
            color: Colors.orange,
            size: 20,
          ),
        ),
        title: Text('themeSettings'.tr()),
        subtitle: Text(isLightMode ? 'lightMode'.tr() : 'darkMode'.tr()),
        trailing: Switch(
          value: isLightMode,
          activeThumbColor: Colors.blue,
          onChanged: (val) => context.read<ThemeCubit>().toggleTheme(),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'language'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('English'),
            trailing: context.locale.languageCode == 'en'
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              context.setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Русский'),
            trailing: context.locale.languageCode == 'ru'
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              context.setLocale(const Locale('ru'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('Türkmençe'),
            trailing: context.locale.languageCode == 'tk'
                ? const Icon(Icons.check, color: Colors.blue)
                : null,
            onTap: () {
              context.setLocale(const Locale('tk'));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showContactPicker(BuildContext context, Profile profile) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'preferredContact'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...['Phone', 'WhatsApp', 'Telegram', 'Email'].map(
            (method) => ListTile(
              title: Text(
                method.toLowerCase().tr() != method.toLowerCase()
                    ? method.toLowerCase().tr()
                    : method,
              ),
              trailing: profile.preferredContact == method
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                context.read<ProfileCubit>().updateProfile(
                  preferredContact: method,
                  displayName: profile.displayName,
                  phoneNumber: profile.phoneNumber,
                  existingAvatarUrl: profile.avatarUrl,
                );
                Navigator.pop(context);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('contactUs'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('supportContent'.tr()),
            const SizedBox(height: 16),
            const Text(
              '+993 61 234567',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              'support@autoservice.com',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showLegalDoc(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                type.tr(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text('${type}Content'.tr()),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
