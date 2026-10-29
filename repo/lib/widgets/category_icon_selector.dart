import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../utils/app_theme.dart';

class CategoryIconSelector extends StatelessWidget {
  final int selectedIconCode;
  final int selectedColorValue;
  final ValueChanged<int> onIconSelected;
  final ValueChanged<int> onColorSelected;

  const CategoryIconSelector({
    super.key,
    required this.selectedIconCode,
    required this.selectedColorValue,
    required this.onIconSelected,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Color Picker Row
        Text(
          'Category Color',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AppTheme.categoryPalette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final color = AppTheme.categoryPalette[index];
              final isSelected = color.toARGB32() == selectedColorValue;
              return GestureDetector(
                onTap: () => onColorSelected(color.toARGB32()),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppTheme.textPrimary : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Icon Selector Grid
        Text(
          'Select Icon',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: AvailableCategoryIcons.icons.length,
            itemBuilder: (context, index) {
              final icon = AvailableCategoryIcons.icons[index];
              final isSelected = icon.codePoint == selectedIconCode;
              final currentColor = Color(selectedColorValue);

              return GestureDetector(
                onTap: () => onIconSelected(icon.codePoint),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? currentColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? currentColor : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isSelected ? currentColor : AppTheme.textSecondary,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
