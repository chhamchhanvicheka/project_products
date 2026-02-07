import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef OnThemeChanged = void Function(ThemeMode);

class SettingsPage extends StatefulWidget {
  final OnThemeChanged onThemeChanged;

  const SettingsPage({super.key, required this.onThemeChanged});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late ThemeMode _selectedTheme;
  String? _userEmail;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _selectedTheme = ThemeMode.light;
    _userEmail = FirebaseAuth.instance.currentUser?.email;
    _loadTheme();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('username') ?? 'User';
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? ThemeMode.light.index;
    setState(() {
      _selectedTheme = ThemeMode.values[themeIndex];
    });
  }

  Future<void> _saveTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
  }

  void _onThemeChanged(ThemeMode? value) async {
    if (value == null) return;
    setState(() => _selectedTheme = value);
    await _saveTheme(value);
    widget.onThemeChanged(value);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _SettingsTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: t.textPrimary),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: t.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: t.surface,
      ),
      body: SingleChildScrollView(
        padding: t.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== USER INFO =====
            Card(
              elevation: 0,
              color: t.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radius),
                side: BorderSide(color: t.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: t.primary.withOpacity(0.12),
                      child: Text(
                        _userName.isNotEmpty
                            ? _userName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: t.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: t.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _userEmail ?? 'No email',
                            style: TextStyle(
                              fontSize: 13,
                              color: t.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ===== APPEARANCE SECTION =====
            Text(
              'Appearance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: t.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radius),
                side: BorderSide(color: t.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _ThemeOption(
                    icon: Icons.light_mode_rounded,
                    label: 'Light',
                    value: ThemeMode.light,
                    groupValue: _selectedTheme,
                    onChanged: _onThemeChanged,
                    theme: t,
                  ),
                  Divider(height: 1, color: t.border),
                  _ThemeOption(
                    icon: Icons.dark_mode_rounded,
                    label: 'Dark',
                    value: ThemeMode.dark,
                    groupValue: _selectedTheme,
                    onChanged: _onThemeChanged,
                    theme: t,
                  ),
                  Divider(height: 1, color: t.border),
                  _ThemeOption(
                    icon: Icons.settings_suggest_rounded,
                    label: 'System default',
                    value: ThemeMode.system,
                    groupValue: _selectedTheme,
                    onChanged: _onThemeChanged,
                    theme: t,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ===== ABOUT SECTION =====
            Text(
              'About',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: t.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radius),
                side: BorderSide(color: t.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info_outline, color: t.textMuted),
                    title: Text('Version',
                        style: TextStyle(color: t.textPrimary)),
                    trailing: Text('1.0.0',
                        style: TextStyle(color: t.textMuted, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ===== ACCOUNT SECTION =====
            Text(
              'Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: t.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(t.radius),
                side: BorderSide(color: t.border),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.red, size: 20),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Sign out from this account',
                  style: TextStyle(color: t.textMuted, fontSize: 12),
                ),
                trailing: Icon(Icons.chevron_right, color: t.textMuted),
                onTap: _logout,
              ),
            ),
          ],
        ),
      ),

      // ===== BOTTOM NAVIGATION =====
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2), label: 'Products'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/dashboard');
          } else if (index == 1) {
            Navigator.of(context).pushReplacementNamed('/products');
          }
        },
      ),
    );
  }
}

// -------------------- Theme Option Tile --------------------
class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode?> onChanged;
  final _SettingsTheme theme;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? theme.primary : theme.textMuted,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: theme.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.primary)
          : Icon(Icons.circle_outlined, color: theme.border),
      onTap: () => onChanged(value),
    );
  }
}

// -------------------- Settings Theme --------------------
class _SettingsTheme {
  final bool isDark;
  final Color primary;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final double radius;
  final EdgeInsets pagePadding;

  const _SettingsTheme({
    required this.isDark,
    required this.primary,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.radius,
    required this.pagePadding,
  });

  factory _SettingsTheme.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _SettingsTheme(
      isDark: isDark,
      primary: Colors.deepPurple,
      surface: isDark ? const Color(0xFF14141A) : Colors.white,
      border: isDark ? Colors.white12 : Colors.grey.shade200,
      textPrimary: isDark ? Colors.white : const Color(0xFF1C1C28),
      textMuted: isDark ? Colors.white70 : Colors.grey.shade600,
      radius: 12,
      pagePadding: const EdgeInsets.all(16),
    );
  }
}
