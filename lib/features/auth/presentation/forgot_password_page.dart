import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/auth_repository.dart';
import '../../data/supabase_auth_repository.dart';

class ForgotPasswordPage extends StatefulWidget {
  final AuthRepository? authRepository;
  const ForgotPasswordPage({super.key, this.authRepository});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  AuthRepository get _repo => widget.authRepository ?? SupabaseAuthRepository();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      await _repo.resetPassword(_emailCtrl.text.trim());
      if (!mounted) return;
      setState(() => _message = 'If your email exists, a reset link was sent.');
    } on AuthException catch (e) {
      setState(() => _message = e.message);
    } catch (_) {
      setState(() => _message = 'Unable to send reset email. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('forgot-email'),
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  final emailRegex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
                  if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (_message != null) Text(_message!, key: const Key('forgot-message')),
              ElevatedButton(
                key: const Key('forgot-submit'),
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : const Text('Send reset email'),
              ),
              TextButton(onPressed: () => GoRouter.of(context).go('/auth'), child: const Text('Back to sign in')),
            ],
          ),
        ),
      ),
    );
  }
}
