import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/currency_service.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pocketpilot.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final legacyPath = p.join(dbPath, 'blackvault.db');
    final path = p.join(dbPath, filePath);

    if (!await File(path).exists() && await File(legacyPath).exists()) {
      try {
        await File(legacyPath).copy(path);
      } catch (_) {}
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount_paise INTEGER NOT NULL,
        category_id INTEGER,
        title TEXT NOT NULL,
        notes TEXT,
        date_time TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
      )
    ''');

    // Budget settings table (key-value storage for offline preferences)
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Populate initial default categories
    final batch = db.batch();
    for (final cat in CategoryModel.defaultCategories) {
      batch.insert(
        'categories',
        cat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------------
  // Category Operations
  // ---------------------------------------------------------------------------

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final results = await db.query(
      'categories',
      orderBy: 'is_default DESC, name ASC',
    );
    return results.map((map) => CategoryModel.fromMap(map)).toList();
  }

  Future<CategoryModel?> getCategoryById(int id) async {
    final db = await database;
    final results = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return CategoryModel.fromMap(results.first);
  }

  /// Inserts a new category with duplicate-name check (case insensitive & trimmed).
  Future<int> insertCategory(CategoryModel category) async {
    final db = await database;
    final trimmedName = category.name.trim();

    // Check for duplicate name
    final existing = await db.rawQuery(
      'SELECT id FROM categories WHERE LOWER(TRIM(name)) = LOWER(?)',
      [trimmedName],
    );
    if (existing.isNotEmpty) {
      throw Exception('A category named "$trimmedName" already exists.');
    }

    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(CategoryModel category) async {
    final db = await database;
    final trimmedName = category.name.trim();

    // Check for duplicate name in other categories
    final existing = await db.rawQuery(
      'SELECT id FROM categories WHERE LOWER(TRIM(name)) = LOWER(?) AND id != ?',
      [trimmedName, category.id],
    );
    if (existing.isNotEmpty) {
      throw Exception('A category named "$trimmedName" already exists.');
    }

    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  /// Deletes a category safely.
  /// PRESERVES historical transactions by reassigning them to an "Uncategorized" category.
  Future<void> deleteCategory(int categoryId) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Find or create an "Uncategorized" fallback category
      final uncatResults = await txn.query(
        'categories',
        where: 'LOWER(TRIM(name)) = ?',
        whereArgs: ['uncategorized'],
        limit: 1,
      );

      int uncatId;
      if (uncatResults.isNotEmpty) {
        uncatId = uncatResults.first['id'] as int;
      } else {
        uncatId = await txn.insert('categories', {
          'name': 'Uncategorized',
          'icon_code': 0xe148, // Icons.category
          'color_value': 0xFF64748B,
          'is_default': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 2. Reassign all expenses belonging to the deleted category to Uncategorized
      await txn.update(
        'transactions',
        {'category_id': uncatId},
        where: 'category_id = ?',
        whereArgs: [categoryId],
      );

      // 3. Delete the category itself
      await txn.delete(
        'categories',
        where: 'id = ?',
        whereArgs: [categoryId],
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Transaction Operations
  // ---------------------------------------------------------------------------

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Fetches transactions with category join, optional search, type filter, category filter, date filter.
  Future<List<TransactionModel>> getTransactions({
    String? searchQuery,
    TransactionType? typeFilter,
    int? categoryIdFilter,
    DateTime? startDate,
    DateTime? endDate,
    bool ascending = false,
    int? limit,
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(t.title LIKE ? OR t.notes LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    if (typeFilter != null) {
      whereClauses.add('t.type = ?');
      whereArgs.add(typeFilter == TransactionType.expense ? 'expense' : 'income');
    }

    if (categoryIdFilter != null) {
      whereClauses.add('t.category_id = ?');
      whereArgs.add(categoryIdFilter);
    }

    if (startDate != null) {
      whereClauses.add('t.date_time >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('t.date_time <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    final whereSql =
        whereClauses.isNotEmpty ? 'WHERE ${whereClauses.join(' AND ')}' : '';
    final orderSql = ascending ? 'ASC' : 'DESC';
    final limitSql = limit != null ? 'LIMIT $limit' : '';

    final query = '''
      SELECT 
        t.id, t.type, t.amount_paise, t.category_id, t.title, t.notes,
        t.date_time, t.created_at,
        c.name AS category_name,
        c.icon_code AS category_icon_code,
        c.color_value AS category_color_value
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      $whereSql
      ORDER BY t.date_time $orderSql, t.id $orderSql
      $limitSql
    ''';

    final results = await db.rawQuery(query, whereArgs);
    return results.map((map) => TransactionModel.fromMap(map)).toList();
  }

  // ---------------------------------------------------------------------------
  // Budget & Financial Totals (Integer Paise Precision)
  // ---------------------------------------------------------------------------

  /// Total money added across all time (all income transactions)
  Future<int> getTotalMoneyAddedPaise() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_paise), 0) as total 
      FROM transactions 
      WHERE type = 'income'
    ''');
    return (result.first['total'] as int?) ?? 0;
  }

  /// Total expenses across all time (all expense transactions)
  Future<int> getTotalExpensesPaise({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    String dateFilter = '';
    final args = <dynamic>[];

    if (startDate != null && endDate != null) {
      dateFilter = ' AND date_time >= ? AND date_time <= ?';
      args.add(startDate.toIso8601String());
      args.add(endDate.toIso8601String());
    }

    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(amount_paise), 0) as total 
      FROM transactions 
      WHERE type = 'expense' $dateFilter
    ''', args);
    return (result.first['total'] as int?) ?? 0;
  }

  /// Calculates the complete financial overview in one atomic read:
  /// Total Money, Total Spent, Remaining Balance
  Future<Map<String, int>> getFinancialOverview() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount_paise ELSE 0 END), 0) AS total_money,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_paise ELSE 0 END), 0) AS total_expenses
      FROM transactions
    ''');

    final totalMoney = (result.first['total_money'] as int?) ?? 0;
    final totalExpenses = (result.first['total_expenses'] as int?) ?? 0;
    final remainingBalance = CurrencyService.calculateRemainingPaise(
      totalMoneyPaise: totalMoney,
      totalExpensesPaise: totalExpenses,
    );

    return {
      'total_money': totalMoney,
      'total_expenses': totalExpenses,
      'remaining_balance': remainingBalance,
    };
  }

  /// Sets or edits total budget.
  /// If the user sets a new total budget directly (e.g. ₹10,000),
  /// we calculate the difference between the target total money and current total money,
  /// and record an adjustment transaction with a clear title.
  Future<void> setTotalBudgetPaise(int targetTotalPaise) async {
    final currentTotal = await getTotalMoneyAddedPaise();
    final difference = targetTotalPaise - currentTotal;
    if (difference == 0) return;

    final now = DateTime.now().toIso8601String();
    if (difference > 0) {
      // Add income adjustment
      await insertTransaction(
        TransactionModel(
          type: TransactionType.income,
          amountPaise: difference,
          title: currentTotal == 0 ? 'Initial Budget Setup' : 'Budget Top-Up',
          notes: 'Set total budget to ${CurrencyService.formatPaise(targetTotalPaise)}',
          dateTime: now,
          createdAt: now,
        ),
      );
    } else {
      // Reduce budget: We adjust by inserting an offsetting negative or reducing transaction
      // Rather than falsifying history, record a budget correction
      await insertTransaction(
        TransactionModel(
          type: TransactionType.income,
          amountPaise: difference, // negative amount in paise
          title: 'Budget Reduction',
          notes: 'Adjusted total budget to ${CurrencyService.formatPaise(targetTotalPaise)}',
          dateTime: now,
          createdAt: now,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Spending Analytics Queries
  // ---------------------------------------------------------------------------

  /// Category breakdown for a given date range
  Future<List<Map<String, dynamic>>> getCategorySpendingBreakdown({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await database;
    final whereClauses = ["t.type = 'expense'"];
    final args = <dynamic>[];

    if (startDate != null) {
      whereClauses.add('t.date_time >= ?');
      args.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('t.date_time <= ?');
      args.add(endDate.toIso8601String());
    }

    final query = '''
      SELECT 
        COALESCE(c.id, 0) as category_id,
        COALESCE(c.name, 'Uncategorized') as category_name,
        COALESCE(c.icon_code, 0xe148) as category_icon_code,
        COALESCE(c.color_value, 0xFF64748B) as category_color_value,
        COALESCE(SUM(t.amount_paise), 0) as total_paise,
        COUNT(t.id) as transaction_count
      FROM transactions t
      LEFT JOIN categories c ON t.category_id = c.id
      WHERE ${whereClauses.join(' AND ')}
      GROUP BY c.id, c.name, c.icon_code, c.color_value
      ORDER BY total_paise DESC
    ''';

    return await db.rawQuery(query, args);
  }

  /// Monthly spending for the last 6 months (for bar chart)
  Future<List<Map<String, dynamic>>> getMonthlySpending({int monthsBack = 6}) async {
    final db = await database;
    final now = DateTime.now();
    final results = <Map<String, dynamic>>[];

    for (int i = monthsBack - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final nextMonthDate = DateTime(now.year, now.month - i + 1, 1);

      final row = await db.rawQuery('''
        SELECT COALESCE(SUM(amount_paise), 0) as total 
        FROM transactions 
        WHERE type = 'expense' 
          AND date_time >= ? 
          AND date_time < ?
      ''', [monthDate.toIso8601String(), nextMonthDate.toIso8601String()]);

      final totalPaise = (row.first['total'] as int?) ?? 0;
      results.add({
        'month_date': monthDate,
        'total_paise': totalPaise,
      });
    }

    return results;
  }

  // ---------------------------------------------------------------------------
  // Settings & App PIN Lock (Offline, Hashed)
  // ---------------------------------------------------------------------------

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  // ---------------------------------------------------------------------------
  // Local Backup, Restore & Reset
  // ---------------------------------------------------------------------------

  /// Exports complete database to a structured JSON string for offline backup
  Future<String> exportBackupJson() async {
    final db = await database;
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final settings = await db.query('settings');

    final backupMap = {
      'app': 'PocketPilot',
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'categories': categories,
      'transactions': transactions,
      'settings': settings,
    };

    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  /// Restores database from a valid JSON backup string
  Future<void> restoreBackupJson(String jsonString) async {
    final db = await database;
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic> ||
        (decoded['app'] != 'PocketPilot' && decoded['app'] != 'BlackVault')) {
      throw Exception('Invalid PocketPilot backup file format.');
    }

    await db.transaction((txn) async {
      // Clear existing records safely
      await txn.delete('transactions');
      await txn.delete('categories');
      await txn.delete('settings');

      // Restore categories
      final categories = decoded['categories'] as List<dynamic>? ?? [];
      for (final cat in categories) {
        if (cat is Map<String, dynamic>) {
          await txn.insert('categories', cat);
        }
      }

      // Restore transactions
      final transactions = decoded['transactions'] as List<dynamic>? ?? [];
      for (final tx in transactions) {
        if (tx is Map<String, dynamic>) {
          await txn.insert('transactions', tx);
        }
      }

      // Restore settings
      final settings = decoded['settings'] as List<dynamic>? ?? [];
      for (final s in settings) {
        if (s is Map<String, dynamic>) {
          await txn.insert('settings', s);
        }
      }
    });
  }

  /// Resets all data completely and reinitializes default categories.
  Future<void> resetAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('categories');
      await txn.delete('settings');

      for (final cat in CategoryModel.defaultCategories) {
        await txn.insert('categories', cat.toMap());
      }
    });
  }
}
