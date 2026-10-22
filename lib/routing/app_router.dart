import 'package:go_router/go_router.dart';

import '../core/navigation/nav_key.dart';
import '../features/auth/data/auth_service.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/driver_register_screen.dart';
import '../features/auth/presentation/screens/admin_register_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/invoice/presentation/screens/invoice_detail_screen.dart';
import '../features/ride/presentation/screens/ride_request_screen.dart';
import '../features/driver/presentation/screens/driver_home_screen.dart';
import '../features/driver/presentation/screens/driver_assignment_detail_screen.dart';
import '../features/admin/presentation/screens/admin_home_screen.dart';
import '../features/admin/presentation/screens/admin_rides_screen.dart';
import '../features/admin/presentation/screens/admin_users_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/settings_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/support/presentation/screens/support_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  
  // Redirect logic to keep users logged in
  redirect: (context, state) async {
    // Check if the user has a token securely saved
    final isLoggedIn = await AuthService().isLoggedIn();

    final isAuthRoute = state.matchedLocation == '/login' ||
                        state.matchedLocation == '/splash' ||
                        state.matchedLocation == '/register' ||
                        state.matchedLocation == '/register-driver' ||
                        state.matchedLocation == '/register-admin';

    // 1. If NOT logged in, and trying to access protected pages -> force to login
    if (!isLoggedIn) {
      return isAuthRoute ? null : '/login';
    }

    // 2. If ALREADY logged in, and trying to access login/splash -> force to their home
    if (isAuthRoute) {
      final user = await AuthService().getStoredUser();
      if (user != null) {
        switch (user.role) {
          case 'DRIVER': return '/driver/home';
          case 'ADMIN': return '/admin/home';
          default: return '/home';
        }
      }
    }

    return null; // No redirect needed, allow navigation
  },

  routes: [
    GoRoute(
      path: '/splash',
      builder: (c, s) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (c, s) => const LoginScreen(),
    ),
    GoRoute(
      path: '/forgot-password', 
      builder: (c, s) => const ForgotPasswordScreen()
    ),
    GoRoute(
      path: '/register',
      builder: (c, s) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/register-driver',
      builder: (c, s) => const DriverRegisterScreen(),
    ),
    GoRoute(
      path: '/register-admin',
      builder: (c, s) => const AdminRegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (c, s) => const HomeScreen(),
    ),
    GoRoute(
      path: '/request-ride',
      builder: (c, s) => const RideRequestScreen(),
    ),
    GoRoute(
      path: '/invoice/:id',
      builder: (c, s) => InvoiceDetailScreen(
        invoiceId: s.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/driver/home',
      builder: (c, s) => const DriverHomeScreen(),
    ),
    GoRoute(
      path: '/driver/assignment/:id',
      builder: (c, s) => DriverAssignmentDetailScreen(
        assignmentId: s.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/admin/home',
      builder: (c, s) => const AdminHomeScreen(),
    ),
    GoRoute(
      path: '/admin/rides',
      builder: (c, s) => const AdminRidesScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (c, s) => const AdminUsersScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (c, s) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (c, s) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (c, s) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/history',
      builder: (c, s) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (c, s) => const SupportScreen(),
    ),
  ],
);