import 'package:go_router/go_router.dart';

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

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    // Auth
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
    GoRoute(
        path: '/register-driver',
        builder: (c, s) => const DriverRegisterScreen()),
    GoRoute(
        path: '/register-admin',
        builder: (c, s) => const AdminRegisterScreen()),

    // Customer
    GoRoute(path: '/home', builder: (c, s) => const HomeScreen()),
    GoRoute(
        path: '/request-ride',
        builder: (c, s) => const RideRequestScreen()),
    GoRoute(
      path: '/invoice/:id',
      builder: (c, s) => InvoiceDetailScreen(
        invoiceId: s.pathParameters['id']!,
      ),
    ),

    // Driver
    GoRoute(
        path: '/driver/home',
        builder: (c, s) => const DriverHomeScreen()),
    GoRoute(
      path: '/driver/assignment/:id',
      builder: (c, s) => DriverAssignmentDetailScreen(
        assignmentId: s.pathParameters['id']!,
      ),
    ),

    // Admin
    GoRoute(
        path: '/admin/home',
        builder: (c, s) => const AdminHomeScreen()),
    GoRoute(
        path: '/admin/rides',
        builder: (c, s) => const AdminRidesScreen()),
    GoRoute(
        path: '/admin/users',
        builder: (c, s) => const AdminUsersScreen()),

    // Shared (all roles)
    GoRoute(
        path: '/profile',
        builder: (c, s) => const ProfileScreen()),
    GoRoute(
        path: '/settings',
        builder: (c, s) => const SettingsScreen()),
    GoRoute(
        path: '/history',
        builder: (c, s) => const HistoryScreen()),
    GoRoute(
        path: '/support',
        builder: (c, s) => const SupportScreen()),
  ],
);