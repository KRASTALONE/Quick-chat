import 'package:chatappui/core/constants/app_themes.dart';
import 'package:chatappui/presentation/screens/settings/blocked_users_screen.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:chatappui/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: UiHelper.customText(
          text: 'Settings',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          context: context,
        ),
        actions: [UiHelper.darkModeToggle(context)],
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiHelper.customText(
                        text: 'Appearance Mode',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        context: context,
                      ),
                      const SizedBox(height: 10),
                      ...AppThemeOption.values.map((themeMode) {
                        final isSelected = themeProvider.themeMode == themeMode;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => themeProvider.setThemeMode(themeMode),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.10)
                                    : Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppThemes.labelForMode(themeMode),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiHelper.customText(
                        text: 'Theme Color',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        context: context,
                      ),
                      const SizedBox(height: 6),
                      UiHelper.customText(
                        text:
                            'Selected color: ${themeProvider.themeColor.label}',
                        fontSize: 13,
                        context: context,
                        color:
                            Theme.of(context).colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: ThemeColorOption.values.map((colorOption) {
                          final isSelected =
                              themeProvider.themeColor == colorOption;

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () =>
                                themeProvider.setThemeColor(colorOption),
                            child: Container(
                              width: 78,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.35),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: colorOption.seedColor,
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    colorOption.label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UiHelper.customText(
                        text: 'Font Size',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        context: context,
                      ),
                      const SizedBox(height: 8),
                      UiHelper.customText(
                        text:
                            'Current scale: ${(themeProvider.fontScale * 100).round()}%',
                        fontSize: 13,
                        context: context,
                        color:
                            Theme.of(context).colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                      ),
                      Slider(
                        value: themeProvider.fontScale,
                        min: 0.85,
                        max: 1.40,
                        divisions: 11,
                        label: '${(themeProvider.fontScale * 100).round()}%',
                        onChanged: themeProvider.setFontScale,
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text('Small'), Text('Large')],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.block_outlined),
                      title: const Text('Blocked Users'),
                      subtitle: const Text('Manage who cannot message you'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BlockedUsersScreen(),
                          ),
                        );
                      },
                    ),
                    UiHelper.sectionDivider(context),
                    ListTile(
                      leading: const Icon(Icons.visibility_outlined),
                      title: const Text('Preview'),
                      subtitle: const Text(
                        'Theme and font changes are saved automatically',
                      ),
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
