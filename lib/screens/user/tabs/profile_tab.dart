import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supa/cubits/profile_cubit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supa/components/app_loading_indicator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/utils/input_formatters.dart';

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
          if (state is! ProfileLoaded) {
            return const AppLoadingIndicator();
          }
          final profile = state.profile;
          return RefreshIndicator(
            onRefresh: () => context.read<ProfileCubit>().fetchProfile(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                  const SizedBox(height: 100),
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
          keyboardType: title == 'phone'.tr() ? TextInputType.phone : null,
          inputFormatters: title == 'phone'.tr()
              ? [PhoneNumberFormatter()]
              : null,
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
