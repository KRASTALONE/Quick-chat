// presentation/screens/onboarding/onboarding_screen.dart
// First screen the user sees when they open the app fresh.
// Has dark mode toggle in AppBar.

import 'package:chatappui/presentation/screens/auth/login_screen.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:flutter/material.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [UiHelper.darkModeToggle(context)]),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiHelper.assetImage('onboarding.png'),
            const SizedBox(height: 28),
            UiHelper.customText(
              text: 'Connect easily with',
              fontSize: 26,
              fontFamily: 'bold',
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              context: context,
            ),
            UiHelper.customText(
              text: 'your family and friends',
              fontSize: 26,
              fontFamily: 'bold',
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              context: context,
            ),
            UiHelper.customText(
              text: 'over countries.',
              fontSize: 26,
              fontFamily: 'bold',
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              context: context,
            ),
          ],
        ),
      ),
      floatingActionButton: UiHelper.customButton(
        label: 'Start Messaging',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
