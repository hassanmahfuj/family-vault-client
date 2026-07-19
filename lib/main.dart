import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/file_provider.dart';
import 'providers/share_provider.dart';
import 'providers/upload_provider.dart';
import 'services/pin_storage.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/pin_screen.dart';

void main() {
  runApp(const FamilyVaultApp());
}

class FamilyVaultApp extends StatelessWidget {
  const FamilyVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider(create: (_) => ShareProvider()),
        ChangeNotifierProvider(create: (_) => UploadProvider()),
      ],
      child: MaterialApp(
        title: 'FamilyVault',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _pinUnlocked = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isCheckingAuth) {
          return const _SplashScreen();
        }

        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        if (!_pinUnlocked) {
          return FutureBuilder<bool>(
            future: PinStorage().hasPin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _SplashScreen();
              }
              final hasPin = snapshot.data ?? false;
              if (!hasPin) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _pinUnlocked = true);
                });
                return const _SplashScreen();
              }
              return PinScreen(
                onUnlocked: () {
                  setState(() => _pinUnlocked = true);
                },
              );
            },
          );
        }

        return const MainScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.cloud_outlined,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'FamilyVault',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
