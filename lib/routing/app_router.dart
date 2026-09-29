import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../features/auth/presentation/screens/login_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Home — next screen to build')),
      ),
    ),
  ],
);