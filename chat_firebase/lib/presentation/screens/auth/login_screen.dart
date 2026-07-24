// presentation/screens/auth/login_screen.dart
// Replaces the old phone-number + OTP flow.
// User can log in with either their EMAIL or USERNAME plus a PASSWORD.
// Dark mode toggle is available in the AppBar.

import 'package:chatappui/data/services/auth_service.dart';
import 'package:chatappui/presentation/screens/auth/register_screen.dart';
import 'package:chatappui/presentation/screens/auth/forgot_password_screen.dart';
import 'package:chatappui/presentation/screens/home/bottom_nav_screen.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(); // email OR username
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePass = true;
  String? _errorMsg;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      await _authService.loginWithEmailOrUsername(
        emailOrUsername: _identifierController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const BottomNavScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMsg = _friendlyError(e.toString());
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('user-not-found') || raw.contains('No account'))
      return 'No account found. Please check your email / username.';
    if (raw.contains('wrong-password') || raw.contains('invalid-credential'))
      return 'Incorrect password. Please try again.';
    if (raw.contains('too-many-requests'))
      return 'Too many attempts. Please try again later.';
    return 'Login failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [UiHelper.darkModeToggle(context)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // ── Title ───────────────────────────────────────────────────────
            UiHelper.customText(
              text: 'Welcome Back',
              fontSize: 26,
              fontFamily: 'bold',
              fontWeight: FontWeight.bold,
              context: context,
            ),
            const SizedBox(height: 8),
            UiHelper.customText(
              text: 'Sign in with your email or username',
              fontSize: 14,
              context: context,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),

            // ── Email / Username field ───────────────────────────────────────
            UiHelper.customTextField(
              controller: _identifierController,
              hintText: 'Email or Username',
              prefixIcon: Icons.person_outline,
              context: context,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),

            // ── Password field ───────────────────────────────────────────────
            UiHelper.customTextField(
              controller: _passwordController,
              hintText: 'Password',
              prefixIcon: Icons.lock_outline,
              context: context,
              obscureText: _obscurePass,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),

            // ── Forgot password ──────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordScreen(),
                  ),
                ),
                child: UiHelper.customText(
                  text: 'Forgot Password?',
                  fontSize: 13,
                  context: context,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // ── Error message ────────────────────────────────────────────────
            if (_errorMsg != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMsg!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 24),

            // ── Login button ─────────────────────────────────────────────────
            UiHelper.customButton(
              label: 'Login',
              onPressed: _login,
              isLoading: _isLoading,
            ),

            const SizedBox(height: 28),

            // ── Register link ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                UiHelper.customText(
                  text: "Don't have an account? ",
                  fontSize: 14,
                  context: context,
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: UiHelper.customText(
                    text: 'Sign Up',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    context: context,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
