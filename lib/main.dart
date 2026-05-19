import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'config/api_config.dart';

import 'screens/auth_wrapper.dart';

import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/profiles/edit_profile_screen.dart';

import 'providers/profile_provider.dart';

import 'repositories/auth_repository.dart';

import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/shared_prefs_service.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  HttpOverrides.global = MyHttpOverrides();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Shared Preferences
        Provider<SharedPrefsService>(create: (_) => SharedPrefsService()),

        // API Client
        Provider<ApiClient>(
          create: (context) =>
              ApiClient(prefsService: context.read<SharedPrefsService>()),
        ),

        // Repository
        Provider<AuthRepository>(
          create: (context) => AuthRepository(
            baseUrl: ApiConfig.baseUrl,
            prefsService: context.read<SharedPrefsService>(),
          ),
        ),

        // AUTH SERVICE
        ChangeNotifierProvider<AuthService>(
          create: (context) => AuthService(
            authRepository: context.read<AuthRepository>(),
            prefsService: context.read<SharedPrefsService>(),
          ),
        ),

        // PROFILE PROVIDER
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(),
        ),
      ],

      child: MaterialApp(
        title: 'Giziku',

        debugShowCheckedModeBanner: false,

        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2AD882)),

          useMaterial3: true,

          fontFamily: 'Poppins',

          textTheme: const TextTheme(
            displayLarge: TextStyle(fontFamily: 'Poppins'),

            displayMedium: TextStyle(fontFamily: 'Poppins'),

            displaySmall: TextStyle(fontFamily: 'Poppins'),

            headlineLarge: TextStyle(fontFamily: 'Poppins'),

            headlineMedium: TextStyle(fontFamily: 'Poppins'),

            headlineSmall: TextStyle(fontFamily: 'Poppins'),

            titleLarge: TextStyle(fontFamily: 'Poppins'),

            titleMedium: TextStyle(fontFamily: 'Poppins'),

            titleSmall: TextStyle(fontFamily: 'Poppins'),

            bodyLarge: TextStyle(fontFamily: 'Poppins'),

            bodyMedium: TextStyle(fontFamily: 'Poppins'),

            bodySmall: TextStyle(fontFamily: 'Poppins'),

            labelLarge: TextStyle(fontFamily: 'Poppins'),

            labelMedium: TextStyle(fontFamily: 'Poppins'),

            labelSmall: TextStyle(fontFamily: 'Poppins'),
          ),
        ),

        home: const AuthWrapper(),

        routes: {
          '/profile': (context) => const ProfileScreen(),

          '/edit_profile': (context) => const EditProfileScreen(),
        },
      ),
    );
  }
}
