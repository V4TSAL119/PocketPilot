import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/currency_service.dart';
import '../utils/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/transaction_tile.dart';
import 'add_expense_screen.dart';

enum DateFilterOption {
  allTime,
  today,
  thisWeek,
  thisMonth,
  custom,
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  // Filters
  TransactionType? _typeFilter; // null = all, expense, income
  int? _selectedCategoryId;
  DateFilterOption _dateFilter = DateFilterOption.allTime;
  DateTimeRange? _customDateRange;
  bool _ascending = false; // default: newest first

  @override
  void initState() {
    super.initState();
    _loadFiltersAndData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiltersAndData() async {
    final categories = await AppDatabase.instance.getAllCategories();
    setState(() => _categories = categories);
    await _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);

    DateTime? startDate;
    DateTime? endDate;
    final now = DateTime.now();

    switch (_dateFilter) {
      case DateFilterOption.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DateFilterOption.thisWeek:
        // Week starting Monday
        final daysFromMonday = (now.weekday - 1);
        final monday = now.subtract(Duration(days: daysFromMonday));
        startDate = DateTime(monday.year, monday.month, monday.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case DateFilterOption.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case DateFilterOption.custom:
        if (_customDateRange != null) {
          startDate = DateTime(
            _customDateRange!.start.year,
            _customDateRange!.start.month,
            _customDateRange!.start.day,
          );
          endDate = DateTime(
            _customDateRange!.end.year,
            _customDateRange!.end.month,
            _customDateRange!.end.day,
            23,
            59,
            59,
          );
        }
        break;
      case DateFilterOption.allTime:
        startDate = null;
        endDate = null;
        break;
    }

    try {
      final results = await AppDatabase.instance.getTransactions(
        searchQuery: _searchController.text,
        typeFilter: _typeFilter,
        categoryIdFilter: _selectedCategoryId,
        startDate: startDate,
        endDate: endDate,
        ascending: _ascending,
      );

      if (mounted) {
        setState(() {
          _transactions = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (context, child) {
        return Theme(
          data: AppTheme.currentThemeData,
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _dateFilter = DateFilterOption.custom;
      });
      _fetchTransactions();
    }
  }

  void _showTransactionDetails(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final isExpense = tx.isExpense;
        final dateFormatted = DateFormat('EEEE, dd MMMM yyyy, hh:mm a')
            .format(tx.parsedDateTime);

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: tx.displayColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(tx.displayIcon, color: tx.displayColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.title,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isExpense
                              ? (tx.categoryName ?? 'Uncategorized')
                              : 'Income / Top-Up',
                          style: TextStyle(
                            color: tx.displayColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyService.formatPaise(tx.amountPaise.abs(), showSign: true),
                    style: TextStyle(
                      color: isExpense ? AppTheme.tastefulRed : AppTheme.emeraldGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: AppTheme.borderSubtle),
              const SizedBox(height: 12),
              _buildDetailRow('Date & Time', dateFormatted),
              if (tx.notes != null && tx.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Notes', tx.notes!),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.tastefulRed,
                        side: BorderSide(color: AppTheme.tastefulRed),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final confirmed = await ConfirmDialog.show(
                          context: this.context,
                          title: 'Delete Transaction',
                          message:
                              'Are you sure you want to delete this record? This will immediately recalculate your total balance.',
                        );
                        if (confirmed && tx.id != null) {
                          await AppDatabase.instance.deleteTransaction(tx.id!);
                          _fetchTransactions();
                        }
                      },
                    ),
                  ),
                  if (isExpense) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emeraldGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final updated = await Navigator.of(this.context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddExpenseScreen(initialExpense: tx),
                            ),
                          );
                          if (updated == true) {
                            _fetchTransactions();
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Records'),
        actions: [
          IconButton(
            tooltip: _ascending ? 'Showing Oldest First' : 'Showing Newest First',
            icon: Icon(
              _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: AppTheme.emeraldGreen,
            ),
            onPressed: () {
              setState(() => _ascending = !_ascending);
              _fetchTransactions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: AppTheme.background,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  onChanged: (_) => _fetchTransactions(),
                  decoration: InputDecoration(
                    hintText: 'Search by title or notes...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchTransactions();
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 10),

                // Type filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // All Type Chip
                      FilterChip(
                        label: const Text('All Types'),
                        selected: _typeFilter == null,
                        backgroundColor: AppTheme.surfaceSecondary,
                        side: BorderSide(color: AppTheme.borderSubtle),
                        selectedColor: AppTheme.emeraldGreen.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.emeraldGreen,
                        labelStyle: TextStyle(
                          color: _typeFilter == null
                              ? AppTheme.emeraldGreen
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() => _typeFilter = null);
                          _fetchTransactions();
                        },
                      ),
                      const SizedBox(width: 8),
                      // Expenses Chip
                      FilterChip(
                        label: const Text('Expenses Only'),
                        selected: _typeFilter == TransactionType.expense,
                        backgroundColor: AppTheme.surfaceSecondary,
                        side: BorderSide(color: AppTheme.borderSubtle),
                        selectedColor: AppTheme.tastefulRed.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.tastefulRed,
                        labelStyle: TextStyle(
                          color: _typeFilter == TransactionType.expense
                              ? AppTheme.tastefulRed
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() => _typeFilter = TransactionType.expense);
                          _fetchTransactions();
                        },
                      ),
                      const SizedBox(width: 8),
                      // Income Chip
                      FilterChip(
                        label: const Text('Money Added'),
                        selected: _typeFilter == TransactionType.income,
                        backgroundColor: AppTheme.surfaceSecondary,
                        side: BorderSide(color: AppTheme.borderSubtle),
                        selectedColor: AppTheme.emeraldGreen.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.emeraldGreen,
                        labelStyle: TextStyle(
                          color: _typeFilter == TransactionType.income
                              ? AppTheme.emeraldGreen
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (_) {
                          setState(() => _typeFilter = TransactionType.income);
                          _fetchTransactions();
                        },
                      ),
                    ],
                  ),
                ),

                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Categories'),
                          selected: _selectedCategoryId == null,
                          backgroundColor: AppTheme.surfaceSecondary,
                          side: BorderSide(color: AppTheme.borderSubtle),
                          selectedColor: AppTheme.emeraldGreen.withValues(alpha: 0.2),
                          checkmarkColor: AppTheme.emeraldGreen,
                          labelStyle: TextStyle(
                            color: _selectedCategoryId == null
                                ? AppTheme.emeraldGreen
                                : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedCategoryId = null);
                            _fetchTransactions();
                          },
                        ),
                        ..._categories.map((cat) {
                          final isSelected = _selectedCategoryId == cat.id;
                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: FilterChip(
                              avatar: Icon(cat.icon, size: 14, color: cat.color),
                              label: Text(cat.name),
                              selected: isSelected,
                              selectedColor: cat.color.withValues(alpha: 0.2),
                              checkmarkColor: cat.color,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                              onSelected: (_) {
                                setState(() {
                                  _selectedCategoryId = isSelected ? null : cat.id;
                                });
                                _fetchTransactions();
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],

                // Date filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDateChip('All Time', DateFilterOption.allTime),
                      const SizedBox(width: 8),
                      _buildDateChip('Today', DateFilterOption.today),
                      const SizedBox(width: 8),
                      _buildDateChip('This Week', DateFilterOption.thisWeek),
                      const SizedBox(width: 8),
                      _buildDateChip('This Month', DateFilterOption.thisMonth),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(_dateFilter == DateFilterOption.custom &&
                                _customDateRange != null
                            ? '${DateFormat('dd/MM').format(_customDateRange!.start)} - ${DateFormat('dd/MM').format(_customDateRange!.end)}'
                            : 'Custom Range'),
                        selected: _dateFilter == DateFilterOption.custom,
                        selectedColor: AppTheme.emeraldGreen.withValues(alpha: 0.2),
                        checkmarkColor: AppTheme.emeraldGreen,
                        labelStyle: TextStyle(
                          color: _dateFilter == DateFilterOption.custom
                              ? AppTheme.emeraldGreen
                              : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        onSelected: (_) => _pickCustomDateRange(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.emeraldGreen),
                  )
                : _transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No matching transactions found',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try adjusting your search terms or filters',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppTheme.emeraldGreen,
                        backgroundColor: AppTheme.card,
                        onRefresh: _fetchTransactions,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final tx = _transactions[index];
                            return TransactionTile(
                              transaction: tx,
                              onTap: () => _showTransactionDetails(tx),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChip(String label, DateFilterOption option) {
    final isSelected = _dateFilter == option;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      backgroundColor: AppTheme.surfaceSecondary,
      side: BorderSide(color: AppTheme.borderSubtle),
      selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      onSelected: (_) {
        setState(() => _dateFilter = option);
        _fetchTransactions();
      },
    );
  }
}
