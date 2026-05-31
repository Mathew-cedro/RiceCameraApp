// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_notifier.dart';

// Settings screen that adjusts user exprience

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final theme = Theme.of(context);
    final isDark = themeNotifier.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account & Settings',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // Profile section
          _SectionHeader('PROFILE', theme),
          _Card(
            isDark: isDark,
            theme: theme,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    child: Icon(Icons.person_rounded,
                        color: theme.colorScheme.primary, size: 28),
                  ),
                  title: Text(
                    'Guest User',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Not signed in',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.45),
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () => _showComingSoon(context),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Appearance ────────────────────────────────
          _SectionHeader('APPEARANCE', theme),
          _Card(
            isDark: isDark,
            theme: theme,
            child: Column(
              children: [
                _ToggleTile(
                  icon: isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  label: 'Dark Mode',
                  description: isDark ? 'Currently dark' : 'Currently light',
                  value: isDark,
                  onChanged: (_) => themeNotifier.toggle(),
                  theme: theme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── About ─────────────────────────────────────
          _SectionHeader('ABOUT', theme),
          _Card(
            isDark: isDark,
            theme: theme,
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  label: 'App Version',
                  trailing: '1.0.0',
                  theme: theme,
                ),
                _Divider(theme),
                _InfoTile(
                  icon: Icons.analytics_outlined,
                  label: 'Analysis Method',
                  trailing: 'HSV Colour',
                  theme: theme,
                ),
                _Divider(theme),
                _InfoTile(
                  icon: Icons.storage_outlined,
                  label: 'History Storage',
                  trailing: 'Supabase',
                  theme: theme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Data ──────────────────────────────────────
          _SectionHeader('DATA', theme),
          _Card(
            isDark: isDark,
            theme: theme,
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.delete_sweep_outlined,
                  label: 'Clear All History',
                  color: const Color(0xFFF44336),
                  theme: theme,
                  onTap: () => _confirmClearHistory(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ── Footer note ───────────────────────────────
          Center(
            child: Text(
              'Palay Detector — built for Filipino farmers 🌾',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign-in coming in a future update.')),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text(
            'This will delete all scan records from Supabase. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Clear history coming in a future update.')),
              );
            },
            child:
                const Text('Clear', style: TextStyle(color: Color(0xFFF44336))),
          ),
        ],
      ),
    );
  }
}

// Reusable widgets
class _SectionHeader extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _SectionHeader(this.label, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final ThemeData theme;
  const _Card({required this.child, required this.isDark, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ThemeData theme;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: theme.colorScheme.onSurface)),
      subtitle: Text(description,
          style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.45))),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.primary,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;
  final ThemeData theme;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: theme.colorScheme.primary, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: theme.colorScheme.onSurface)),
      trailing: Text(trailing,
          style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.45))),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14, color: color)),
      onTap: onTap,
      trailing: Icon(Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurface.withOpacity(0.25)),
    );
  }
}

class _Divider extends StatelessWidget {
  final ThemeData theme;
  const _Divider(this.theme);

  @override
  Widget build(BuildContext context) {
    return Divider(
        color: theme.dividerColor, height: 1, indent: 52, endIndent: 0);
  }
}
