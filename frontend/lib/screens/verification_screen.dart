import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class VerificationScreen extends StatefulWidget {
  static const routeName = '/verify';
  final String email;

  const VerificationScreen({super.key, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      debugPrint('VerificationScreen: Starting verification for ${widget.email}');
      await Provider.of<AuthProvider>(context, listen: false).verifyRegistration(
        widget.email,
        _codeController.text.trim(),
      );
      if (!mounted) return;
      
      debugPrint('VerificationScreen: Verification successful, updated AuthProvider state');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified! Logging you in...'), backgroundColor: Colors.green),
      );
      
      // Wait a tiny bit for the state to propagate if needed, then jump to home
      // Since AuthWrapper is the root 'home' widget, we can just clear the stack
      // or push replacement to HomeScreen directly.
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(HomeScreen.routeName, (route) => false);
        debugPrint('VerificationScreen: Navigating to HomeScreen and clearing stack');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email'), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 80, color: Colors.deepPurpleAccent),
              const SizedBox(height: 24),
              Text(
                'Enter the 6-digit code sent to\n${widget.email}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '123456',
                  prefixIcon: Icon(Icons.security),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8),
                maxLength: 6,
                validator: (val) => val!.length != 6 ? 'Enter 6-digit code' : null,
              ),
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (ctx, auth, _) => auth.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          ElevatedButton(
                            onPressed: _submit,
                            child: const Text('Verify & Login'),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () async {
                              try {
                                await auth.resendVerification(widget.email);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('New code sent!'), backgroundColor: Colors.green),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                                );
                              }
                            },
                            child: const Text('Resend Code'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
