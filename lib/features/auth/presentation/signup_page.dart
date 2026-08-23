import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/manox_brand.dart';
import '../domain/auth_repository.dart';
import '../data/supabase_auth_repository.dart';

class SignupPage extends StatefulWidget {
  final AuthRepository? authRepository;
  const SignupPage({super.key, this.authRepository});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _confirmationSent = false;
  String? _error;

  AuthRepository get _repo => widget.authRepository ?? SupabaseAuthRepository();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.signUp(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      final session = SupabaseAuthRepository.currentSession;
      if (session != null) {
        GoRouter.of(context).go('/home');
      } else {
        setState(() => _confirmationSent = true);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Unable to create account. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmationSent) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: ManoxBrand()),
                    const SizedBox(height: 32),
                    const Icon(Icons.mark_email_read_outlined, size: 56),
                    const SizedBox(height: 18),
                    const Text('Check your email', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Text(
                      'We sent a confirmation link to ${_emailCtrl.text.trim()}. Confirm your email, then return to MANOX and sign in.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => GoRouter.of(context).go('/auth'),
                      child: const Text('Back to sign in'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => setState(() => _confirmationSent = false),
                      child: const Text('Use another email'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: ManoxBrand()),
                    const SizedBox(height: 28),
                    const Text('Create your MANOX account', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('Join the creator community.', textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    TextFormField(
                      key: const Key('signup-email'),
                      controller: _emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                        if (!emailRegex.hasMatch(v.trim())) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('signup-password'),
                      controller: _passwordCtrl,
                      decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        if (v.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      key: const Key('signup-confirm'),
                      controller: _confirmCtrl,
                      decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_reset_outlined)),
                      obscureText: true,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Confirm your password';
                        if (v != _passwordCtrl.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    if (_error != null) ...[
                      Text(_error!, key: const Key('signup-error'), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 10),
                    ],
                    ElevatedButton(
                      key: const Key('signup-submit'),
                      onPressed: _loading ? null : _submit,
                      child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create account'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loading ? null : () => GoRouter.of(context).go('/auth'),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
