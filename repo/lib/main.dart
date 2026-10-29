import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database/app_database.dart';
import 'screens/analytics_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/transactions_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.initTheme();

  runApp(const PocketPilotApp());
}

class PocketPilotApp extends StatelessWidget {
  const PocketPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemePreset>(
      valueListenable: AppTheme.currentThemeNotifier,
      builder: (context, currentPreset, _) {
        final isDark = currentPreset == AppThemePreset.obsidianDark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: AppTheme.background,
            systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          ),
        );

        return MaterialApp(
          title: 'PocketPilot',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.currentThemeData,
          home: const AppRootScreen(),
        );
      },
    );
  }
}

typedef BlackVaultApp = PocketPilotApp;

class AppRootScreen extends StatefulWidget {
  const AppRootScreen({super.key});

  @override
  State<AppRootScreen> createState() => _AppRootScreenState();
}

class _AppRootScreenState extends State<AppRootScreen> {
  bool _isLocked = false;
  bool _isCheckingLock = true;
  String? _expectedPinHash;

  @override
  void initState() {
    super.initState();
    _checkLockStatus();
  }

  Future<void> _checkLockStatus() async {
    final pinHash = await AppDatabase.instance.getSetting('app_pin_hash');
    if (mounted) {
      setState(() {
        _expectedPinHash = pinHash;
        _isLocked = pinHash != null && pinHash.isNotEmpty;
        _isCheckingLock = false;
      });
    }
  }

  void _onUnlocked() {
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLock) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    if (_isLocked && _expectedPinHash != null) {
      return PinLockScreen(
        expectedPinHash: _expectedPinHash!,
        onUnlocked: _onUnlocked,
      );
    }

    return const MainNavigationScaffold();
  }
}

class PinLockScreen extends StatefulWidget {
  final String expectedPinHash;
  final VoidCallback onUnlocked;

  const PinLockScreen({
    super.key,
    required this.expectedPinHash,
    required this.onUnlocked,
  });

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _enteredPin = '';
  String? _errorMessage;

  void _handleKeyTap(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _handleBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _verifyPin() {
    final enteredHash = (_enteredPin.hashCode ^ 0x5F3759DF).toString();
    if (enteredHash == widget.expectedPinHash) {
      widget.onUnlocked();
    } else {
      setState(() {
        _enteredPin = '';
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/images/pocketpilot_logo.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.borderSubtle),
                    ),
                    child: Icon(
                      Icons.lock_outline_rounded,
                      size: 36,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'PocketPilot Locked',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your 4-digit PIN to access records',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 32),

              // PIN Dot Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled
                          ? AppTheme.primaryColor
                          : AppTheme.surfaceSecondary,
                      border: Border.all(
                        color: isFilled
                            ? AppTheme.primaryColor
                            : AppTheme.borderSubtle,
                        width: 1.5,
                      ),
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: AppTheme.tastefulRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const Spacer(),

              // Numeric Keypad
              Column(
                children: [
                  for (var row in [
                    ['1', '2', '3'],
                    ['4', '5', '6'],
                    ['7', '8', '9'],
                  ])
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: row
                            .map((d) => _buildKey(d, () => _handleKeyTap(d)))
                            .toList(),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 72, height: 72),
                        _buildKey('0', () => _handleKeyTap('0')),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: IconButton(
                            icon: Icon(Icons.backspace_outlined,
                                color: AppTheme.textSecondary),
                            onPressed: _handleBackspace,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKey(String label, VoidCallback onTap) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.card,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;
  Key _refreshKey = UniqueKey();

  void _reloadAllData() {
    setState(() {
      _refreshKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _refreshKey,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            DashboardScreen(
              onNavigateToTransactions: () => setState(() => _currentIndex = 1),
              onNavigateToCategories: () => setState(() => _currentIndex = 3),
            ),
            const TransactionsScreen(),
            const AnalyticsScreen(),
            const CategoriesScreen(),
            SettingsScreen(onDataChanged: _reloadAllData),
          ],
        ),
        bottomNavigationBar: ValueListenableBuilder<AppThemePreset>(
          valueListenable: AppTheme.currentThemeNotifier,
          builder: (context, _, __) => Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              border: Border(top: BorderSide(color: AppTheme.borderSubtle, width: 1)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home'),
                    _buildNavItem(1, Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Records'),
                    _buildNavItem(2, Icons.insights_outlined, Icons.insights_rounded, 'Analytics'),
                    _buildNavItem(3, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Categories'),
                    _buildNavItem(4, Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  size: 22,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textMuted,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
