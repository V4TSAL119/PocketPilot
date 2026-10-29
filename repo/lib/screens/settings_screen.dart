import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/app_database.dart';
import '../utils/app_theme.dart';
import '../widgets/confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onDataChanged;

  const SettingsScreen({super.key, this.onDataChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPinLockEnabled = false;
  String? _savedPin;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final pinHash = await AppDatabase.instance.getSetting('app_pin_hash');
    if (mounted) {
      setState(() {
        _savedPin = pinHash;
        _isPinLockEnabled = pinHash != null && pinHash.isNotEmpty;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePinLock(bool enable) async {
    if (enable) {
      // Set new PIN
      final newPin = await _showPinDialog(title: 'Set 4-Digit Security PIN');
      if (newPin != null && newPin.length == 4) {
        final pinHash = (newPin.hashCode ^ 0x5F3759DF).toString();
        await AppDatabase.instance.setSetting('app_pin_hash', pinHash);
        setState(() {
          _isPinLockEnabled = true;
          _savedPin = pinHash;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('App PIN lock successfully enabled!'),
              backgroundColor: AppTheme.emeraldGreen,
            ),
          );
        }
      }
    } else {
      // Prompt for current PIN before disabling
      final enteredPin =
          await _showPinDialog(title: 'Enter Current PIN to Disable');
      if (enteredPin != null) {
        final enteredHash = (enteredPin.hashCode ^ 0x5F3759DF).toString();
        if (enteredHash == _savedPin) {
          await AppDatabase.instance.setSetting('app_pin_hash', '');
          setState(() {
            _isPinLockEnabled = false;
            _savedPin = null;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('PIN lock disabled.'),
                backgroundColor: AppTheme.card,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incorrect PIN. Cannot disable lock.'),
                backgroundColor: AppTheme.tastefulRed,
              ),
            );
          }
        }
      }
    }
  }

  Future<String?> _showPinDialog({required String title}) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Text(title,
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          autofocus: true,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '••••',
            hintStyle: TextStyle(color: AppTheme.textMuted),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().length == 4) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup() async {
    try {
      final jsonBackup = await AppDatabase.instance.exportBackupJson();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.borderSubtle),
          ),
          title: Row(
            children: [
              Icon(Icons.backup_outlined, color: AppTheme.emeraldGreen),
              const SizedBox(width: 8),
              Text(
                'Offline Backup Ready',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your complete SQLite financial records have been exported to encrypted offline JSON format.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: const Text(
                  '⚠ Warning: Keep your backup data safe. It contains your complete offline transaction records.',
                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy Backup Data'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonBackup));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Backup data copied to clipboard! Save it securely.'),
                    backgroundColor: AppTheme.emeraldGreen,
                  ),
                );
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppTheme.tastefulRed,
          ),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    final controller = TextEditingController();
    final jsonInput = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.borderSubtle),
        ),
        title: Text(
          'Restore from Backup',
          style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste your previously exported PocketPilot backup JSON below. This will overwrite current records with the backup data.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 5,
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontFamily: 'monospace'),
              decoration: const InputDecoration(
                hintText: '{"app": "PocketPilot", ...}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(context).pop(controller.text.trim());
              }
            },
            child: const Text('Restore Data'),
          ),
        ],
      ),
    );

    if (jsonInput != null && jsonInput.isNotEmpty) {
      final confirmed = await ConfirmDialog.show(
        context: context,
        title: 'Overwrite All Records?',
        message:
            'Restoring this backup will replace all current categories and transactions. This action cannot be reversed.',
        confirmLabel: 'Overwrite & Restore',
        isDestructive: true,
      );

      if (confirmed) {
        try {
          await AppDatabase.instance.restoreBackupJson(jsonInput);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Database successfully restored from backup!'),
                backgroundColor: AppTheme.emeraldGreen,
              ),
            );
          }
          widget.onDataChanged?.call();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to restore backup: $e'),
                backgroundColor: AppTheme.tastefulRed,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _resetAllData() async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Reset All Records?',
      message:
          'This will permanently delete ALL transactions, categories, and reset all app settings to default. Are you completely sure?',
      confirmLabel: 'Reset Everything',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await AppDatabase.instance.resetAllData();
        setState(() {
          _isPinLockEnabled = false;
          _savedPin = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All financial records have been reset.'),
              backgroundColor: AppTheme.tastefulRed,
            ),
          );
        }
        widget.onDataChanged?.call();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reset failed: $e'),
              backgroundColor: AppTheme.tastefulRed,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.emeraldGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings & Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ===================================================================
          // THEME & APPEARANCE (User Color Palette & Single-Option Toggle)
          // ===================================================================
          _buildSectionHeader('APPEARANCE & THEME'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderSubtle),
              boxShadow: AppTheme.cardShadow,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        switch (AppTheme.currentTheme) {
                          AppThemePreset.nordicNavy => Icons.water_outlined,
                          AppThemePreset.forestSage => Icons.eco_outlined,
                          AppThemePreset.obsidianDark => Icons.dark_mode_rounded,
                          AppThemePreset.warmAmber => Icons.wb_sunny_outlined,
                        },
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppTheme.currentThemeTitle,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Tap a theme card below to switch',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: [
                    _buildThemeCard(
                      title: 'Nordic Navy',
                      paletteName: '#F7F9FC',
                      isSelected: AppTheme.currentTheme == AppThemePreset.nordicNavy,
                      bgColor: const Color(0xFFF7F9FC),
                      primaryColor: const Color(0xFF142D4E),
                      accentColor: const Color(0xFF10B981),
                      onTap: () async {
                        await AppTheme.setPreset(AppThemePreset.nordicNavy);
                        setState(() {});
                      },
                    ),
                    _buildThemeCard(
                      title: 'Forest Sage',
                      paletteName: '#F7F6F0',
                      isSelected: AppTheme.currentTheme == AppThemePreset.forestSage,
                      bgColor: const Color(0xFFF7F6F0),
                      primaryColor: const Color(0xFF365747),
                      accentColor: const Color(0xFF84A98C),
                      onTap: () async {
                        await AppTheme.setPreset(AppThemePreset.forestSage);
                        setState(() {});
                      },
                    ),
                    _buildThemeCard(
                      title: 'Obsidian Dark',
                      paletteName: '#0B0F17',
                      isSelected: AppTheme.currentTheme == AppThemePreset.obsidianDark,
                      bgColor: const Color(0xFF0B0F17),
                      primaryColor: const Color(0xFF1E293B),
                      accentColor: const Color(0xFF10B981),
                      onTap: () async {
                        await AppTheme.setPreset(AppThemePreset.obsidianDark);
                        setState(() {});
                      },
                    ),
                    _buildThemeCard(
                      title: 'Warm Amber',
                      paletteName: '#FFFBF5',
                      isSelected: AppTheme.currentTheme == AppThemePreset.warmAmber,
                      bgColor: const Color(0xFFFFFBF5),
                      primaryColor: const Color(0xFF92400E),
                      accentColor: const Color(0xFFD97706),
                      onTap: () async {
                        await AppTheme.setPreset(AppThemePreset.warmAmber);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Security & Offline Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppTheme.emeraldGreen.withValues(alpha: 0.3)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.emeraldGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: AppTheme.emeraldGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Offline & Private',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'No cloud servers, no analytics, no network permissions. Your financial data stays exclusively on this device in private SQLite storage.',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Security Settings Group
          _buildSectionHeader('SECURITY & PROTECTION'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderSubtle),
              boxShadow: AppTheme.cardShadow,
            ),
            child: SwitchListTile(
              title: Text(
                'App PIN Lock',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Require 4-digit PIN when opening app',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              value: _isPinLockEnabled,
              activeThumbColor: AppTheme.emeraldGreen,
              onChanged: _togglePinLock,
            ),
          ),

          const SizedBox(height: 24),

          // Backup & Restore Group
          _buildSectionHeader('OFFLINE BACKUP & RESTORE'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.borderSubtle),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.file_download_outlined,
                      color: AppTheme.emeraldGreen),
                  title: Text(
                    'Export Local Backup',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Generate encrypted offline backup of transactions and categories',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  trailing: Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
                  onTap: _exportBackup,
                ),
                Divider(color: AppTheme.borderSubtle),
                ListTile(
                  leading: Icon(Icons.file_upload_outlined,
                      color: Color(0xFF3B82F6)),
                  title: Text(
                    'Restore from Backup',
                    style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Import a previous PocketPilot backup file',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                  trailing: Icon(Icons.chevron_right,
                      color: AppTheme.textSecondary),
                  onTap: _restoreBackup,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionHeader('DANGER ZONE'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: AppTheme.tastefulRed.withValues(alpha: 0.3)),
              boxShadow: AppTheme.cardShadow,
            ),
            child: ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: AppTheme.tastefulRed),
              title: Text(
                'Reset All Data',
                style: TextStyle(
                    color: AppTheme.tastefulRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'Permanently wipe all transactions and restore default categories',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
              onTap: _resetAllData,
            ),
          ),

          const SizedBox(height: 32),

          // About App Info
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/pocketpilot_logo.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'PocketPilot v1.0.0',
                  style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zero Trackers • Zero Cloud • True Privacy',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String paletteName,
    required bool isSelected,
    required Color bgColor,
    required Color primaryColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withValues(alpha: 0.12)
                : AppTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.borderSubtle,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Palette Preview Dots
                  Row(
                    children: [
                      Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: bgColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppTheme.borderSubtle, width: 1),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                paletteName,
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
    );
  }
}
