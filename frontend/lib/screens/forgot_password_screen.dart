import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  static const routeName = '/forgot-password';
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _codeSent = false;
  Future<void> _requestToken() async {
    if (_emailController.text.isEmpty) return;
    try {
      await Provider.of<AuthProvider>(context, listen: false).requestPasswordReset(_emailController.text.trim());
      setState(() {
        _codeSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent! Please check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _resetPassword() async {
    if (_tokenController.text.isEmpty || _newPasswordController.text.isEmpty) return;
    try {
      await Provider.of<AuthProvider>(context, listen: false).resetPassword(
        _tokenController.text.trim(),
        _newPasswordController.text.trim(),
      );
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successful!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (!_codeSent) ...[
              const Text('Enter your email to receive a password reset token.'),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (ctx, auth, _) => auth.isLoading 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _requestToken, child: const Text('Send Reset Token')),
              ),
            ] else ...[
              const Text('Enter the token and your new password.'),
              const SizedBox(height: 16),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(labelText: 'Reset Token', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (ctx, auth, _) => auth.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(onPressed: _resetPassword, child: const Text('Reset Password')),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
