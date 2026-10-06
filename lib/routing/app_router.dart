import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/invoice/presentation/screens/invoice_detail_screen.dart';
import '../features/ride/presentation/screens/ride_request_screen.dart';

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
  ],
);