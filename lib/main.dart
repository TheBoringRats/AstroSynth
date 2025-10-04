import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/constants.dart';
import 'config/theme.dart';
import 'providers/filter_provider.dart';
import 'providers/planet_provider.dart';
import 'screens/planet_browser_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (will be added later)
  // await Firebase.initializeApp();

  runApp(const AstroSynthApp());
}

class AstroSynthApp extends StatelessWidget {
  const AstroSynthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlanetProvider()),
        ChangeNotifierProvider(create: (_) => FilterProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
        // Routes will be added here
        // routes: AppRoutes.routes,
      ),
    );
  }
}

/// Temporary Splash Screen - will be replaced with proper implementation
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusMessage = 'Initializing...';
  double _progress = 0.0;
  int _loadedPlanets = 0;
  int _totalPlanets = 1033;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final provider = Provider.of<PlanetProvider>(context, listen: false);

    setState(() {
      _statusMessage = 'Checking local cache...';
      _progress = 0.1;
    });

    // Check if we have cached data
    final progress = await provider.getLoadingProgress();
    final cachedCount = progress['cachedCount'] as int;
    final isCacheFresh = progress['isCacheFresh'] as bool;
    final isComplete = progress['isComplete'] as bool;

    if (isCacheFresh && isComplete) {
      // Use cached data
      setState(() {
        _statusMessage = 'Loading ${cachedCount} cached planets...';
        _progress = 0.5;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PlanetBrowserScreen()),
        );
      }
    } else {
      // Load all planets from API
      setState(() {
        _statusMessage = 'Fetching planets from NASA TAP API...';
        _progress = 0.2;
      });

      await provider.loadAllPlanetsWithProgress(
        onProgress: (loaded, total) {
          if (mounted) {
            setState(() {
              _loadedPlanets = loaded;
              _totalPlanets = total;
              _statusMessage = 'Loading planets from NASA...';
              _progress = 0.2 + (loaded / total * 0.7);
            });
          }
        },
      );

      setState(() {
        _statusMessage = 'Ready to explore!';
        _progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PlanetBrowserScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.spaceBackgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo (placeholder)
              Icon(Icons.public, size: 120, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppConstants.appDescription,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Progress indicator
              SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              if (_loadedPlanets > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '$_loadedPlanets / $_totalPlanets planets',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Temporary Home Screen - will be replaced with proper implementation
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.spaceBackgroundGradient),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rocket_launch,
                size: 100,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to ${AppConstants.appName}',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Explore the universe of exoplanets and discover potential habitable worlds!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to planet browser (to be implemented)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Planet Browser - Coming Soon!'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                },
                icon: const Icon(Icons.explore),
                label: const Text('Explore Planets'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
