import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ThemePickerSheet extends StatelessWidget {
  const ThemePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const ThemePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemePreset>(
      valueListenable: AppTheme.currentThemeNotifier,
      builder: (context, currentPreset, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: AppTheme.borderSubtle, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Theme',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Choose your preferred visual aesthetic',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 20, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceSecondary,
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2x2 Grid of Theme Options
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _buildOption(
                      context: context,
                      preset: AppThemePreset.nordicNavy,
                      title: 'Nordic Navy',
                      subtitle: 'Executive Navy',
                      bgDot: const Color(0xFFF7F9FC),
                      primaryDot: const Color(0xFF142D4E),
                      accentDot: const Color(0xFF10B981),
                      isSelected: currentPreset == AppThemePreset.nordicNavy,
                    ),
                    _buildOption(
                      context: context,
                      preset: AppThemePreset.forestSage,
                      title: 'Forest Sage',
                      subtitle: 'Organic Pine',
                      bgDot: const Color(0xFFF7F6F0),
                      primaryDot: const Color(0xFF365747),
                      accentDot: const Color(0xFF84A98C),
                      isSelected: currentPreset == AppThemePreset.forestSage,
                    ),
                    _buildOption(
                      context: context,
                      preset: AppThemePreset.obsidianDark,
                      title: 'Obsidian Dark',
                      subtitle: 'Midnight Slate',
                      bgDot: const Color(0xFF0B0F17),
                      primaryDot: const Color(0xFF1E293B),
                      accentDot: const Color(0xFF10B981),
                      isSelected: currentPreset == AppThemePreset.obsidianDark,
                    ),
                    _buildOption(
                      context: context,
                      preset: AppThemePreset.warmAmber,
                      title: 'Warm Amber',
                      subtitle: 'Earthy Minimal',
                      bgDot: const Color(0xFFFFFBF5),
                      primaryDot: const Color(0xFF92400E),
                      accentDot: const Color(0xFFD97706),
                      isSelected: currentPreset == AppThemePreset.warmAmber,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required BuildContext context,
    required AppThemePreset preset,
    required String title,
    required String subtitle,
    required Color bgDot,
    required Color primaryDot,
    required Color accentDot,
    required bool isSelected,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await AppTheme.setPreset(preset);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.08)
                : AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.borderSubtle,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Palette Dots
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: bgDot,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: primaryDot,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: accentDot,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

