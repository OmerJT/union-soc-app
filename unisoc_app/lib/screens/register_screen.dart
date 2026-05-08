import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _upNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isAdmin = false;
  String? _error;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await auth.register(
      _usernameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
      _upNumberController.text.trim(),
      role: _isAdmin ? 'admin' : 'user',
    );
    if (!success) setState(() => _error = 'Registration failed. Check the details and try again.');
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6750A4),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.groups, size: 48, color: Color(0xFF6750A4)),
                  const SizedBox(height: 8),
                  const Text('Join UniSoc', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _isAdmin,
                    title: const Text('Register as society admin'),
                    subtitle: const Text('Admins do not need a UP number.'),
                    onChanged: (value) => setState(() => _isAdmin = value),
                  ),
                  TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: 'First Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: 'Last Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder())),
                  if (!_isAdmin) ...[
                    const SizedBox(height: 12),
                    TextField(controller: _upNumberController, decoration: const InputDecoration(labelText: 'UP Number (e.g. UP123456)', prefixIcon: Icon(Icons.badge), border: OutlineInputBorder())),
                  ],
                  const SizedBox(height: 12),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.account_circle), border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6750A4), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Create Account', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Already have an account? Login')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
