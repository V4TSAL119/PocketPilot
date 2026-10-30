import 'package:flutter_test/flutter_test.dart';
import 'package:pocketpilot/models/debt_model.dart';
import 'package:pocketpilot/models/debt_repayment_model.dart';
import 'package:pocketpilot/models/bill_model.dart';
import 'package:pocketpilot/services/currency_service.dart';

void main() {
  group('PocketPilot Currency & Financial Calculation Tests', () {
    test('Converts Rupee decimal to integer paise precisely', () {
      expect(CurrencyService.rupeeToPaise(100.00), 10000);
      expect(CurrencyService.rupeeToPaise(250.50), 25050);
      expect(CurrencyService.rupeeToPaise(0.99), 99);
      expect(CurrencyService.rupeeToPaise(10000.00), 1000000);
      expect(CurrencyService.rupeesToPaise(100), 10000);
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
      final progressZero = CurrencyService.calculatePercentageSpent(
        totalMoneyPaise: 0,
        totalExpensesPaise: 0,
      );
      expect(progressZero, 0.0);
      expect(progressZero.isNaN, false);
      expect(progressZero.isInfinite, false);

      final progressOverZero = CurrencyService.calculatePercentageSpent(
        totalMoneyPaise: 0,
        totalExpensesPaise: 50000,
      );
      expect(progressOverZero, 100.0);

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

  group('PocketPilot Borrow & Lend Tracker Calculation Tests', () {
    test('Section 3: Lending calculation (Rahul owes me ₹5,000, repaid ₹2,000, outstanding ₹3,000)', () {
      final now = DateTime.now().toIso8601String();
      final lendRecord = DebtModel(
        id: 1,
        type: DebtType.lend,
        personName: 'Rahul',
        amountPaise: 500000, // ₹5,000
        startDate: now,
        dueDate: DateTime.now().add(const Duration(days: 10)).toIso8601String(),
        totalRepaidPaise: 200000, // ₹2,000 repaid
        createdAt: now,
        updatedAt: now,
      );

      expect(lendRecord.isLend, true);
      expect(lendRecord.isBorrow, false);
      expect(lendRecord.originalAmountInRupees, 5000.0);
      expect(lendRecord.totalRepaidInRupees, 2000.0);
      expect(lendRecord.outstandingPaise, 300000); // ₹3,000 outstanding
      expect(lendRecord.outstandingInRupees, 3000.0);
      expect(lendRecord.status, DebtStatus.partiallyRepaid);
      expect(lendRecord.statusLabel, 'Partially Repaid');
      expect(lendRecord.repaymentProgress, 0.4); // 40% repaid
    });

    test('Section 3 & 5: Lending record full settlement', () {
      final now = DateTime.now().toIso8601String();
      final settledRecord = DebtModel(
        id: 1,
        type: DebtType.lend,
        personName: 'Rahul',
        amountPaise: 500000, // ₹5,000
        startDate: now,
        totalRepaidPaise: 500000, // ₹5,000 repaid
        isSettled: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(settledRecord.outstandingPaise, 0);
      expect(settledRecord.status, DebtStatus.settled);
      expect(settledRecord.statusLabel, 'Settled');
      expect(settledRecord.repaymentProgress, 1.0); // 100% repaid
      expect(settledRecord.isOverdue, false); // A fully settled record is NEVER overdue
    });

    test('Section 4: Borrowing calculation (Amit lent me ₹10,000, repaid ₹3,000, outstanding ₹7,000)', () {
      final now = DateTime.now().toIso8601String();
      final borrowRecord = DebtModel(
        id: 2,
        type: DebtType.borrow,
        personName: 'Amit',
        amountPaise: 1000000, // ₹10,000
        startDate: now,
        totalRepaidPaise: 300000, // ₹3,000
        interestRate: 0.0,
        createdAt: now,
        updatedAt: now,
      );

      expect(borrowRecord.isBorrow, true);
      expect(borrowRecord.isLend, false);
      expect(borrowRecord.outstandingPaise, 700000); // ₹7,000
      expect(borrowRecord.outstandingInRupees, 7000.0);
      expect(borrowRecord.status, DebtStatus.partiallyRepaid);
      expect(borrowRecord.repaymentProgress, 0.3); // 30%
    });

    test('Section 5: Multi-repayment timeline validation', () {
      final now = DateTime.now().toIso8601String();
      final repayments = [
        DebtRepaymentModel(
          id: 1,
          debtId: 1,
          amountPaise: 100000, // ₹1,000
          dateTime: now,
          notes: 'First repayment',
          createdAt: now,
        ),
        DebtRepaymentModel(
          id: 2,
          debtId: 1,
          amountPaise: 50000, // ₹500
          dateTime: now,
          notes: 'Second repayment',
          createdAt: now,
        ),
        DebtRepaymentModel(
          id: 3,
          debtId: 1,
          amountPaise: 150000, // ₹1,500
          dateTime: now,
          notes: 'Third repayment',
          createdAt: now,
        ),
      ];

      final totalRepaid = repayments.fold<int>(0, (sum, r) => sum + r.amountPaise);
      expect(totalRepaid, 300000); // ₹3,000

      final originalAmount = 500000; // ₹5,000
      final outstanding = (originalAmount - totalRepaid).clamp(0, originalAmount);
      expect(outstanding, 200000); // ₹2,000
      expect(CurrencyService.formatPaise(outstanding), '₹2,000.00');
    });

    test('Section 6: Separate debts between same person are NOT auto-offset', () {
      // Rahul owes me ₹5,000 (Lend)
      const rahulOwesMePaise = 500000;
      // I owe Rahul ₹2,000 (Borrow)
      const iOweRahulPaise = 200000;

      // Debts remain distinct
      expect(rahulOwesMePaise, 500000);
      expect(iOweRahulPaise, 200000);

      // Net position for display only
      const netPositionPaise = rahulOwesMePaise - iOweRahulPaise;
      expect(netPositionPaise, 300000); // ₹3,000 net receivable
      expect(CurrencyService.formatPaise(netPositionPaise), '₹3,000.00');
    });

    test('Section 7: Dynamic overdue status calculation', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5)).toIso8601String();
      final futureDate = DateTime.now().add(const Duration(days: 5)).toIso8601String();

      // Past due date with balance -> OVERDUE
      final overdueRecord = DebtModel(
        id: 3,
        type: DebtType.lend,
        personName: 'Karan',
        amountPaise: 500000,
        startDate: DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
        dueDate: pastDate,
        totalRepaidPaise: 100000,
        isSettled: false,
        createdAt: pastDate,
        updatedAt: pastDate,
      );
      expect(overdueRecord.isOverdue, true);
      expect(overdueRecord.status, DebtStatus.overdue);

      // Future due date -> ACTIVE or PARTIALLY REPAID (NOT overdue)
      final activeRecord = DebtModel(
        id: 4,
        type: DebtType.lend,
        personName: 'Karan',
        amountPaise: 500000,
        startDate: DateTime.now().toIso8601String(),
        dueDate: futureDate,
        totalRepaidPaise: 0,
        isSettled: false,
        createdAt: pastDate,
        updatedAt: pastDate,
      );
      expect(activeRecord.isOverdue, false);
      expect(activeRecord.status, DebtStatus.active);

      // Past due date BUT marked settled -> NEVER OVERDUE
      final settledPastRecord = overdueRecord.copyWith(
        isSettled: true,
        totalRepaidPaise: 500000,
      );
      expect(settledPastRecord.isOverdue, false);
      expect(settledPastRecord.status, DebtStatus.settled);
    });
   });

  group('PocketPilot Bills, EMIs & Recurring Payments Tests', () {
    test('Monthly Rent obligation and amount formatting', () {
      final now = DateTime.now().toIso8601String();
      final rent = BillModel(
        id: 1,
        name: 'House Rent',
        category: 'Rent',
        amountPaise: 800000, // ₹8,000
        frequency: 'monthly',
        dueDate: now,
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(rent.amountInRupees, 8000.0);
      expect(rent.formattedAmount, '₹8,000.00');
      expect(rent.remainingInCyclePaise, 800000);
      expect(rent.isRecurring, true);
    });

    test('Partial bill payment calculation (₹5,000 bill, ₹2,000 paid -> ₹3,000 remaining, 40% progress)', () {
      final now = DateTime.now().toIso8601String();
      final bill = BillModel(
        id: 2,
        name: 'Electricity Bill',
        category: 'Electricity',
        amountPaise: 500000, // ₹5,000
        dueDate: now,
        startDate: now,
        totalPaidInCurrentCyclePaise: 200000, // ₹2,000 paid
        createdAt: now,
        updatedAt: now,
      );

      expect(bill.remainingInCyclePaise, 300000); // ₹3,000 remaining
      expect(bill.remainingInCycleInRupees, 3000.0);
      expect(bill.formattedRemainingAmount, '₹3,000.00');
      expect(bill.paymentProgress, 0.4); // 40%
      expect(bill.computedStatus, BillStatus.partiallyPaid);
      expect(bill.statusLabel, 'Partially Paid');
    });

    test('Full bill payment marks status as paid with 100% progress and 0 remaining', () {
      final now = DateTime.now().toIso8601String();
      final bill = BillModel(
        id: 3,
        name: 'Wi-Fi Broadband',
        category: 'Internet',
        amountPaise: 79900, // ₹799
        dueDate: now,
        startDate: now,
        totalPaidInCurrentCyclePaise: 79900,
        createdAt: now,
        updatedAt: now,
      );

      expect(bill.remainingInCyclePaise, 0);
      expect(bill.paymentProgress, 1.0);
      expect(bill.computedStatus, BillStatus.paid);
      expect(bill.statusLabel, 'Paid');
      expect(bill.dueStatusDisplay, 'Paid for this cycle');
    });

    test('Monthly recurrence due date calculation clamps month-end days correctly (e.g. Jan 31 -> Feb 28)', () {
      final jan31 = DateTime(2026, 1, 31);
      final nextFeb = BillModel.computeNextDueDate(jan31, 'monthly', dueDay: 31);
      expect(nextFeb.year, 2026);
      expect(nextFeb.month, 2);
      expect(nextFeb.day, 28); // Feb 28 in 2026 (non-leap year)

      final feb28 = DateTime(2026, 2, 28);
      final nextMar = BillModel.computeNextDueDate(feb28, 'monthly', dueDay: 31);
      expect(nextMar.year, 2026);
      expect(nextMar.month, 3);
      expect(nextMar.day, 31); // Mar 31

      final dec15 = DateTime(2026, 12, 15);
      final nextJan = BillModel.computeNextDueDate(dec15, 'monthly', dueDay: 15);
      expect(nextJan.year, 2027);
      expect(nextJan.month, 1);
      expect(nextJan.day, 15);
    });

    test('Weekly, Quarterly and Yearly next due date calculations', () {
      final base = DateTime(2026, 5, 10);

      final weeklyNext = BillModel.computeNextDueDate(base, 'weekly');
      expect(weeklyNext, DateTime(2026, 5, 17));

      final quarterlyNext = BillModel.computeNextDueDate(base, 'quarterly');
      expect(quarterlyNext, DateTime(2026, 8, 10));

      final yearlyNext = BillModel.computeNextDueDate(base, 'yearly');
      expect(yearlyNext, DateTime(2027, 5, 10));
    });

    test('Loan EMI tracking with principal balance', () {
      final now = DateTime.now().toIso8601String();
      final loan = BillModel(
        id: 4,
        name: 'SBI Car Loan',
        category: 'Loan / EMI',
        amountPaise: 850000, // ₹8,500 EMI
        isLoan: true,
        lenderName: 'State Bank of India',
        originalLoanAmountPaise: 50000000, // ₹5,00,000 original
        outstandingPrincipalPaise: 42000000, // ₹4,20,000 outstanding
        interestRate: 8.5,
        tenureMonths: 60,
        dueDate: now,
        startDate: now,
        createdAt: now,
        updatedAt: now,
      );

      expect(loan.isLoan, true);
      expect(loan.amountInRupees, 8500.0);
      expect(CurrencyService.paiseToRupees(loan.outstandingPrincipalPaise!), 420000.0);
      expect(loan.interestRate, 8.5);
      expect(loan.tenureMonths, 60);
    });

    test('Dynamic overdue status detection: unpaid past due is overdue, paid is never overdue', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 4)).toIso8601String();
      final now = DateTime.now().toIso8601String();

      final overdueBill = BillModel(
        id: 5,
        name: 'Gas Cylinder',
        category: 'Gas',
        amountPaise: 95000,
        dueDate: pastDate,
        startDate: now,
        totalPaidInCurrentCyclePaise: 0,
        createdAt: now,
        updatedAt: now,
      );
      expect(overdueBill.computedStatus, BillStatus.overdue);
      expect(overdueBill.statusLabel, 'Overdue');

      final paidBill = overdueBill.copyWith(
        status: 'paid',
        totalPaidInCurrentCyclePaise: 95000,
      );
      expect(paidBill.computedStatus, BillStatus.paid);
      expect(paidBill.statusLabel, 'Paid');
    });
  });
}
