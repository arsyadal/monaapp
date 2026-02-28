import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_provider.dart';
import 'main.dart'; // for kPrimary
import 'auth_screens.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = provider.isDarkMode;
    final currency = provider.currency;
    final usePin = provider.usePin;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : kBackground,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Settings
          _buildSettingsCard(
            isDark: isDark,
            title: 'Appearance',
            children: [
              SwitchListTile(
                title: Text('Dark Mode', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                value: isDark,
                activeColor: kPrimary,
                secondary: Icon(Icons.dark_mode_outlined, color: isDark ? Colors.white70 : Colors.black54),
                onChanged: (val) => context.read<AppProvider>().toggleTheme(val),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Currency Settings
          _buildSettingsCard(
            isDark: isDark,
            title: 'Localization',
            children: [
              ListTile(
                leading: Icon(Icons.attach_money_outlined, color: isDark ? Colors.white70 : Colors.black54),
                title: Text('Currency', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                trailing: DropdownButton<String>(
                  value: currency,
                  dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  items: ['Rp', '\$', '€', '£']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: isDark ? Colors.white : Colors.black))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) context.read<AppProvider>().setCurrency(val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Security Settings
          _buildSettingsCard(
            isDark: isDark,
            title: 'Security',
            children: [
              SwitchListTile(
                title: Text('PIN Lock', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text('Require PIN to open app', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12)),
                value: usePin,
                activeColor: kPrimary,
                secondary: Icon(Icons.lock_outline, color: isDark ? Colors.white70 : Colors.black54),
                onChanged: (val) {
                  if (val) {
                    _showPinSetup(context);
                  } else {
                    context.read<AppProvider>().disablePin();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade800,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () {
              context.read<AppProvider>().setToken(null);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showPinSetup(BuildContext context) {
    String pin = '';
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Setup 4-Digit PIN'),
        content: TextField(
          maxLength: 4,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter 4 digits'),
          onChanged: (val) => pin = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (pin.length == 4) {
                context.read<AppProvider>().setPin(pin);
                Navigator.pop(c);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required bool isDark, required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade600),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: isDark ? null : Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
