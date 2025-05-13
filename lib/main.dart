import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/ilan_service.dart';
import 'services/storage_service.dart';
import 'pages/splash_screen.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<IlanService>(
          create: (_) => IlanService(),
        ),
        Provider<StorageService>(
          create: (_) => StorageService(),
        ),
      ],
      child: MaterialApp(
        title: 'BendeVar',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.bordo,
            primary: AppColors.bordo,
            onPrimary: AppColors.beyaz,
            secondary: AppColors.bordo.withOpacity(0.7),
            onSecondary: AppColors.beyaz,
            background: AppColors.beyaz,
            onBackground: AppColors.darkGrey,
            surface: AppColors.beyaz,
            onSurface: AppColors.darkGrey,
            error: Colors.redAccent,
            onError: AppColors.beyaz,
          ),
          scaffoldBackgroundColor: AppColors.beyaz,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.bordo,
            foregroundColor: AppColors.beyaz,
            elevation: 0,
            titleTextStyle: TextStyle(
              color: AppColors.beyaz,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            iconTheme: IconThemeData(
              color: AppColors.beyaz,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bordo,
              foregroundColor: AppColors.beyaz,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.bordo,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: AppColors.bordo,
            foregroundColor: AppColors.beyaz,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedItemColor: AppColors.bordo,
            unselectedItemColor: AppColors.mediumGrey,
            backgroundColor: AppColors.beyaz,
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.bordo, width: 2),
            ),
            labelStyle: const TextStyle(color: AppColors.mediumGrey),
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
