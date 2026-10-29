/// Handles all currency conversions, calculations, and formatting using integer paise.
/// 1 Rupee = 100 Paise.
/// Floating-point numbers are NEVER used for storing or accumulating monetary balances.
class CurrencyService {
  static const String currencySymbol = '₹';

  /// Converts a Rupee decimal amount (e.g. 100.50) to integer paise (10050).
  static int rupeeToPaise(double rupees) {
    return (rupees * 100).round();
  }

  /// Converts integer paise (e.g. 10050) to double rupees (100.50).
  static double paiseToRupees(int paise) {
    return paise / 100.0;
  }

  /// Parses user string input (e.g. "10,000.50" or "10000" or "₹ 500") into integer paise.
  /// Returns null if the input is invalid or negative/zero.
  static int? parseToPaise(String input) {
    if (input.trim().isEmpty) return null;

    // Remove any currency symbols, commas, or whitespace
    final cleaned = input.replaceAll('₹', '').replaceAll(',', '').trim();
    final value = double.tryParse(cleaned);
    if (value == null || value.isNaN || value.isInfinite) {
      return null;
    }
    if (value <= 0) {
      return null;
    }
    return (value * 100).round();
  }

  /// Formats integer paise into standard Indian currency format:
  /// Examples:
  ///   1000000 paise (₹10,000.00) -> "₹10,000.00"
  ///   12500000 paise (₹1,25,000.00) -> "₹1,25,000.00"
  ///   0 paise -> "₹0.00"
  ///   -50000 paise -> "-₹500.00"
  static String formatPaise(
    int paise, {
    bool includeDecimals = true,
    bool showSign = false,
  }) {
    final isNegative = paise < 0;
    final absPaise = paise.abs();
    final rupees = absPaise ~/ 100;
    final remainingPaise = absPaise % 100;

    // Indian Numbering format: last 3 digits, then groups of 2 digits
    final rupeesStr = rupees.toString();
    String formattedRupees = '';

    if (rupeesStr.length <= 3) {
      formattedRupees = rupeesStr;
    } else {
      final lastThree = rupeesStr.substring(rupeesStr.length - 3);
      final remaining = rupeesStr.substring(0, rupeesStr.length - 3);

      final buffer = StringBuffer();
      for (int i = 0; i < remaining.length; i++) {
        if (i > 0 && (remaining.length - i) % 2 == 0) {
          buffer.write(',');
        }
        buffer.write(remaining[i]);
      }
      formattedRupees = '${buffer.toString()},$lastThree';
    }

    final paiseStr = remainingPaise.toString().padLeft(2, '0');
    final amountFormatted = includeDecimals
        ? '$currencySymbol$formattedRupees.$paiseStr'
        : '$currencySymbol$formattedRupees';

    if (isNegative) {
      return '-$amountFormatted';
    } else if (showSign && paise > 0) {
      return '+$amountFormatted';
    }
    return amountFormatted;
  }

  /// Calculates percentage of budget spent safely.
  /// Handles zero or negative total budget without division-by-zero.
  /// Returns a value between 0.0 and 100.0 (or greater if overspent).
  static double calculatePercentageSpent({
    required int totalMoneyPaise,
    required int totalExpensesPaise,
  }) {
    if (totalMoneyPaise <= 0) {
      return totalExpensesPaise > 0 ? 100.0 : 0.0;
    }
    final percentage = (totalExpensesPaise / totalMoneyPaise) * 100.0;
    return percentage;
  }

  /// Calculates remaining balance in integer paise:
  /// Formula: Remaining = Total Money - Total Expenses
  static int calculateRemainingPaise({
    required int totalMoneyPaise,
    required int totalExpensesPaise,
  }) {
    return totalMoneyPaise - totalExpensesPaise;
  }
}
