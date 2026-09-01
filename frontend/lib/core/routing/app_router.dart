import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:finance_dashboard/features/auth/presentation/login_register_page.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text('Dashboard (TODO)'),
        ),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginRegisterPage(),
    ),
  ],
);
