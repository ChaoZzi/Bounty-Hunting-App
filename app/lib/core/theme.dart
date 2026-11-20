import 'package:flutter/material.dart';

/// 黑金设计 Token —— 与 docs/设计规范.md 保持一致
class AppColors {
  static const bgBase = Color(0xFF08090C);
  static const bgElevated = Color(0xFF12141A);
  static const bgCard = Color(0xFF16181F);

  static const hairline = Color(0x12FFFFFF);

  static const textPrimary = Color(0xFFF5F6F8);
  static const textSecondary = Color(0xFFA8ADB8);
  static const textTertiary = Color(0xFF6B7280);

  static const gold300 = Color(0xFFF3D9A4);
  static const gold500 = Color(0xFFD9B678);
  static const gold700 = Color(0xFFA8843F);

  static const success = Color(0xFF3DDC97);
  static const warning = Color(0xFFFFB020);
  static const danger = Color(0xFFFF4D4F);
  static const info = Color(0xFF5B8CFF);

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold300, Color(0xFFC9A15E)],
  );
}

class AppTheme {
  static ThemeData get dark {
    final scheme = const ColorScheme.dark(
      primary: AppColors.gold500,
      secondary: AppColors.gold300,
      surface: AppColors.bgCard,
      error: AppColors.danger,
      onPrimary: Color(0xFF1A1206),
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bgBase,
      fontFamily: 'HarmonyOS Sans SC',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgBase,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(color: AppColors.textPrimary, fontSize: 34, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        bodySmall: TextStyle(color: AppColors.textTertiary, fontSize: 12),
      ),
      dividerColor: AppColors.hairline,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold500, width: 1.2),
        ),
      ),
    );
  }
}

/// 主按钮：金色渐变 + 深色文字
class GoldButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onTap;
  final double height;

  const GoldButton({
    super.key,
    required this.text,
    this.loading = false,
    this.onTap,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = loading || onTap == null;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: height,
        decoration: BoxDecoration(
          gradient: disabled ? null : AppColors.goldGradient,
          color: disabled ? const Color(0xFF2A2D35) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.gold700.withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ],
        ),
        alignment: Alignment.center,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1206)),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: disabled ? AppColors.textTertiary : const Color(0xFF1A1206),
                ),
              ),
      ),
    );
  }
}

/// 卡片：深色 + 细描边（深色下不用阴影分层）
class DarkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const DarkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.hairline),
        ),
        child: child,
      ),
    );
  }
}
