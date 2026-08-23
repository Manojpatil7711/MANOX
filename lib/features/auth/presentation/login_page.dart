import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/manox_brand.dart';
import '../domain/auth_repository.dart';
import '../data/supabase_auth_repository.dart';

class LoginPage extends StatefulWidget {
  final AuthRepository? authRepository;
  const LoginPage({super.key, this.authRepository});
  @override State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false, _obscure = true;
  String? _error;
  AuthRepository get _repo => widget.authRepository ?? SupabaseAuthRepository();
  @override void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await _repo.signIn(_emailCtrl.text.trim(), _passwordCtrl.text);
      if (mounted) context.go('/home');
    } on AuthException catch (e) { if (mounted) setState(() => _error = e.message); }
      catch (_) { if (mounted) setState(() => _error = 'Unable to sign in. Please check your details.'); }
      finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
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
            Text('Sign in to continue your creator journey.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 30),
            TextFormField(key: const Key('login-email'), controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline)), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || v.trim().isEmpty ? 'Email is required' : null),
            const SizedBox(height: 14),
            TextFormField(key: const Key('login-password'), controller: _passwordCtrl, obscureText: _obscure, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => _obscure = !_obscure))), validator: (v) => v == null || v.isEmpty ? 'Password is required' : null),
            Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _loading ? null : () => context.go('/auth/forgot'), child: const Text('Forgot password?'))),
            if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(_error!, key: const Key('login-error'), style: TextStyle(color: Theme.of(context).colorScheme.error))),
            ElevatedButton(key: const Key('login-submit'), onPressed: _loading ? null : _submit, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in')),
            const SizedBox(height: 20),
            Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('NEW TO MANOX', style: Theme.of(context).textTheme.bodySmall)), const Expanded(child: Divider())]),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _loading ? null : () => context.go('/auth/signup'), child: const Text('Create your MANOX account')),
          ]),
        )),
      )),),
    );
  }
}
