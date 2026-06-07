import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/join_screen.dart';
import 'screens/watch_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const LiliWatchApp(),
    ),
  );
}

class LiliWatchApp extends StatelessWidget {
  const LiliWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lili Watch',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const _RootNavigator(),
    );
  }
}

class _RootNavigator extends StatelessWidget {
  const _RootNavigator();

  @override
  Widget build(BuildContext context) {
    final screen = context.select<AppProvider, AppScreen>((p) => p.screen);
    return switch (screen) {
      AppScreen.join       => const JoinScreen(),
      AppScreen.connecting => const _ConnectingScreen(),
      AppScreen.watch      => const WatchScreen(),
    };
  }
}

class _ConnectingScreen extends StatelessWidget {
  const _ConnectingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepNight,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💕', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppTheme.rosePink),
            const SizedBox(height: 16),
            const Text(
              'بنوصّل...',
              style: TextStyle(color: AppTheme.warmWhite, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
