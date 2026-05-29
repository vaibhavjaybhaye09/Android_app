import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'core/network/dio_client.dart';
import 'features/accounts/providers/auth_provider.dart';
import 'features/accounts/screens/forgot_password_screen.dart';
import 'features/accounts/screens/login_screen.dart';
import 'features/accounts/screens/otp_verification_screen.dart';
import 'features/accounts/screens/register_screen.dart';
import 'features/accounts/screens/role_selection_screen.dart';
import 'features/photographers/screens/home_screen.dart';
import 'features/bookings/providers/booking_provider.dart';
import 'features/photographers/providers/photographer_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dioClient = DioClient();
  final apiService = ApiService(dioClient);
  final authService = AuthService(dioClient);
  const secureStorage = FlutterSecureStorage();

  runApp(
    MyApp(
      apiService: apiService,
      authService: authService,
      secureStorage: secureStorage,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    required this.apiService,
    required this.authService,
    required this.secureStorage,
    super.key,
  });

  final ApiService apiService;
  final AuthService authService;
  final FlutterSecureStorage secureStorage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(authService, secureStorage),
        ),
        ChangeNotifierProvider(
          create: (_) => PhotographerProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => BookingProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(apiService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PhotoHub',
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F7F7),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0095F6),
            primary: const Color(0xFF0095F6),
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF262626),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/verify-otp': (context) => const OtpVerificationScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/home': (context) => const HomeScreen(),
          '/select-role': (context) => const RoleSelectionScreen(),
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _shutterAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _shutterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeInOutQuart),
      ),
    );

    _controller.forward();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = await authProvider.isLoggedIn();

    if (!mounted) return;

    if (isLoggedIn) {
      if (authProvider.currentUser?.role == 'unassigned') {
        Navigator.pushReplacementNamed(context, '/select-role');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.white),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Aperture/Shutter Effect
                Transform.scale(
                  scale: 1.0 + (1.0 - _shutterAnimation.value) * 2,
                  child: Opacity(
                    opacity: (1.0 - _shutterAnimation.value).clamp(0.0, 1.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1A1A1A),
                          width: 100 * (1.0 - _shutterAnimation.value),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Content
                Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0095F6).withOpacity(0.1),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0095F6).withOpacity(0.1),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_rounded,
                            size: 80,
                            color: Color(0xFF0095F6),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'PhotoHub',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Capture Every Moment',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 80),
                        const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0095F6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.camera_alt_outlined,
        size: 60,
        color: Color(0xFF0095F6),
      ),
    );
  }
}
