import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 18),
              UiHelper.customText(
                text: 'QuickChat',
                fontSize: 26,
                fontWeight: FontWeight.bold,
                context: context,
              ),
              const SizedBox(height: 8),
              UiHelper.customText(
                text: 'Loading your conversations...',
                fontSize: 13,
                context: context,
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 22),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
