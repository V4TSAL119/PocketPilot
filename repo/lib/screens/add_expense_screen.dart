import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../services/currency_service.dart';
import '../utils/app_theme.dart';
import '../widgets/confirm_dialog.dart';

class AddExpenseScreen extends StatefulWidget {
  final TransactionModel? initialExpense;

  const AddExpenseScreen({super.key, this.initialExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEditing => widget.initialExpense != null;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  Future<void> _initFields() async {
    final categories = await AppDatabase.instance.getAllCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;

      if (_isEditing) {
        final exp = widget.initialExpense!;
        _titleController.text = exp.title;
        _amountController.text = CurrencyService.paiseToRupees(exp.amountPaise).toStringAsFixed(2);
        _notesController.text = exp.notes ?? '';
        _selectedDateTime = exp.parsedDateTime;

        if (exp.categoryId != null) {
          _selectedCategory = categories.firstWhere(
            (c) => c.id == exp.categoryId,
            orElse: () => categories.first,
          );
        } else if (categories.isNotEmpty) {
          _selectedCategory = categories.first;
        }
      } else if (categories.isNotEmpty) {
        _selectedCategory = categories.first;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: AppTheme.currentThemeData,
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: AppTheme.currentThemeData,
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveExpense() async {
    if (_isSaving) return; // Prevent double tap
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an expense category'),
          backgroundColor: AppTheme.tastefulRed,
        ),
      );
      return;
    }

    final amountPaise = CurrencyService.parseToPaise(_amountController.text);
    if (amountPaise == null || amountPaise <= 0) {
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
      if (_isEditing) {
        final updated = widget.initialExpense!.copyWith(
          title: _titleController.text.trim(),
          amountPaise: amountPaise,
          categoryId: _selectedCategory!.id,
          notes: _notesController.text.trim(),
          dateTime: _selectedDateTime.toIso8601String(),
        );
        await AppDatabase.instance.updateTransaction(updated);
      } else {
        final newExpense = TransactionModel(
          type: TransactionType.expense,
          amountPaise: amountPaise,
          categoryId: _selectedCategory!.id,
          title: _titleController.text.trim(),
          notes: _notesController.text.trim(),
          dateTime: _selectedDateTime.toIso8601String(),
          createdAt: now,
        );
        await AppDatabase.instance.insertTransaction(newExpense);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expense: $e'),
            backgroundColor: AppTheme.tastefulRed,
          ),
        );
      }
    }
  }

  Future<void> _deleteExpense() async {
    if (!_isEditing) return;

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Expense',
      message: 'Are you sure you want to delete this expense? This action will immediately restore your balance.',
      confirmLabel: 'Delete Expense',
    );

    if (confirmed) {
      await AppDatabase.instance.deleteTransaction(widget.initialExpense!.id!);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.emeraldGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
        actions: [
          if (_isEditing)
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: AppTheme.tastefulRed),
              onPressed: _deleteExpense,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount Input Field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AMOUNT (₹)',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: !_isEditing,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.tastefulRed,
                      ),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.tastefulRed,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter an expense amount';
                        }
                        final paise = CurrencyService.parseToPaise(val);
                        if (paise == null || paise <= 0) {
                          return 'Enter a valid amount greater than zero';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Title / Description
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Expense Title *',
                  hintText: 'e.g., Grocery Shopping, Taxi fare, Dinner',
                  prefixIcon: Icon(Icons.edit_note, color: AppTheme.textSecondary),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Title cannot be empty';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Category Selector
              Text(
                'Select Category *',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_categories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No categories found. Please create one in Categories screen.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                )
              else
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory?.id == cat.id;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 82,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cat.color.withValues(alpha: 0.18)
                                : AppTheme.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? cat.color : AppTheme.borderSubtle,
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat.icon,
                                color: isSelected ? cat.color : AppTheme.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // Date & Time Picker Tile
              InkWell(
                onTap: _pickDateTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: AppTheme.textSecondary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date & Time',
                              style: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy, hh:mm a').format(_selectedDateTime),
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Optional Notes
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Optional Notes',
                  hintText: 'Add payment method, invoice number, or details',
                  prefixIcon: Icon(Icons.description_outlined, color: AppTheme.textSecondary),
                ),
              ),

              const SizedBox(height: 32),

              // Submit / Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emeraldGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSaving ? null : _saveExpense,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Update Expense' : 'Save Expense',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
