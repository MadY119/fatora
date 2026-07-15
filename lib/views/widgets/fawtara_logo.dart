import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'package:fatora/core/constants/app_colors.dart';

class FawtaraLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDarkTheme;
  final Uint8List? logoBytes;

  const FawtaraLogo({
    super.key,
    this.size = 140,
    this.showText = true,
    this.isDarkTheme = true,
    this.logoBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // إذا كان هناك شعار مخصص، اعرضه
        if (logoBytes != null)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brandTeal, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandTeal.withOpacity(0.35),
                  blurRadius: 35,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.memory(logoBytes!, fit: BoxFit.cover),
            ),
          )
        // وإلا، اعرض الشعار الافتراضي
        else
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brandDark,
              border: Border.all(color: AppColors.brandTeal, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandTeal.withOpacity(0.35),
                  blurRadius: 35,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // خلفية الفاتورة البيضاء والفيروزية
                Positioned(
                  top: size * 0.18,
                  child: Container(
                    width: size * 0.45,
                    height: size * 0.55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(size * 0.06),
                      border: Border.all(color: AppColors.brandTeal, width: 2),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: size * 0.12,
                          width: double.infinity,
                          color: AppColors.brandTeal,
                        ),
                        const Spacer(),
                        Icon(CupertinoIcons.checkmark_alt, color: AppColors.brandTeal, size: size * 0.22),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
                // حرف "ف" المدمج مع اللوجو
                Positioned(
                  bottom: size * 0.22,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: size * 0.08, vertical: size * 0.02),
                    decoration: BoxDecoration(
                      color: AppColors.brandDark,
                      borderRadius: BorderRadius.circular(size * 0.2),
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                    child: Text(
                      'ف',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: size * 0.28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                // الدائرة الصغيرة لحرف الفاء
                Positioned(
                  top: size * 0.25,
                  right: size * 0.28,
                  child: CircleAvatar(radius: size * 0.04, backgroundColor: Colors.white),
                ),
                // الدائرة الفيروزية التكميلية تحت
                Positioned(
                  bottom: size * 0.12,
                  right: size * 0.22,
                  child: Container(
                    width: size * 0.2,
                    height: size * 0.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brandTeal,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // نصوص اللوجو (فواتير - إدارة فواتيرك بذكاء)
        if (showText) ...[
          SizedBox(height: size * 0.18),
          Text(
            'فواتير',
            style: GoogleFonts.plusJakartaSans(
              fontSize: size * 0.26,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: isDarkTheme ? Colors.white : AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'إدارة فواتيرك بذكاء',
            style: GoogleFonts.plusJakartaSans(
              fontSize: size * 0.12,
              fontWeight: FontWeight.w600,
              color: AppColors.brandTeal,
            ),
          ),
        ],
      ],
    );
  }
}