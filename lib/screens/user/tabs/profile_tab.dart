import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/cubits/profile_cubit.dart';
import 'package:supa/models/profile_model.dart';
import 'package:supa/screens/auth/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is ProfileActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const AppLoadingIndicator();
        }

        if (state is ProfileLoaded) {
          final profile = state.profile;
          return SingleChildScrollView(
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
                        ? const Icon(Icons.person, size: 60, color: Colors.blue)
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
                Text(profile.email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),

                // --- LOYALTY CARD ---
                _buildLoyaltyCard(profile),
                const SizedBox(height: 24),

                // --- PERSONAL INFO ---
                _buildSectionHeader('Personal Info'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge, color: Colors.blue),
                        title: const Text('Name'),
                        subtitle: Text(profile.displayName ?? 'Not set'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showEditDialog(
                          context,
                          'Name',
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
                        title: const Text('Phone'),
                        subtitle: Text(profile.phoneNumber ?? 'Not set'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showEditDialog(
                          context,
                          'Phone',
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
                _buildSectionHeader('Settings'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.contact_mail,
                          color: Colors.blue,
                        ),
                        title: const Text('Preferred Contact'),
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
                        title: const Text('Notifications'),
                        subtitle: const Text('Get alerts for your orders'),
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
                        leading: const Icon(Icons.language, color: Colors.blue),
                        title: const Text('Language'),
                        subtitle: const Text('English'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Language switcher coming soon!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

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
                    label: const Text('Logout Account'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        }

        return const Center(child: Text('Something went wrong'));
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLoyaltyCard(Profile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF673AB7), Color(0xFF512DA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF673AB7).withAlpha(77),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
              Text(
                'GOLD MEMBER',
                style: TextStyle(
                  color: Colors.white.withAlpha(179),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const Text(
            'LOYALTY POINTS',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            '${profile.loyaltyPoints} PTS',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (profile.loyaltyPoints % 1000) / 1000,
              backgroundColor: Colors.black26,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${1000 - (profile.loyaltyPoints % 1000)} points to next bonus',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showContactPicker(BuildContext context, Profile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Preferred Contact Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...['Phone', 'WhatsApp', 'Telegram', 'Email'].map(
            (method) => ListTile(
              title: Text(method),
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
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: title),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
