import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/cubits/garage_cubit.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/service_cubit.dart';
import 'package:supa/cubits/profile_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:supa/screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(create: (context) => GarageCubit()..fetchVehicles()),
        BlocProvider(create: (context) => OrderCubit()..fetchMyOrders()),
        BlocProvider(create: (context) => ServiceCubit()..fetchServices()),
        BlocProvider(create: (context) => ProfileCubit()..fetchProfile()),
        BlocProvider(
          create: (context) => ThemeCubit(context.read<ProfileCubit>()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, bool>(
        builder: (context, isLightMode) {
          return MaterialApp(
            title: 'AutoService',
            debugShowCheckedModeBanner: false,
            themeMode: isLightMode ? ThemeMode.light : ThemeMode.dark,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primaryColor = const Color(0xFF673AB7);
    final scaffoldBg = isDark
        ? const Color(0xFF0F0F1E)
        : const Color(0xFFF8F9FE);
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: Color(0xFF673AB7),
              secondary: Color(0xFF03DAC6),
              surface: Color(0xFF0F0F1E),
              onSurface: Colors.white,
            )
          : const ColorScheme.light(
              primary: Color(0xFF673AB7),
              secondary: Color(0xFF512DA8),
              surface: Colors.white,
              onSurface: Color(0xFF1A1A2E),
            ),
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: GoogleFonts.outfitTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).apply(bodyColor: textColor, displayColor: textColor),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withAlpha(13)
            : Colors.black.withAlpha(10),
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : Colors.black.withAlpha(179),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black12,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF673AB7), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: isDark ? 4 : 2,
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
