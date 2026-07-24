import 'package:chatappui/core/constants/app_themes.dart';
import 'package:chatappui/data/models/user_model.dart';
import 'package:chatappui/data/services/auth_service.dart';
import 'package:chatappui/data/services/user_service.dart';
import 'package:chatappui/presentation/screens/auth/login_screen.dart';
import 'package:chatappui/presentation/screens/profile/profile_setup_screen.dart';
import 'package:chatappui/presentation/screens/settings/settings_screen.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:chatappui/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final userService = UserService();
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: UiHelper.customText(
          text: 'More',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          context: context,
        ),
        actions: [UiHelper.darkModeToggle(context)],
      ),
      body: currentUid == null
          ? const Center(child: Text('No user found'))
          : StreamBuilder<UserModel?>(
              stream: userService.userStream(currentUid),
              builder: (context, snapshot) {
                final user = snapshot.data;
                final themeProvider = context.watch<ThemeProvider>();

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: user == null
                            ? const Center(child: CircularProgressIndicator())
                            : Row(
                                children: [
                                  UiHelper.avatar(
                                    name: user.displayName,
                                    photoUrl: user.photoUrl,
                                    radius: 32,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        UiHelper.customText(
                                          text: user.displayName,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          context: context,
                                        ),
                                        UiHelper.customText(
                                          text: '@${user.username}',
                                          fontSize: 13,
                                          context: context,
                                          color: Colors.grey,
                                        ),
                                        if (user.bio.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          UiHelper.customText(
                                            text: user.bio,
                                            fontSize: 12,
                                            context: context,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ProfileSetupScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: const Text('Edit Profile'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileSetupScreen(),
                                ),
                              );
                            },
                          ),
                          UiHelper.sectionDivider(context),
                          ListTile(
                            leading: const Icon(Icons.settings_outlined),
                            title: const Text('App Settings'),
                            subtitle: Text(
                              '${AppThemes.labelForMode(themeProvider.themeMode)} / '
                              '${themeProvider.themeColor.label} / '
                              '${(themeProvider.fontScale * 100).round()}%',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                          UiHelper.sectionDivider(context),
                          ListTile(
                            leading: const Icon(
                              Icons.logout,
                              color: Colors.red,
                            ),
                            title: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Logout'),
                                  content: const Text(
                                    'Are you sure you want to log out?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text(
                                        'Logout',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true) return;

                              await authService.logout();
                              if (!context.mounted) return;

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (_) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
