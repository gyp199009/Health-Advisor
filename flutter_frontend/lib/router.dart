import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/chat/chat_detail_screen.dart';
import 'screens/records/records_list_screen.dart';
import 'screens/records/record_detail_screen.dart';
import 'screens/settings/settings_screen.dart'; // Import the SettingsScreen
import 'widgets/main_layout.dart'; // Import the MainLayout
// import 'screens/common/not_found_screen.dart';

// Placeholder screen for routes not yet implemented
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title Screen - Placeholder')),
    );
  }
}

class AppRouter {
  final AuthProvider authProvider;

  AppRouter({required this.authProvider});

  late final GoRouter router = GoRouter(
    refreshListenable: authProvider, // Re-evaluate routes when auth state changes
    initialLocation: '/login', // Start at login page
    debugLogDiagnostics: true, // Enable logging for debugging
    redirect: (context, state) {
      final loggedIn = authProvider.isLoggedIn;
      final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

      // If the user is not logged in and not trying to log in or register, redirect to login
      if (!loggedIn && !loggingIn) {
        return '/login';
      }

      // If the user is logged in and trying to access login/register, redirect to dashboard
      if (loggedIn && loggingIn) {
        return '/dashboard';
      }

      // No redirect needed
      return null;
    },
    routes: <RouteBase>[
      // ShellRoute for main app layout with navigation rail
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(), // Use LoginScreen
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(), // Use RegisterScreen
      ),
      ShellRoute(
        builder: (context, state, child) {
          // Use MainLayout, passing the child widget (the current screen)
          return MainLayout(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            redirect: (_, __) => '/dashboard', // Redirect root to dashboard
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatDetailScreen(
          conversationId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/records',
        builder: (context, state) => const RecordsListScreen(),
      ),
      // Add route for SettingsScreen
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      // Placeholder routes for dashboard actions (implement actual screens later)
      GoRoute(
        path: '/chat/new', // Route for starting a new chat
        builder: (context, state) => const PlaceholderScreen(title: 'New Chat'), // Replace with actual screen
      ),
       GoRoute(
        path: '/records/:id', // Route for viewing record details
        builder: (context, state) => RecordDetailScreen(
          recordId: state.pathParameters['id']!,
        ),
      ),
       GoRoute(
        path: '/health-data', // Route for health data (placeholder)
        builder: (context, state) => const PlaceholderScreen(title: 'Health Data'), // Replace with actual screen
      ),
        ], // End of routes within ShellRoute
      ), // End of ShellRoute
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Page Not Found'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // 跳转到主页/dashboard
                GoRouter.of(context).go('/dashboard');
              },
              child: const Text('返回主页'),
            ),
          ],
        ),
      ),
    ),
  );
}