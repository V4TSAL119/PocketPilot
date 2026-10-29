import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/transaction_model.dart';
import '../services/currency_service.dart';
import '../utils/app_theme.dart';
import '../widgets/spending_progress_bar.dart';
import '../widgets/theme_picker_sheet.dart';
import '../widgets/transaction_tile.dart';
import 'add_expense_screen.dart';
import 'add_money_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToTransactions;
  final VoidCallback onNavigateToCategories;

  const DashboardScreen({
    super.key,
    required this.onNavigateToTransactions,
    required this.onNavigateToCategories,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  int _totalMoneyPaise = 0;
  int _totalExpensesPaise = 0;
  int _remainingBalancePaise = 0;
  List<TransactionModel> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final overview = await AppDatabase.instance.getFinancialOverview();
      final recent = await AppDatabase.instance.getTransactions(limit: 5);

      if (mounted) {
        setState(() {
          _totalMoneyPaise = overview['total_money'] ?? 0;
          _totalExpensesPaise = overview['total_expenses'] ?? 0;
          _remainingBalancePaise = overview['remaining_balance'] ?? 0;
          _recentTransactions = recent;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSetBudgetDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AddMoneyDialog(),
    );
    if (result == true) {
      _loadDashboardData();
    }
  }

  void _navigateToAddExpense() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddExpenseScreen(),
      ),
    );
    if (result == true) {
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.emeraldGreen),
        ),
      );
    }

    final isOverBudget = _remainingBalancePaise < 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/pocketpilot_logo.png',
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Icon(
                    Icons.flight_takeoff_rounded,
                    color: AppTheme.emeraldGreen,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PocketPilot',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Offline Money Manager',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Change Theme',
            icon: const Icon(Icons.palette_outlined, size: 22),
            onPressed: () => ThemePickerSheet.show(context),
          ),
          IconButton(
            tooltip: 'Set / Top-Up Budget',
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 22),
            onPressed: _showSetBudgetDialog,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, size: 22),
            onPressed: _loadDashboardData,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.emeraldGreen,
        backgroundColor: AppTheme.card,
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===============================================================
              // EXECUTIVE HERO BALANCE CARD
              // ===============================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: switch (AppTheme.currentTheme) {
                      AppThemePreset.obsidianDark => const [
                          Color(0xFF151E2E),
                          Color(0xFF0F1724),
                        ],
                      AppThemePreset.forestSage => const [
                          Color(0xFF365747),
                          Color(0xFF243B30),
                        ],
                      AppThemePreset.nordicNavy => const [
                          Color(0xFF142D4E),
                          Color(0xFF0E223D),
                        ],
                      AppThemePreset.warmAmber => const [
                          Color(0xFF92400E),
                          Color(0xFF78350F),
                        ],
                    },
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isOverBudget
                        ? AppTheme.tastefulRed.withValues(alpha: 0.6)
                        : (AppTheme.isDark
                            ? const Color(0x3310B981)
                            : const Color(0x33FFFFFF)),
                    width: 1.2,
                  ),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Status badge pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isOverBudget
                                ? AppTheme.tastefulRed.withValues(alpha: 0.2)
                                : AppTheme.emeraldGreen.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isOverBudget
                                  ? AppTheme.tastefulRed
                                  : AppTheme.emeraldGreen,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isOverBudget
                                      ? AppTheme.tastefulRed
                                      : AppTheme.emeraldGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOverBudget
                                    ? 'OVERSPENT'
                                    : 'REMAINING BALANCE',
                                style: TextStyle(
                                  color: isOverBudget
                                      ? AppTheme.tastefulRed
                                      : AppTheme.emeraldGreen,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Edit budget action button
                        InkWell(
                          onTap: _showSetBudgetDialog,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.edit, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Budget',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        CurrencyService.formatPaise(_remainingBalancePaise),
                        style: TextStyle(
                          color: isOverBudget
                              ? AppTheme.tastefulRed
                              : Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Money',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                CurrencyService.formatPaise(_totalMoneyPaise),
                                style: TextStyle(
                                  color: AppTheme.emeraldGreen,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Spent',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                CurrencyService.formatPaise(
                                    _totalExpensesPaise),
                                style: const TextStyle(
                                  color: Color(0xFFF87171),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===============================================================
              // SPENDING PROGRESS BAR CARD
              // ===============================================================
              SpendingProgressBar(
                totalMoneyPaise: _totalMoneyPaise,
                totalExpensesPaise: _totalExpensesPaise,
              ),

              const SizedBox(height: 22),

              // ===============================================================
              // QUICK ACTIONS GRID
              // ===============================================================
              Text(
                'Quick Actions',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      title: 'Add Expense',
                      subtitle: 'Record spend',
                      icon: Icons.remove_circle_outline_rounded,
                      color: AppTheme.tastefulRed,
                      onTap: _navigateToAddExpense,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionBtn(
                      title: 'Add Money',
                      subtitle: 'Deposit / budget',
                      icon: Icons.add_circle_outline_rounded,
                      color: AppTheme.emeraldGreen,
                      onTap: _showSetBudgetDialog,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionBtn(
                      title: 'Categories',
                      subtitle: 'Manage tags',
                      icon: Icons.grid_view_rounded,
                      color: const Color(0xFF3B82F6),
                      onTap: widget.onNavigateToCategories,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionBtn(
                      title: 'All Records',
                      subtitle: 'History & export',
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF8B5CF6),
                      onTap: widget.onNavigateToTransactions,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ===============================================================
              // RECENT TRANSACTIONS
              // ===============================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (_recentTransactions.isNotEmpty)
                    TextButton(
                      onPressed: widget.onNavigateToTransactions,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              color: AppTheme.isDark
                                  ? AppTheme.accentColor
                                  : AppTheme.primaryColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 11,
                            color: AppTheme.isDark
                                ? AppTheme.accentColor
                                : AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_recentTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.borderSubtle),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSecondary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_outlined,
                          size: 32,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No transactions recorded yet',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap "Add Expense" or "Add Money" above to begin tracking your finances.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentTransactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tx = _recentTransactions[index];
                    return TransactionTile(
                      transaction: tx,
                      onTap: widget.onNavigateToTransactions,
                    );
                  },
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Expense',
        backgroundColor:
            AppTheme.isDark ? AppTheme.accentColor : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: _navigateToAddExpense,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  Widget _buildActionBtn({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
