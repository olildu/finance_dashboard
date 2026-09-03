import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:finance_dashboard/core/theme/colors.dart';
import 'package:finance_dashboard/core/theme/spacing.dart';
import 'package:finance_dashboard/features/auth/business/auth_provider.dart';

class LoginRegisterPage extends StatefulWidget {
  const LoginRegisterPage({super.key});

  @override
  State<LoginRegisterPage> createState() => _LoginRegisterPageState();
}

class _LoginRegisterPageState extends State<LoginRegisterPage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isLoading = false;
  bool _isRegisterMode = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validate login inputs
  String? _validateLoginInputs() {
    if (_usernameController.text.isEmpty) {
      return 'Username is required';
    }
    if (_passwordController.text.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  /// Validate register inputs
  String? _validateRegisterInputs() {
    if (_usernameController.text.isEmpty) {
      return 'Username is required';
    }
    if (_emailController.text.isEmpty) {
      return 'Email is required';
    }
    if (!_isValidEmail(_emailController.text)) {
      return 'Invalid email format';
    }
    if (_passwordController.text.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  /// Check if email format is valid
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Handle login button press
  Future<void> _handleLogin() async {
    final error = _validateLoginInputs();
    if (error != null) {
      _showErrorDialog(error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.login(
        _usernameController.text,
        _passwordController.text,
      );

      // Clear fields on successful login
      if (mounted) {
        _usernameController.clear();
        _passwordController.clear();
        _emailController.clear();
        context.go('/');
      }
    } catch (e) {
      // Error is handled by the provider and displayed via the error widget
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handle register button press
  Future<void> _handleRegister() async {
    final error = _validateRegisterInputs();
    if (error != null) {
      _showErrorDialog(error);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.register(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );

      // Clear fields on successful register
      if (mounted) {
        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
        context.go('/');
      }
    } catch (e) {
      // Error is handled by the provider and displayed via the error widget
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Toggle between login and register mode
  void _toggleMode() {
    setState(() {
      _isRegisterMode = !_isRegisterMode;
      _usernameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegisterMode ? 'Register' : 'Login'),
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Title
              Text(
                _isRegisterMode ? 'Create Account' : 'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Error message
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.currentError != null) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.1),
                        border: Border.all(color: errorColor),
                        borderRadius: BorderRadius.circular(radiusInput),
                      ),
                      child: Text(
                        authProvider.currentError!,
                        style: TextStyle(color: errorColor),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Username field
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radiusInput),
                  ),
                  filled: true,
                  fillColor: secondaryColor,
                  labelStyle: TextStyle(color: mutedTextColor),
                ),
                style: const TextStyle(color: Colors.white),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              // Email field (only for register mode)
              if (_isRegisterMode) ...[
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(radiusInput),
                    ),
                    filled: true,
                    fillColor: secondaryColor,
                    labelStyle: TextStyle(color: mutedTextColor),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
              ],
              // Password field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radiusInput),
                  ),
                  filled: true,
                  fillColor: secondaryColor,
                  labelStyle: TextStyle(color: mutedTextColor),
                ),
                style: const TextStyle(color: Colors.white),
                enabled: !_isLoading,
              ),
              const SizedBox(height: 32),
              // Login/Register button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_isRegisterMode ? _handleRegister : _handleLogin),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: primaryColor,
                  disabledBackgroundColor: primaryColor.withOpacity(0.5),
                  foregroundColor: highlightColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusCard)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isRegisterMode ? 'Register' : 'Login',
                        style: TextStyle(
                          color: highlightColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              // Toggle mode button
              TextButton(
                onPressed: _isLoading ? null : _toggleMode,
                child: Text(
                  _isRegisterMode
                      ? 'Already have an account? Login'
                      : 'Don\'t have an account? Register',
                  style: TextStyle(
                    color: highlightColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
