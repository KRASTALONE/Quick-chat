import 'package:chatappui/data/services/auth_service.dart';
import 'package:chatappui/presentation/screens/profile/profile_setup_screen.dart';
import 'package:chatappui/presentation/widgets/ui_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureCon = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final username = _usernameController.text.trim();
    final pass = _passwordController.text;
    final confirm = _confirmController.text;

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _errorMsg = 'Enter valid email');
      return false;
    }

    if (username.length < 3) {
      setState(() => _errorMsg = 'Username must be 3+ chars');
      return false;
    }

    if (pass.length < 6) {
      setState(() => _errorMsg = 'Password must be 6+ chars');
      return false;
    }

    if (pass != confirm) {
      setState(() => _errorMsg = 'Passwords do not match');
      return false;
    }

    return true;
  }

  Future<void> _register() async {
    setState(() => _errorMsg = null);

    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
        username: _usernameController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
    } catch (e) {
      debugPrint("REGISTER ERROR: $e"); // 🔥 important

      setState(() {
        _errorMsg = _handleError(e.toString());
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _handleError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Email already exists';
    }

    if (error.contains('weak-password')) {
      return 'Password too weak';
    }

    if (error.contains('invalid-email')) {
      return 'Invalid email';
    }

    if (error.contains('permission-denied')) {
      return 'Firestore permission denied';
    }

    if (error.contains('Username already taken')) {
      return 'Username already taken';
    }

    return error; // 🔥 show real error
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 30),
            UiHelper.customText(
              text: 'Create Account',
              fontSize: 26,
              fontWeight: FontWeight.bold,
              context: context,
            ),
            const SizedBox(height: 8),
            UiHelper.customText(
              text: 'Sign up with email & username',
              fontSize: 14,
              context: context,
            ),
            const SizedBox(height: 30),
            UiHelper.customTextField(
              controller: _emailController,
              hintText: 'Email',
              prefixIcon: Icons.email_outlined,
              context: context,
            ),
            const SizedBox(height: 12),
            UiHelper.customTextField(
              controller: _usernameController,
              hintText: 'Username',
              prefixIcon: Icons.alternate_email,
              context: context,
            ),
            const SizedBox(height: 12),
            UiHelper.customTextField(
              controller: _passwordController,
              hintText: 'Password',
              prefixIcon: Icons.lock_outline,
              context: context,
              obscureText: _obscurePass,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
            const SizedBox(height: 12),
            UiHelper.customTextField(
              controller: _confirmController,
              hintText: 'Confirm Password',
              prefixIcon: Icons.lock_outline,
              context: context,
              obscureText: _obscureCon,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureCon ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscureCon = !_obscureCon),
              ),
            ),
            if (_errorMsg != null) ...[
              const SizedBox(height: 10),
              Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            UiHelper.customButton(
              label: 'Sign Up',
              onPressed: _register,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have account? "),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
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
