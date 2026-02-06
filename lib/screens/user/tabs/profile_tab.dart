import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/cubits/profile_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:supa/models/profile_model.dart';
import 'package:supa/screens/auth/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supa/screens/user/locations_screen.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          return const AppLoadingIndicator();
        }

        if (state is ProfileLoaded || state is ProfileActionSuccess) {
          final profile = (state is ProfileLoaded)
              ? state.profile
              : (context.read<ProfileCubit>().state as ProfileLoaded).profile;
          return RefreshIndicator(
            onRefresh: () => context.read<ProfileCubit>().fetchProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null && context.mounted) {
                        context.read<ProfileCubit>().updateProfile(
                          displayName: profile.displayName,
                          phoneNumber: profile.phoneNumber,
                          avatar: image,
                          existingAvatarUrl: profile.avatarUrl,
                        );
                      }
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.withAlpha(51),
                      backgroundImage: profile.avatarUrl != null
                          ? CachedNetworkImageProvider(profile.avatarUrl!)
                          : null,
                      child: profile.avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.blue,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.displayName ?? 'New User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    profile.email,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const SizedBox(height: 24),

                  // --- PERSONAL INFO ---
                  _buildSectionHeader(context, 'personalInfo'.tr()),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.badge, color: Colors.blue),
                          title: Text('name'.tr()),
                          subtitle: Text(profile.displayName ?? 'notSet'.tr()),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showEditDialog(
                            context,
                            'name'.tr(),
                            profile.displayName,
                            (val) {
                              context.read<ProfileCubit>().updateProfile(
                                displayName: val,
                                phoneNumber: profile.phoneNumber,
                                existingAvatarUrl: profile.avatarUrl,
                              );
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.phone, color: Colors.blue),
                          title: Text('phone'.tr()),
                          subtitle: Text(profile.phoneNumber ?? 'notSet'.tr()),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showEditDialog(
                            context,
                            'phone'.tr(),
                            profile.phoneNumber,
                            (val) {
                              context.read<ProfileCubit>().updateProfile(
                                displayName: profile.displayName,
                                phoneNumber: val,
                                existingAvatarUrl: profile.avatarUrl,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- SETTINGS ---
                  _buildSectionHeader(context, 'settings'.tr()),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.contact_mail,
                            color: Colors.blue,
                          ),
                          title: Text('preferredContact'.tr()),
                          subtitle: Text(profile.preferredContact),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showContactPicker(context, profile),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          secondary: const Icon(
                            Icons.notifications,
                            color: Colors.blue,
                          ),
                          title: Text('notifications'.tr()),
                          value: profile.notificationsEnabled,
                          onChanged: (val) {
                            context.read<ProfileCubit>().updateProfile(
                              notificationsEnabled: val,
                              displayName: profile.displayName,
                              phoneNumber: profile.phoneNumber,
                              existingAvatarUrl: profile.avatarUrl,
                            );
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.language,
                            color: Colors.blue,
                          ),
                          title: Text('language'.tr()),
                          subtitle: Text(
                            context.locale.languageCode == 'en'
                                ? 'English'
                                : context.locale.languageCode == 'ru'
                                ? 'Русский'
                                : 'Türkmençe',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _showLanguagePicker(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                          ),
                          title: Text('ourBranches'.tr()),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LocationsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- APPEARANCE ---
                  _buildSectionHeader(context, 'appearance'.tr()),
                  _buildAppThemesSection(context),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withAlpha(30),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
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
                      label: Text('logout'.tr()),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
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

        // Fallback or Initial state
        context.read<ProfileCubit>().fetchProfile();
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
      child: ListTile(
        leading: Icon(
          isLightMode ? Icons.light_mode : Icons.dark_mode,
          color: Colors.orange,
        ),
        title: Text('themeSettings'.tr()),
        subtitle: Text(isLightMode ? 'lightMode'.tr() : 'darkMode'.tr()),
        trailing: Switch(
          value: isLightMode,
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

  void _showEditDialog(
    BuildContext context,
    String title,
    String? initialValue,
    Function(String) onSave,
  ) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(dialogContext);
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }
}
