import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/service_locator.dart';
import 'services/database_service.dart';
import 'providers/index.dart';
import 'screens/auth/index.dart';
import 'screens/home_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.init();

  // Change to false to use real implementations
  setupServiceLocator(useMocks: true);

  runApp(const ShiptagApp());
}

class ShiptagApp extends StatelessWidget {
  const ShiptagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShipmentProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'SHIPTAG',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
          ),
          primaryColor: Colors.blue,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            // Check for remembered user on app startup
            if (!authProvider.rememberMe) {
              Future.microtask(() async {
                await authProvider.checkRememberedUser();
              });
            }

            if (authProvider.isAuthenticated) {
              return const HomeScreen();
            }
            return LoginScreen(
              onLoginSuccess: () {
                // Navigate to home
              },
            );
          },
        ),
        routes: {
          '/login': (context) => LoginScreen(
                onLoginSuccess: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
          '/signup': (context) => const SignUpScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/otp-verification': (context) {
            final mobileNumber =
                ModalRoute.of(context)?.settings.arguments as String?;
            return OtpVerificationScreen(
              mobileNumber: mobileNumber ?? '',
            );
          },
          '/reset-password': (context) {
            final mobileNumber =
                ModalRoute.of(context)?.settings.arguments as String?;
            return ResetPasswordScreen(
              mobileNumber: mobileNumber ?? '',
            );
          },
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}

