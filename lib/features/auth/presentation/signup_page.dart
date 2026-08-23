import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/manox_brand.dart';
import '../domain/auth_repository.dart';
import '../data/supabase_auth_repository.dart';

class SignupPage extends StatefulWidget {
  final AuthRepository? authRepository;
  const SignupPage({super.key, this.authRepository});
  @override State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final first = TextEditingController();
  final surname = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool loading = false, obscure = true, confirmationSent = false;
  String? error;
  AuthRepository get repo => widget.authRepository ?? SupabaseAuthRepository();
  @override void dispose() { first.dispose(); surname.dispose(); mobile.dispose(); email.dispose(); password.dispose(); confirm.dispose(); super.dispose(); }

  String? requiredField(String? v, String name) => v == null || v.trim().isEmpty ? '$name is required' : null;

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { loading = true; error = null; });
    try {
      await repo.signUp(
        firstName: first.text,
        surname: surname.text,
        mobile: mobile.text,
        email: email.text.trim(),
        password: password.text,
      );
      if (!mounted) return;
      if (repo.hasSession) {
        context.go('/home');
      } else {
        setState(() => confirmationSent = true);
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'Unable to create your account. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (confirmationSent) {
      return Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(children: [
        const ManoxBrand(), const SizedBox(height: 36), const Icon(Icons.mark_email_read_outlined, size: 56), const SizedBox(height: 18),
        const Text('Check your email', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)), const SizedBox(height: 10),
        const Text('Confirm your email, then return to MANOX and sign in.', textAlign: TextAlign.center), const SizedBox(height: 24),
        ElevatedButton(onPressed: () => context.go('/auth'), child: const Text('Back to sign in')),
      ])))));
    }
    return Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 28, 24, 32), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Center(child: ManoxBrand()), const SizedBox(height: 28), const Text('Create your MANOX account', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)), const SizedBox(height: 7), const Text('Your Difference Matters.', textAlign: TextAlign.center), const SizedBox(height: 26),
      Row(children: [Expanded(child: TextFormField(controller: first, decoration: const InputDecoration(labelText: 'First name', prefixIcon: Icon(Icons.person_outline)), validator: (v) => requiredField(v, 'First name'))), const SizedBox(width: 12), Expanded(child: TextFormField(controller: surname, decoration: const InputDecoration(labelText: 'Surname', prefixIcon: Icon(Icons.badge_outlined)), validator: (v) => requiredField(v, 'Surname')))]),
      const SizedBox(height: 14), TextFormField(controller: mobile, decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone, validator: (v) => v == null || v.replaceAll(RegExp(r'\D'), '').length < 10 ? 'Enter a valid mobile number' : null),
      const SizedBox(height: 14), TextFormField(key: const Key('signup-email'), controller: email, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.mail_outline)), keyboardType: TextInputType.emailAddress, validator: (v) => v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim()) ? 'Enter a valid email' : null),
      const SizedBox(height: 14), TextFormField(key: const Key('signup-password'), controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => obscure = !obscure))), validator: (v) => v == null || v.length < 8 ? 'Use at least 8 characters' : null),
      const SizedBox(height: 14), TextFormField(key: const Key('signup-confirm'), controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm password', prefixIcon: Icon(Icons.lock_reset_outlined)), validator: (v) => v != password.text ? 'Passwords do not match' : null),
      const SizedBox(height: 18), if (error != null) ...[Text(error!, key: const Key('signup-error'), style: TextStyle(color: Theme.of(context).colorScheme.error)), const SizedBox(height: 10)],
      ElevatedButton(key: const Key('signup-submit'), onPressed: loading ? null : submit, child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create account')),
      const SizedBox(height: 10), TextButton(onPressed: loading ? null : () => context.go('/auth'), child: const Text('Already have an account? Sign in')),
    ]))))));
  }
}
