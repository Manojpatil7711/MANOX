import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/manox_brand.dart';
import '../domain/auth_repository.dart';
import '../data/supabase_auth_repository.dart';

class LoginPage extends StatefulWidget {
  final AuthRepository? authRepository;
  const LoginPage({super.key, this.authRepository});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _loading = false, _obscure = true, _otpMode = false, _otpSent = false;
  String? _error;
  AuthRepository get _repo => widget.authRepository ?? SupabaseAuthRepository();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _repo.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to sign in. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid email address first.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _repo.sendEmailOtp(email);
      if (mounted) setState(() => _otpSent = true);
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to send the code. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 6-digit verification code.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await _repo.verifyEmailOtp(_emailCtrl.text.trim(), code);
      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'The code could not be verified. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _repo.signInWithGoogle();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Google sign-in could not start.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Center(child: ManoxBrand()),
            const SizedBox(height: 42),
            const Text('Welcome back', textAlign: TextAlign.center, style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Sign in to continue your MANOX journey.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 26),
            OutlinedButton.icon(
              key: const Key('google-signin'),
              onPressed: _loading ? null : _google,
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('CONTINUE WITH GOOGLE'),
            ),
            const SizedBox(height: 18),
            Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: Theme.of(context).textTheme.bodySmall)), const Expanded(child: Divider())]),
            const SizedBox(height: 18),
            TextFormField(
              key: const Key('login-email'),
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline)),
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            if (!_otpMode) ...[
              TextFormField(
                key: const Key('login-password'),
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscure = !_obscure))),
                validator: (v) => v == null || v.isEmpty ? 'Password is required' : v.length < 8 ? 'Password must be at least 8 characters' : null,
              ),
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _loading ? null : () => context.go('/auth/forgot'), child: const Text('Forgot password?'))),
              if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, key: const Key('login-error'), textAlign: TextAlign.center, style: TextStyle(color: scheme.error))),
              ElevatedButton(key: const Key('login-submit'), onPressed: _loading ? null : _submitPassword, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('SIGN IN')),
              const SizedBox(height: 8),
              TextButton(onPressed: _loading ? null : () => setState(() { _otpMode = true; _error = null; }), child: const Text('USE EMAIL CODE INSTEAD')),
            ] else ...[
              Text('We’ll send a secure one-time code to your email.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              Text('6 digits • numbers only • one-time use • expires automatically', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              if (!_otpSent) ...[
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, key: const Key('login-error'), textAlign: TextAlign.center, style: TextStyle(color: scheme.error))),
                ElevatedButton(key: const Key('send-email-code'), onPressed: _loading ? null : _sendOtp, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('SEND CODE')),
                TextButton(onPressed: _loading ? null : () => setState(() { _otpMode = false; _error = null; }), child: const Text('USE PASSWORD INSTEAD')),
              ] else ...[
                TextField(
                  key: const Key('email-otp'),
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(labelText: '6-digit verification code', counterText: ''),
                ),
                if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, key: const Key('login-error'), textAlign: TextAlign.center, style: TextStyle(color: scheme.error))),
                ElevatedButton(key: const Key('verify-email-code'), onPressed: _loading || !RegExp(r'^\d{6}$').hasMatch(_otpCtrl.text.trim()) ? null : _verifyOtp, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('VERIFY & CONTINUE')),
                TextButton(onPressed: _loading ? null : _sendOtp, child: const Text('RESEND CODE')),
                TextButton(onPressed: _loading ? null : () => setState(() { _otpMode = false; _otpSent = false; _error = null; }), child: const Text('USE PASSWORD INSTEAD')),
              ],
            ],
            const SizedBox(height: 18),
            Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('NEW TO MANOX', style: Theme.of(context).textTheme.bodySmall)), const Expanded(child: Divider())]),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _loading ? null : () => context.go('/auth/signup'), child: const Text('CREATE YOUR MANOX ACCOUNT')),
          ]),
        )),
      )),),
    );
  }
}
