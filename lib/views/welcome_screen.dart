import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fatora/core/constants/app_colors.dart';
import 'package:fatora/views/widgets/fawtara_logo.dart';
import 'package:fatora/views/widgets/app_navigation.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Uint8List? _logoBytes;

  @override
  void initState() {
    super.initState();
    _loadLogo();
    // أنيميشن تنفس هادي وسلس للوجو
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fadeAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  Future<void> _loadLogo() async {
    final prefs = await SharedPreferences.getInstance();
    final logoBase64 = prefs.getString('company_logo');
    if (logoBase64 != null && mounted) {
      try {
        setState(() => _logoBytes = base64Decode(logoBase64));
      } catch (e) {
        // Logo decode failed, use default
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, AppNavigation.dashboardRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // 🌟 1. خلفية لايت نظيفة ومريحة للعين (Slate-tinted Off-White)
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // 🌟 2. تدرجات إضاءة خلفية ناعمة جداً (Light Ambient Blobs)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryContainer.withOpacity(0.6), // Soft Blue Tint
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -100,
              child: Container(
                width: 380,
                height: 380,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2EB5B7).withOpacity(0.15), // Soft Teal Tint
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // 🌟 3. المحتوى الأساسي للشاشة
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // شريط علوي صغير إداري على كارت أبيض
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface, // Pure White
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.outline.withOpacity(0.3), width: 1),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.primary, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Executive Light Edition',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // 🌟 4. اللوجو التفاعلي على النظام الفاتح (isDarkTheme: false)
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) => Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(opacity: _fadeAnimation.value, child: child),
                      ),
                      // هنا السر: isDarkTheme: false عشان النص يطلع كحلي غامق فخم
                      child: FawtaraLogo(size: 160, showText: true, isDarkTheme: false, logoBytes: _logoBytes),
                    ),

                    // منطقة زرار "ابدأ الآن" والنسخة
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 380),
                          decoration: BoxDecoration(
                            boxShadow: [
                              // ظل أزرق هادي ومؤسسي
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.2),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _navigateToDashboard,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary, // Blue #0052D1
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('ابدأ الآن', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(width: 12),
                                const Icon(CupertinoIcons.arrow_left, size: 20, color: Colors.white),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'v1.0.0 ENTERPRISE EDITION',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600, color: AppColors.outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
