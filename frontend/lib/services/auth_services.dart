import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_dashboard/services/http_services.dart';

class AuthServices {
  final HttpServices _http = HttpServices();

  Future<void> login({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController usernameController,
    required TextEditingController passwordController,
    required void Function(bool) setLoading,
  }) async {
    if (!formKey.currentState!.validate()) return;
    setLoading(true);

    final result = await _http.login(usernameController.text, passwordController.text);

    final message = result['message'].toString();
    final success = result['success'] == true;

    log('Login result: $message');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? message : message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) context.go('/');

    setLoading(false);
  }

  Future<void> register({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required TextEditingController usernameController,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required void Function(bool) setLoading,
    required void Function(bool) setIsLogin,
  }) async {
    if (!formKey.currentState!.validate()) return;
    setLoading(true);

    final result = await _http.register(
      usernameController.text,
      emailController.text,
      passwordController.text,
    );

    final message = result['message'].toString();
    final success = result['success'] == true;

    log('Registration result: $message');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? message : message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );

    if (success) setIsLogin(true);

    setLoading(false);
  }
}
