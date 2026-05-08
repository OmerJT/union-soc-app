import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _isLoading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final profile = await auth.getProfile();
    if (profile != null) {
      _emailController.text = profile['email'] ?? '';
      _firstNameController.text = profile['first_name'] ?? '';
      _lastNameController.text = profile['last_name'] ?? '';
      _notificationsEnabled = profile['notifications_enabled'] ?? true;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _message = null);
    final auth = Provider.of<AuthService>(context, listen: false);
    final payload = {
      'email': _emailController.text.trim(),
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'notifications_enabled': _notificationsEnabled,
    };
    if (_passwordController.text.trim().isNotEmpty) {
      payload['password'] = _passwordController.text.trim();
    }
    final success = await auth.updateProfile(payload);
    setState(() {
      _message = success ? 'Account settings updated.' : 'Could not update account settings.';
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Account Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Update your profile, password and global notification preference.'),
        const SizedBox(height: 16),
        TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last name', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'New password (optional)', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        SwitchListTile(
          value: _notificationsEnabled,
          title: const Text('Receive event notifications'),
          subtitle: const Text('Turn all society event notifications on or off.'),
          onChanged: (value) => setState(() => _notificationsEnabled = value),
        ),
        if (_message != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_message!, style: const TextStyle(color: Color(0xFF6750A4)))),
        ElevatedButton.icon(onPressed: _save, icon: const Icon(Icons.save), label: const Text('Save settings')),
      ],
    );
  }
}
