import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../models/category_model.dart';
import '../services/currency_service.dart';
import '../utils/app_theme.dart';
import '../widgets/category_icon_selector.dart';
import '../widgets/confirm_dialog.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  List<CategoryModel> _categories = [];
  Map<int, int> _spendingPerCategory = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final categories = await AppDatabase.instance.getAllCategories();
      final breakdown = await AppDatabase.instance.getCategorySpendingBreakdown();

      final spendingMap = <int, int>{};
      for (final item in breakdown) {
        final catId = item['category_id'] as int;
        final totalPaise = item['total_paise'] as int;
        spendingMap[catId] = totalPaise;
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _spendingPerCategory = spendingMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openCategoryDialog([CategoryModel? existing]) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(
        existingCategory: existing,
        onSaved: _loadCategories,
      ),
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Category',
      message:
          'Are you sure you want to delete "${category.name}"?\n\nAll existing expenses in this category will be preserved and safely moved to "Uncategorized". No financial records will be lost.',
      confirmLabel: 'Delete Category',
    );

    if (confirmed && category.id != null) {
      await AppDatabase.instance.deleteCategory(category.id!);
      _loadCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "${category.name}" deleted. Expenses moved to Uncategorized.'),
            backgroundColor: AppTheme.card,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            tooltip: 'Add Category',
            icon: Icon(Icons.add, color: AppTheme.emeraldGreen),
            onPressed: () => _openCategoryDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.emeraldGreen),
            )
          : RefreshIndicator(
              color: AppTheme.emeraldGreen,
              backgroundColor: AppTheme.card,
              onRefresh: _loadCategories,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final totalSpentPaise = _spendingPerCategory[cat.id] ?? 0;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderSubtle),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Row(
                      children: [
                        // Category Icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cat.color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 22),
                        ),
                        const SizedBox(width: 14),

                        // Name & Default Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      cat.name,
                                      style: TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  if (cat.isDefault) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.surfaceSecondary,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: AppTheme.borderSubtle),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Spent: ${CurrencyService.formatPaise(totalSpentPaise)}',
                                style: TextStyle(
                                  color: totalSpentPaise > 0
                                      ? AppTheme.textSecondary
                                      : AppTheme.textMuted,
                                  fontSize: 12,
                                  fontWeight: totalSpentPaise > 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action Buttons: Edit and Delete
                        IconButton(
                          icon: Icon(Icons.edit_outlined, size: 18),
                          color: AppTheme.textSecondary,
                          tooltip: 'Edit Category',
                          onPressed: () => _openCategoryDialog(cat),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 18),
                          color: AppTheme.tastefulRed,
                          tooltip: 'Delete Category',
                          onPressed: () => _deleteCategory(cat),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Custom Category',
        onPressed: () => _openCategoryDialog(),
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}

class _CategoryFormDialog extends StatefulWidget {
  final CategoryModel? existingCategory;
  final VoidCallback onSaved;

  const _CategoryFormDialog({
    this.existingCategory,
    required this.onSaved,
  });

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _nameController = TextEditingController();
  late int _iconCode;
  late int _colorValue;
  bool _isSaving = false;

  bool get _isEditing => widget.existingCategory != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final cat = widget.existingCategory!;
      _nameController.text = cat.name;
      _iconCode = cat.iconCode;
      _colorValue = cat.colorValue;
    } else {
      _iconCode = AvailableCategoryIcons.icons.first.codePoint;
      _colorValue = AppTheme.categoryPalette.first.toARGB32();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: AppTheme.tastefulRed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now().toIso8601String();
      if (_isEditing) {
        final updated = widget.existingCategory!.copyWith(
          name: name,
          iconCode: _iconCode,
          colorValue: _colorValue,
        );
        await AppDatabase.instance.updateCategory(updated);
      } else {
        final newCategory = CategoryModel(
          name: name,
          iconCode: _iconCode,
          colorValue: _colorValue,
          isDefault: false,
          createdAt: now,
        );
        await AppDatabase.instance.insertCategory(newCategory);
      }

      widget.onSaved();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.tastefulRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              _isEditing ? 'Edit Category' : 'New Category',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),

            // Preview Badge
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(_colorValue).withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Color(_colorValue).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AvailableCategoryIcons.getIcon(_iconCode),
                      color: Color(_colorValue),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _nameController.text.trim().isEmpty
                          ? 'Category Preview'
                          : _nameController.text.trim(),
                      style: TextStyle(
                        color: Color(_colorValue),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name Input
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: AppTheme.textPrimary),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Category Name *',
                hintText: 'e.g., Gym, Subscriptions, Rent',
              ),
            ),
            const SizedBox(height: 16),

            // Color & Icon Selector
            CategoryIconSelector(
              selectedIconCode: _iconCode,
              selectedColorValue: _colorValue,
              onIconSelected: (code) => setState(() => _iconCode = code),
              onColorSelected: (val) => setState(() => _colorValue = val),
            ),
            const SizedBox(height: 20),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
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
                            _isEditing ? 'Save Changes' : 'Create Category',
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
