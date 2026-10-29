import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpilot/services/currency_service.dart';

void main() {
  group('PocketPilot Currency & Financial Calculation Tests', () {
    test('Converts Rupee decimal to integer paise precisely', () {
      expect(CurrencyService.rupeeToPaise(100.00), 10000);
      expect(CurrencyService.rupeeToPaise(250.50), 25050);
      expect(CurrencyService.rupeeToPaise(0.99), 99);
      expect(CurrencyService.rupeeToPaise(10000.00), 1000000);
    });

    test('Converts integer paise to Rupee decimal correctly', () {
      expect(CurrencyService.paiseToRupees(10000), 100.00);
      expect(CurrencyService.paiseToRupees(25050), 250.50);
      expect(CurrencyService.paiseToRupees(1000000), 10000.00);
    });

    test('Parses user rupee input safely to integer paise', () {
      expect(CurrencyService.parseToPaise('10000'), 1000000);
      expect(CurrencyService.parseToPaise('₹ 10,000.00'), 1000000);
      expect(CurrencyService.parseToPaise('250.50'), 25050);
      expect(CurrencyService.parseToPaise('1,25,000'), 12500000);

      // Rejects invalid inputs, negative numbers, or zero
      expect(CurrencyService.parseToPaise(''), null);
      expect(CurrencyService.parseToPaise('   '), null);
      expect(CurrencyService.parseToPaise('abc'), null);
      expect(CurrencyService.parseToPaise('-500'), null);
      expect(CurrencyService.parseToPaise('0'), null);
    });

    test('Formats rupees using standard Indian numbering system', () {
      // Small values
      expect(CurrencyService.formatPaise(0), '₹0.00');
      expect(CurrencyService.formatPaise(50000), '₹500.00');

      // Thousands (₹10,000.00)
      expect(CurrencyService.formatPaise(1000000), '₹10,000.00');

      // Lakhs (₹1,25,000.00)
      expect(CurrencyService.formatPaise(12500000), '₹1,25,000.00');

      // Negative values
      expect(CurrencyService.formatPaise(-25000), '-₹250.00');

      // Show sign parameter
      expect(CurrencyService.formatPaise(100000, showSign: true), '+₹1,000.00');
    });

    test('Calculates remaining balance formula accurately: Remaining = Total Money - Total Expenses', () {
      // Prompt required test workflow:
      // Initial budget: ₹10,000 (1,000,000 paise)
      // Expense: ₹250 (25,000 paise)
      // Remaining: ₹9,750 (975,000 paise)
      int totalMoney = 1000000;
      int totalExpenses = 25000;
      int remaining = CurrencyService.calculateRemainingPaise(
        totalMoneyPaise: totalMoney,
        totalExpensesPaise: totalExpenses,
      );
      expect(remaining, 975000);
      expect(CurrencyService.formatPaise(remaining), '₹9,750.00');

      // Adding ₹2,000 (200,000 paise)
      totalMoney += 200000;
      expect(totalMoney, 1200000); // ₹12,000

      // Remaining should be ₹11,750 (1,175,000 paise)
      remaining = CurrencyService.calculateRemainingPaise(
        totalMoneyPaise: totalMoney,
        totalExpensesPaise: totalExpenses,
      );
      expect(remaining, 1175000);
      expect(CurrencyService.formatPaise(remaining), '₹11,750.00');
    });

    test('Handles zero budget and division-by-zero safely for spending progress', () {
      // 0 budget, 0 expense
      final progressZero = CurrencyService.calculatePercentageSpent(
        totalMoneyPaise: 0,
        totalExpensesPaise: 0,
      );
      expect(progressZero, 0.0);
      expect(progressZero.isNaN, false);
      expect(progressZero.isInfinite, false);

      // 0 budget, positive expense (over budget)
      final progressOverZero = CurrencyService.calculatePercentageSpent(
        totalMoneyPaise: 0,
        totalExpensesPaise: 50000,
      );
      expect(progressOverZero, 100.0);

      // Normal budget: 2,500 spent out of 10,000 = 25.0%
      final progressNormal = CurrencyService.calculatePercentageSpent(
        totalMoneyPaise: 1000000,
        totalExpensesPaise: 250000,
      );
      expect(progressNormal, 25.0);
    });

    test('Overspending detection when expenses exceed budget', () {
      final totalMoney = 500000; // ₹5,000
      final totalExpenses = 750000; // ₹7,500
      final remaining = CurrencyService.calculateRemainingPaise(
        totalMoneyPaise: totalMoney,
        totalExpensesPaise: totalExpenses,
      );
      expect(remaining < 0, true);
      expect(remaining, -250000);
      expect(CurrencyService.formatPaise(remaining), '-₹2,500.00');
    });
  });
}
