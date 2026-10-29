import 'package:flutter/material.dart';
import 'category_model.dart';
import '../services/currency_service.dart';

enum TransactionType {
  expense,
  income, // Money added to budget
}

class TransactionModel {
  final int? id;
  final TransactionType type;
  final int amountPaise;
  final int? categoryId;
  final String title;
  final String? notes;
  final String dateTime; // ISO 8601 string
  final String createdAt;

  // Joined fields from category table (for display)
  final String? categoryName;
  final int? categoryIconCode;
  final int? categoryColorValue;

  const TransactionModel({
    this.id,
    required this.type,
    required this.amountPaise,
    this.categoryId,
    required this.title,
    this.notes,
    required this.dateTime,
    required this.createdAt,
    this.categoryName,
    this.categoryIconCode,
    this.categoryColorValue,
  });

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  double get amountInRupees => CurrencyService.paiseToRupees(amountPaise);
  String get formattedAmount => CurrencyService.formatPaise(
        amountPaise,
        showSign: true,
      );

  DateTime get parsedDateTime {
    try {
      return DateTime.parse(dateTime);
    } catch (_) {
      return DateTime.now();
    }
  }

  IconData get displayIcon {
    if (isIncome) {
      return Icons.arrow_downward_rounded;
    }
    if (categoryIconCode != null && categoryIconCode! > 0) {
      return AvailableCategoryIcons.getIcon(categoryIconCode!);
    }
    return Icons.receipt_long;
  }

  Color get displayColor {
    if (isIncome) {
      return const Color(0xFF10B981); // Emerald Green
    }
    if (categoryColorValue != null && categoryColorValue! > 0) {
      return Color(categoryColorValue!);
    }
    return const Color(0xFFEF4444); // Tasteful Red
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type == TransactionType.expense ? 'expense' : 'income',
      'amount_paise': amountPaise,
      'category_id': categoryId,
      'title': title.trim(),
      'notes': notes?.trim(),
      'date_time': dateTime,
      'created_at': createdAt,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: (map['type'] as String) == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      amountPaise: map['amount_paise'] as int,
      categoryId: map['category_id'] as int?,
      title: map['title'] as String,
      notes: map['notes'] as String?,
      dateTime: map['date_time'] as String,
      createdAt: map['created_at'] as String,
      categoryName: map['category_name'] as String?,
      categoryIconCode: map['category_icon_code'] as int?,
      categoryColorValue: map['category_color_value'] as int?,
    );
  }

  TransactionModel copyWith({
    int? id,
    TransactionType? type,
    int? amountPaise,
    int? categoryId,
    String? title,
    String? notes,
    String? dateTime,
    String? createdAt,
    String? categoryName,
    int? categoryIconCode,
    int? categoryColorValue,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      amountPaise: amountPaise ?? this.amountPaise,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dateTime: dateTime ?? this.dateTime,
      createdAt: createdAt ?? this.createdAt,
      categoryName: categoryName ?? this.categoryName,
      categoryIconCode: categoryIconCode ?? this.categoryIconCode,
      categoryColorValue: categoryColorValue ?? this.categoryColorValue,
    );
  }
}
