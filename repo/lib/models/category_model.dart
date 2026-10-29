import 'package:flutter/material.dart';

class CategoryModel {
  final int? id;
  final String name;
  final int iconCode;
  final int colorValue;
  final bool isDefault;
  final String createdAt;

  const CategoryModel({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
    this.isDefault = false,
    required this.createdAt,
  });

  IconData get icon => AvailableCategoryIcons.getIcon(iconCode);
  Color get color => Color(colorValue);

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name.trim(),
      'icon_code': iconCode,
      'color_value': colorValue,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      iconCode: map['icon_code'] as int,
      colorValue: map['color_value'] as int,
      isDefault: (map['is_default'] as int) == 1,
      createdAt: map['created_at'] as String,
    );
  }

  CategoryModel copyWith({
    int? id,
    String? name,
    int? iconCode,
    int? colorValue,
    bool? isDefault,
    String? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Predefined default categories with carefully chosen icons and distinct colors
  static List<CategoryModel> get defaultCategories {
    final now = DateTime.now().toIso8601String();
    return [
      CategoryModel(
        name: 'Food',
        iconCode: Icons.restaurant.codePoint,
        colorValue: 0xFFF59E0B, // Amber
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Transport',
        iconCode: Icons.directions_car.codePoint,
        colorValue: 0xFF3B82F6, // Blue
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Shopping',
        iconCode: Icons.shopping_bag.codePoint,
        colorValue: 0xFFEC4899, // Pink
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Education',
        iconCode: Icons.school.codePoint,
        colorValue: 0xFF8B5CF6, // Purple
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Entertainment',
        iconCode: Icons.movie.codePoint,
        colorValue: 0xFF06B6D4, // Cyan
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Bills',
        iconCode: Icons.receipt_long.codePoint,
        colorValue: 0xFFF97316, // Orange
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Health',
        iconCode: Icons.local_hospital.codePoint,
        colorValue: 0xFFEF4444, // Red
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Personal Care',
        iconCode: Icons.spa.codePoint,
        colorValue: 0xFF14B8A6, // Teal
        isDefault: true,
        createdAt: now,
      ),
      CategoryModel(
        name: 'Other',
        iconCode: Icons.category.codePoint,
        colorValue: 0xFF64748B, // Slate
        isDefault: true,
        createdAt: now,
      ),
    ];
  }
}

/// Curated selectable icons for user custom categories
class AvailableCategoryIcons {
  static const List<IconData> icons = [
    Icons.restaurant,
    Icons.fastfood,
    Icons.local_cafe,
    Icons.shopping_bag,
    Icons.shopping_cart,
    Icons.directions_car,
    Icons.two_wheeler,
    Icons.train,
    Icons.flight,
    Icons.receipt_long,
    Icons.electric_bolt,
    Icons.water_drop,
    Icons.home,
    Icons.wifi,
    Icons.school,
    Icons.menu_book,
    Icons.movie,
    Icons.sports_esports,
    Icons.fitness_center,
    Icons.local_hospital,
    Icons.medical_services,
    Icons.spa,
    Icons.pets,
    Icons.work,
    Icons.savings,
    Icons.card_giftcard,
    Icons.account_balance,
    Icons.category,
  ];

  static IconData getIcon(int code) {
    for (final icon in icons) {
      if (icon.codePoint == code) return icon;
    }
    return Icons.category;
  }
}
