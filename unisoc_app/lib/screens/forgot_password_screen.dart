import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _message;

  Future<void> _requestToken() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final token = await auth.requestPasswordReset(_usernameController.text.trim());
    setState(() {
      _message = token == null ? 'Could not create reset request.' : 'Prototype reset token: $token';
      if (token != null && token.length > 20) _tokenController.text = token;
    });
  }

  Future<void> _resetPassword() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final success = await auth.resetPassword(_tokenController.text.trim(), _passwordController.text.trim());
    setState(() => _message = success ? 'Password reset successfully. You can now log in.' : 'Password reset failed.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Request a password reset token, then enter a new password. In a production system this token would be emailed.'),
          const SizedBox(height: 16),
          TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Username or email', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _requestToken, child: const Text('Request reset token')),
          const Divider(height: 32),
          TextField(controller: _tokenController, decoration: const InputDecoration(labelText: 'Reset token', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'New password', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _resetPassword, child: const Text('Reset password')),
          if (_message != null) Padding(padding: const EdgeInsets.only(top: 12), child: SelectableText(_message!)),
        ],
      ),
    );
  }
}
