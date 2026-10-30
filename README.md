# 🚀 PocketPilot — Offline Money Manager

<div align="center">

### **Calm, Minimal & Privacy-First Personal Finance for Android**
*Track Expenses, Manage Monthly Bills & EMIs, and Keep Borrow & Lend Ledgers — 100% Offline.*

[![Flutter](https://img.shields.io/badge/Flutter-3.3%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://android.com)
[![Database](https://img.shields.io/badge/Database-SQLite%20(sqflite)-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://sqlite.org)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20Offline-10B981?style=for-the-badge&logo=shield&logoColor=white)](#privacy--offline-architecture)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

</div>

---

## 📖 Overview

**PocketPilot** is a modern, distraction-free money management application built with **Flutter** and **SQLite**. Designed with financial clarity and peace of mind at its core, PocketPilot eliminates intrusive ads, mandatory account sign-ups, and cloud tracking. 

Every single transaction, bill, and debt record remains safely encrypted on your device. Powered by an exact **integer-paise financial engine**, PocketPilot guarantees zero floating-point calculation errors.

---

## ✨ Key Features

### 1. 📊 Executive Home Dashboard
- **Available Balance at a Glance**: Clear display of current funds and total budget.
- **Balance Privacy Toggle**: Tap the eye icon (`👁`) to mask figures (`₹ ••••••`) in public spaces.
- **Integrated Budget Progress Bar**: Color-shifting progress indicator (Healthy Green ➔ Amber Warning at 80% ➔ Alert Red when overspent).
- **Monthly Inflow & Outflow**: Immediate comparison between money allocated and spent this month.
- **Contextual Due Soon Banner**: Subtle, non-intrusive alert that appears only when bills are overdue or approaching due date within 7 days.
- **Recent Activity**: Quick access to recent transactions with one-tap navigation to full records.

### 2. 🧾 Transactions & Records
- **Chronological Ledger**: Clean list of all expenses and money added.
- **Instant Search & Quick Filters**: Search by title or notes, and quickly switch between `All`, `Expenses`, and `Income`.
- **Advanced Filtering Bottom Sheet**: Filter transactions by specific Category or Custom Date Ranges without cluttering the screen.
- **Complete Transaction Inspection**: Edit, update, or safely delete records with instant automatic balance recalculation.

### 3. 📅 Bills, EMIs & Recurring Obligations
- **Comprehensive Tracking**: Manage House Rent, Bank/Vehicle EMIs, Credit Cards, Electricity, Water, Wi-Fi, Insurance, and Subscriptions.
- **Automatic Recurrence Engine**: Automatically rolls over to the next billing period upon payment, with intelligent month-end day clamping (e.g., Jan 31 ➔ Feb 28/29).
- **High-Contrast Payment Status**:
  - 🔴 **Tasteful Red**: Active remaining balance or overdue obligation.
  - 🟢 **Emerald Green**: Paid in full and cleared for the current cycle.
- **Partial Payment Support**: Record partial payments (e.g., pay ₹2,000 on a ₹5,000 bill; tracks remaining ₹3,000 with a progress bar).
- **Loan & EMI Management**: Track lender name, principal amount, loan tenure, interest rate, and complete EMI payment history.
- **Calendar & List Views**: Switch between chronological list view and day-by-day due date calendar.

### 4. 🤝 Borrow & Lend Tracker (Debts)
- **Two Distinct Ledgers**:
  - **Money to Collect**: Friends, colleagues, and family who owe you money.
  - **My Borrowings**: Personal loans and debts you need to repay.
- **Net Position Calculation**: Instant calculation of `Total to Collect − Total to Repay`.
- **Multi-Payment History**: Add partial repayments over time until the loan is marked as Settled.
- **Person Profiles**: View aggregated balances per individual without automated debt-offsetting that could cause confusion.
- **Reopen & Settle**: Reopen settled records or edit terms anytime.

### 5. 📈 Spending Analytics & Visual Trends
- **Monthly Run-Rate**: Shows this month's total spend, daily spending average, and highest expense category.
- **Category Donut Chart**: Visual distribution of where your money goes.
- **6-Month Historical Spending Bar Chart**: Track financial trends and spending seasonality month over month.

### 6. 🎨 Multi-Theme Engine
PocketPilot includes 4 hand-crafted, high-contrast themes matching modern design tokens:
- **Obsidian Dark** *(Default)*: Pure `#0B0B0B` OLED Black with Emerald Green accents.
- **Nordic Navy**: Crisp `#F7F9FC` executive navy canvas with cool mint highlights.
- **Forest Sage**: Organic pine `#365747` on natural sage paper `#F7F6F0`.
- **Warm Amber**: Earthy brown tones `#92400E` on `#FFFBF5` canvas.

### 7. 🔒 Security & Data Sovereignty
- **4-Digit App PIN Lock**: Protect your financial data from prying eyes on app launch.
- **100% Offline**: Zero external network calls, zero analytics SDKs, zero third-party servers.
- **JSON Backup & Restore**: Export full database state to encrypted JSON or restore previous backups in seconds.

---

## 🛠️ Technology Stack & Architecture

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Framework** | **Flutter 3.x (Dart 3.x)** | High-performance cross-platform mobile UI |
| **Database** | **SQLite (`sqflite`)** | Local relational database with versioned schema migrations (v1 ➔ v2 ➔ v3) |
| **Charts** | **`fl_chart`** | Smooth, interactive donut and bar charts |
| **Math Engine** | **`CurrencyService`** | Strict integer-paise calculations (avoids IEEE-754 decimal rounding drift) |
| **Storage** | **`shared_preferences`** | Persisting user theme preferences, PIN hashes, and privacy settings |
| **Design System** | **UI/UX Pro Max** | 48dp touch targets, semantic colors, and minimal cognitive load |

---

## 📁 Project Structure

```text
lib/
├── database/
│   └── app_database.dart          # SQLite schema, migrations (v1-v3), and CRUD queries
├── models/
│   ├── bill_model.dart            # Recurring bills & loan models
│   ├── bill_payment_model.dart    # Individual payment ledger for bills
│   ├── category_model.dart        # Custom categories with icons and colors
│   ├── debt_model.dart            # Borrow & lend records
│   ├── debt_repayment_model.dart  # Partial repayment history
│   └── transaction_model.dart     # Inflow & expense transactions
├── screens/
│   ├── dashboard_screen.dart      # Primary Home screen
│   ├── transactions_screen.dart   # All transaction records with filters
│   ├── bills_screen.dart          # Bills & EMIs dashboard
│   ├── bill_detail_screen.dart    # Detailed bill view & payment history
│   ├── add_edit_bill_screen.dart  # Form for recurring bills & loans
│   ├── borrow_lend_screen.dart    # Debts dashboard
│   ├── debt_detail_screen.dart    # Debt timeline & repayments
│   ├── add_edit_debt_screen.dart  # Form for lending/borrowing
│   ├── person_profile_screen.dart # Per-person loan summaries
│   ├── analytics_screen.dart      # Spending charts & statistics
│   ├── categories_screen.dart     # Category management
│   ├── more_screen.dart           # Consolidated settings & tools hub
│   ├── add_expense_screen.dart    # Expense entry form
│   └── add_money_screen.dart      # Budget top-up & set budget dialog
├── services/
│   └── currency_service.dart      # Indian numbering format & paise math
├── utils/
│   └── app_theme.dart             # 4 Color palettes, typography & theme tokens
├── widgets/
│   ├── bill_calendar_view.dart    # Due date visual calendar
│   ├── confirm_dialog.dart        # Reusable alert confirmation
│   ├── record_bill_payment_dialog.dart # Payment entry dialog
│   ├── spending_progress_bar.dart # Budget progress indicator
│   ├── theme_picker_sheet.dart    # Bottom sheet theme switcher
│   └── transaction_tile.dart      # Standard transaction list item
└── main.dart                      # App entry point & 4-tab bottom navigation
```

---

## ⚡ Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.3.0`)
- [Android Studio](https://developer.android.com/studio) or VS Code with Flutter extension
- Android SDK (`API 21` or higher)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/pocketpilot.git
   cd pocketpilot
   ```

2. **Install Flutter packages:**
   ```bash
   flutter pub get
   ```

3. **Run code analysis:**
   ```bash
   flutter analyze
   ```

4. **Run unit tests:**
   ```bash
   flutter test
   ```

5. **Run the app on an Android device or emulator:**
   ```bash
   flutter run
   ```

---

## 📦 Building the Release APK

To generate an optimized release APK for Android:

```bash
flutter build apk --release --no-tree-shake-icons
```

The compiled APK will be located at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Automated Testing

PocketPilot features an extensive test suite verifying:
- Precise integer paise to rupee conversions.
- Indian numbering system currency formatting (`₹1,50,000.00`).
- Remaining balance formulas (`Remaining = Budget − Expenses`).
- Borrow and lend partial repayment math and timeline validation.
- Recurring bill rollover and month-end clamping (Jan 31 ➔ Feb 28).
- Dynamic overdue status calculations.

Run all tests via:
```bash
flutter test test/calculations_test.dart
```

---

## 🛡️ Privacy & Offline Architecture

PocketPilot was built on the belief that **personal financial data belongs solely to the user**:
- **No Internet Permission**: The app operates entirely offline.
- **No Cloud Synchronization**: Records are stored in a local SQLite file (`pocketpilot.db`).
- **No Analytics / Telemetry**: No third-party tracking scripts, Firebase analytics, or ad networks.
- **Portability**: You can export your data to JSON anytime from **More ➔ Export JSON Backup**.

---

## 🤝 Contributing

Contributions, feature suggestions, and bug reports are welcome!
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<div align="center">
  <sub>Built with ❤️ using Flutter and Dart. Designed for mindful, stress-free money management.</sub>
</div>

