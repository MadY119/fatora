import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fatora/core/constants/app_colors.dart';
import 'package:fatora/views/dashboard_screen.dart';
import 'package:fatora/views/invoice_form_screen.dart';
import 'package:fatora/views/invoice_history_screen.dart';
import 'package:fatora/views/settings_screen.dart';
import 'package:fatora/views/welcome_screen.dart';
import 'package:fatora/views/widgets/app_navigation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FawtaraApp());
}

class FawtaraApp extends StatelessWidget {
  const FawtaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fawtara - Executive Billing',
      debugShowCheckedModeBanner: false,
      // 🌟 تطبيق نظام Executive Light Narrative (Corporate Modern)
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          background: AppColors.background,
          onSurface: AppColors.textPrimary,
        ),
        // 🌟 استخدام خط Plus Jakarta Sans في كل مكان في التطبيق
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        ),
        // ضبط تصميم الكروت (White Card with 1px Slate Border)
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // rounded-lg
            side: const BorderSide(color: AppColors.outline, width: 1),
          ),
        ),
      ),
      home: const WelcomeScreen(),
      routes: {
        AppNavigation.dashboardRoute: (_) => const DashboardScreen(),
        AppNavigation.invoicesRoute: (_) => const InvoiceHistoryScreen(),
        AppNavigation.newInvoiceRoute: (_) => const InvoiceFormScreen(),
        AppNavigation.settingsRoute: (_) => const SettingsScreen(),
      },
    );
  }
}
