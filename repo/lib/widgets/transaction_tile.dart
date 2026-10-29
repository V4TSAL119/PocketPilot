import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../services/currency_service.dart';
import '../utils/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.isExpense;
    final date = transaction.parsedDateTime;
    final formattedDate = DateFormat('dd MMM, hh:mm a').format(date);

    final amountColor =
        isExpense ? AppTheme.tastefulRed : AppTheme.emeraldGreen;
    final prefix = isExpense ? '-' : '+';
    final formattedAmount =
        '$prefix${CurrencyService.formatPaise(transaction.amountPaise.abs())}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderSubtle),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              // Category / Type Icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: transaction.displayColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: transaction.displayColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Icon(
                  transaction.displayIcon,
                  color: transaction.displayColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),

              // Title and category / date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isExpense && transaction.categoryName != null) ...[
                          Text(
                            transaction.categoryName!,
                            style: TextStyle(
                              color: transaction.displayColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppTheme.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          formattedDate,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formattedAmount,
                    style: TextStyle(
                      color: amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (transaction.notes != null &&
                      transaction.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.notes,
                        size: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
