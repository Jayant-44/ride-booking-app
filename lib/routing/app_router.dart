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

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/register-driver',
      builder: (context, state) => const DriverRegisterScreen(),
    ),
    GoRoute(
      path: '/register-admin',
      builder: (context, state) => const AdminRegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/request-ride',
      builder: (context, state) => const RideRequestScreen(),
    ),
    GoRoute(
      path: '/invoice/:id',
      builder: (context, state) => InvoiceDetailScreen(
        invoiceId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/driver/home',
      builder: (context, state) => const DriverHomeScreen(),
    ),
    GoRoute(
      path: '/driver/assignment/:id',
      builder: (context, state) => DriverAssignmentDetailScreen(
        assignmentId: state.pathParameters['id']!,
      ),
    ),
  ],
);