import 'package:fluffy_link/core/theme.dart';
import 'package:fluffy_link/screens/home/home_screen.dart';
import 'package:fluffy_link/screens/landing/landing_screen.dart';
import 'package:fluffy_link/screens/redirect/redirect_screen.dart';
import 'package:fluffy_link/screens/stats/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/s/:code',
      builder: (context, state) {
        return StatsScreen(code: state.pathParameters['code']!);
      },
    ),
    GoRoute(path: '/upload', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
    GoRoute(
      path: '/:code',
      builder: (context, state) {
        return RedirectScreen(code: state.pathParameters['code']!);
      },
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
);

class PermaLinkApp extends StatelessWidget {
  const PermaLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Perma.link',
      theme: AppTheme.dark,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.link_off_rounded,
              size: 48,
              color: AppTheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Link not found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              "This link doesn't exist or may have expired.",
              style: TextStyle(color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Go to Perma.link'),
            ),
          ],
        ),
      ),
    );
  }
}
