import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../utils/app_theme.dart';

class SpendingProgressBar extends StatelessWidget {
  final int totalMoneyPaise;
  final int totalExpensesPaise;

  const SpendingProgressBar({
    super.key,
    required this.totalMoneyPaise,
    required this.totalExpensesPaise,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = CurrencyService.calculatePercentageSpent(
      totalMoneyPaise: totalMoneyPaise,
      totalExpensesPaise: totalExpensesPaise,
    );

    final isOverBudget =
        totalExpensesPaise > totalMoneyPaise && totalMoneyPaise > 0;
    final isZeroBudget = totalMoneyPaise <= 0;

    Color progressColor;
    if (isOverBudget) {
      progressColor = AppTheme.tastefulRed;
    } else if (percentage >= 80) {
      progressColor = const Color(0xFFF59E0B); // Amber warning
    } else {
      progressColor = AppTheme.emeraldGreen;
    }

    final clampedProgress = (percentage / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOverBudget
              ? AppTheme.tastefulRed.withValues(alpha: 0.5)
              : AppTheme.borderSubtle,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isOverBudget
                          ? Icons.warning_amber_rounded
                          : Icons.pie_chart_outline_rounded,
                      size: 16,
                      color: progressColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOverBudget ? 'Budget Exceeded!' : 'Spending Progress',
                    style: TextStyle(
                      color: isOverBudget
                          ? AppTheme.tastefulRed
                          : AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isZeroBudget
                      ? 'No Budget'
                      : '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: progressColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: isZeroBudget ? 0.0 : clampedProgress,
              backgroundColor: AppTheme.surfaceSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 9,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${CurrencyService.formatPaise(totalExpensesPaise)}',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Total: ${CurrencyService.formatPaise(totalMoneyPaise)}',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (isOverBudget) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: AppTheme.tastefulRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 14, color: AppTheme.tastefulRed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'You have overspent by ${CurrencyService.formatPaise(totalExpensesPaise - totalMoneyPaise)}.',
                      style: TextStyle(
                        color: AppTheme.tastefulRed,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
