import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supa/cubits/auth_cubit.dart';
import 'package:supa/utils/tm_material_delegate.dart';
import 'package:supa/utils/tm_cupertino_delegate.dart';
import 'package:supa/cubits/garage_cubit.dart';
import 'package:supa/cubits/order_cubit.dart';
import 'package:supa/cubits/service_cubit.dart';
import 'package:supa/cubits/profile_cubit.dart';
import 'package:supa/cubits/theme_cubit.dart';
import 'package:supa/cubits/gemini_chat_cubit.dart';
import 'package:supa/services/gemini_service.dart';
import 'package:supa/screens/splash/splash_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supa/components/ui/connectivity_barrier.dart';
import 'package:supa/services/cache_service.dart';
import 'package:supa/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run independent initializations in parallel
  await Future.wait([
    EasyLocalization.ensureInitialized(),
    dotenv.load(fileName: ".env"),
    CacheService.init(),
    SharedPreferences.getInstance(),
  ]);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize Notifications (can also be parallelized if needed)
  await NotificationService().init();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ru'), Locale('tk')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const MainApp(),
    ),
  );
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
        BlocProvider(create: (context) => GeminiChatCubit(GeminiService())),
      ],
      child: BlocListener<AuthCubit, AuthCubitState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            CacheService.clearAll();
            context.read<GarageCubit>().clear();
            context.read<OrderCubit>().clear();
            context.read<ProfileCubit>().clear();
            context.read<ServiceCubit>().clear();
          } else if (state is AuthAuthenticated) {
            // Re-fetch data for the newly authenticated user
            context.read<ProfileCubit>().fetchProfile();
            context.read<GarageCubit>().fetchVehicles();
            context.read<ServiceCubit>().fetchServices();
            context.read<OrderCubit>().fetchMyOrders();
          }
        },
        child: BlocBuilder<ThemeCubit, bool>(
          builder: (context, isLightMode) {
            return MaterialApp(
              title: 'AutoService',
              debugShowCheckedModeBanner: false,
              themeMode: isLightMode ? ThemeMode.light : ThemeMode.dark,
              theme: _buildTheme(Brightness.light),
              darkTheme: _buildTheme(Brightness.dark),
              builder: (context, child) {
                return ConnectivityBarrier(child: child!);
              },
              localizationsDelegates: [
                const TmMaterialLocalizationsDelegate(),
                const TmCupertinoLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                ...context.localizationDelegates,
              ],
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    const primaryColor = Color(0xFF673AB7);
    final scaffoldBg = isDark
        ? const Color(0xFF0F0F1E)
        : const Color(0xFFF8F9FE);
    final cardBg = isDark ? const Color(0xFF1E1E2E) : Colors.white;

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
      textTheme:
          GoogleFonts.outfitTextTheme(
            isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
          ).apply(
            bodyColor: isDark ? Colors.white : Colors.black87,
            displayColor: isDark ? Colors.white : Colors.black,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: isDark ? 0 : 8,
        shadowColor: isDark ? Colors.transparent : Colors.black.withAlpha(40),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withAlpha(13)
            : Colors.grey.withAlpha(30),
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey[700]),
        labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withAlpha(40),
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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
