import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/transaction_model.dart';
import '../services/currency_service.dart';
import '../utils/app_theme.dart';

class AddMoneyDialog extends StatefulWidget {
  const AddMoneyDialog({super.key});

  @override
  State<AddMoneyDialog> createState() => _AddMoneyDialogState();
}

class _AddMoneyDialogState extends State<AddMoneyDialog> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController(text: 'Added Funds');
  final _notesController = TextEditingController();

  // Mode: 0 = Top up budget (add additional money), 1 = Set exact total money
  int _selectedMode = 0;
  bool _isSaving = false;
  int _currentTotalPaise = 0;
  int _currentExpensesPaise = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCurrentTotals();
  }

  Future<void> _fetchCurrentTotals() async {
    final overview = await AppDatabase.instance.getFinancialOverview();
    if (mounted) {
      setState(() {
        _currentTotalPaise = overview['total_money'] ?? 0;
        _currentExpensesPaise = overview['total_expenses'] ?? 0;
        _isLoading = false;
        // If current total is 0, default to "Set Total Budget" mode
        if (_currentTotalPaise == 0) {
          _selectedMode = 1;
          _titleController.text = 'Initial Budget Setup';
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _applyQuickAmount(int rupees) {
    _amountController.text = rupees.toString();
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    final inputPaise = CurrencyService.parseToPaise(_amountController.text);
    if (inputPaise == null || inputPaise <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than zero'),
          backgroundColor: AppTheme.tastefulRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().toIso8601String();

      if (_selectedMode == 0) {
        // TOP UP MODE: Add this additional money as income
        await AppDatabase.instance.insertTransaction(
          TransactionModel(
            type: TransactionType.income,
            amountPaise: inputPaise,
            title: _titleController.text.trim().isEmpty
                ? 'Added Funds'
                : _titleController.text.trim(),
            notes: _notesController.text.trim(),
            dateTime: now,
            createdAt: now,
          ),
        );
      } else {
        // SET TOTAL BUDGET MODE: Set exact total money
        await AppDatabase.instance.setTotalBudgetPaise(inputPaise);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating budget: $e'),
            backgroundColor: AppTheme.tastefulRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AlertDialog(
        backgroundColor: AppTheme.card,
        content: const SizedBox(
          height: 100,
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.emeraldGreen),
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.borderSubtle),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: AppTheme.emeraldGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Manage Budget',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Segmented Mode Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMode = 0;
                          _titleController.text = 'Added Funds';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedMode == 0
                              ? AppTheme.card
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          'Add Money (+)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedMode == 0
                                ? AppTheme.emeraldGreen
                                : AppTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMode = 1;
                          _titleController.text = 'Reset Budget Total';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedMode == 1
                              ? AppTheme.card
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          'Set Total Money',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _selectedMode == 1
                                ? AppTheme.emeraldGreen
                                : AppTheme.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Explanation header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Total Money:',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      Text(
                        CurrencyService.formatPaise(_currentTotalPaise),
                        style: TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Total Spent:',
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      Text(
                        CurrencyService.formatPaise(_currentExpensesPaise),
                        style: TextStyle(
                          color: AppTheme.tastefulRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Amount Input Field
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.emeraldGreen,
              ),
              decoration: InputDecoration(
                labelText: _selectedMode == 0
                    ? 'Amount to Add (₹)'
                    : 'Target Total Budget (₹)',
                prefixText: '₹ ',
                prefixStyle: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.emeraldGreen,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Quick Amount Chips
            Wrap(
              spacing: 8,
              children: [1000, 2000, 5000, 10000, 25000].map((rupees) {
                return ActionChip(
                  label: Text('+$rupees'),
                  backgroundColor: AppTheme.surfaceSecondary,
                  side: BorderSide(color: AppTheme.borderSubtle),
                  labelStyle: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  onPressed: () => _applyQuickAmount(rupees),
                );
              }).toList(),
            ),

            const SizedBox(height: 14),

            // Optional Description / Title
            TextField(
              controller: _titleController,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Label / Note',
                hintText: 'e.g. Salary, Pocket Money, Monthly Allowance',
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _selectedMode == 0 ? 'Add Funds' : 'Save Budget',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
