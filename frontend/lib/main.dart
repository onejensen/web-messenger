import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/home_screen.dart'; // Placeholder

import 'package:flutter/foundation.dart';
import 'widgets/global_error_display.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  // Capture framework errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      // In debug, we still want it in the console, but we don't want to 
      // necessarily stop the custom ErrorWidget from rendering.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In release, we could log to server
    }
  };

  // Capture asynchronous errors (outside of the widget tree)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Global Async Error: $error');
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text('An unexpected error occurred: $error'),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'RELOAD',
          textColor: Colors.white,
          onPressed: () {
            runApp(const RestartWidget(child: MyApp()));
          },
        ),
      ),
    );
    return true; // handled
  };

  // Custom error widget for UI crashes
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return GlobalErrorDisplay(
      errorDetails: kDebugMode ? details : null,
      onRetry: () {
         runApp(const RestartWidget(child: MyApp()));
      },
    );
  };

  runApp(const RestartWidget(child: MyApp()));
}

class RestartWidget extends StatefulWidget {
  final Widget child;
  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        scaffoldMessengerKey: messengerKey,
        builder: (context, widget) {
          // Wrap with another error boundary if needed, but ErrorWidget.builder is global.
          return widget!;
        },
        title: 'Kood/Sisu Messenger',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.deepPurpleAccent,
          colorScheme: const ColorScheme.dark(
            primary: Colors.deepPurpleAccent,
            secondary: Colors.tealAccent,
            surface: Color(0xFF1E1E2C),
          ),
          scaffoldBackgroundColor: const Color(0xFF121212),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF2C2C3E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurpleAccent, width: 2),
            ),
            labelStyle: const TextStyle(color: Colors.white70),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          LoginScreen.routeName: (ctx) => const LoginScreen(),
          RegisterScreen.routeName: (ctx) => const RegisterScreen(),
          HomeScreen.routeName: (ctx) => const HomeScreen(),
          VerificationScreen.routeName: (ctx) {
            final args = ModalRoute.of(ctx)!.settings.arguments as String;
            return VerificationScreen(email: args);
          },
        },
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Perform auto-login check once
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.tryAutoLogin();
    
    // Init socket if authenticated
    // Moved to HomeScreen initState for better lifecycle management
    // if (auth.isAuthenticated && auth.token != null) { ... }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Listen to changes to redirect if logout/login happens
    final auth = Provider.of<AuthProvider>(context);
    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
