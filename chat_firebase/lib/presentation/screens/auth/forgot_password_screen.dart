// presentation/screens/auth/forgot_password_screen.dart
// Allows users to request a password reset email.

import 'package:chatappui/data/services/auth_service.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      await _authService.sendPasswordResetEmail(_emailController.text);
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMsg = 'Could not send reset email. '
              'Please check the address and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [UiHelper.darkModeToggle(context)],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiHelper.customText(
              text: 'Reset Password',
              fontSize: 26,
              fontFamily: 'bold',
              fontWeight: FontWeight.bold,
              context: context,
            ),
            const SizedBox(height: 12),
            if (!_emailSent) ...[
              UiHelper.customText(
                text: 'Enter your registered email address and '
                    'we ll send you a reset link.',
                fontSize: 14,
                context: context,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              UiHelper.customTextField(
                controller: _emailController,
                hintText: 'Email',
                prefixIcon: Icons.email_outlined,
                context: context,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMsg!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 28),
              UiHelper.customButton(
                label: 'Send Reset Link',
                onPressed: _sendReset,
                isLoading: _isLoading,
              ),
            ] else ...[
              // ── Success state ────────────────────────────────────────────
              const Icon(
                Icons.mark_email_read_outlined,
                size: 72,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              UiHelper.customText(
                text: 'Reset email sent! Check your inbox and follow '
                    'the link to reset your password.',
                fontSize: 15,
                context: context,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              UiHelper.customButton(
                label: 'Back to Login',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
