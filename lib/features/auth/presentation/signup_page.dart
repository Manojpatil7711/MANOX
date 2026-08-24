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
  final first = TextEditingController();
  final surname = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();

  bool loading = false;
  bool obscure = true;
  bool confirmationSent = false;
  String? error;

  AuthRepository get repo => widget.authRepository ?? SupabaseAuthRepository();

  @override
  void dispose() {
    first.dispose(); surname.dispose(); mobile.dispose(); email.dispose(); password.dispose(); confirm.dispose();
    super.dispose();
  }

  String? requiredField(String? value, String name) => value == null || value.trim().isEmpty ? '$name is required' : null;

  String? passwordValidator(String? value) {
    final p = value ?? '';
    if (p.length < 8) return 'Use at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(p)) return 'Add at least 1 uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(p)) return 'Add at least 1 lowercase letter';
    if (!RegExp(r'\d').hasMatch(p)) return 'Add at least 1 number';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(p)) return 'Add at least 1 special character';
    return null;
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { loading = true; error = null; });
    try {
      await repo.signUp(firstName: first.text, surname: surname.text, mobile: mobile.text, email: email.text.trim(), password: password.text);
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

  InputDecoration fieldDecoration(String label, IconData icon) => InputDecoration(labelText: label, prefixIcon: Icon(icon), filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (confirmationSent) {
      return Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(children: [
        const ManoxBrand(), const SizedBox(height: 36), Icon(Icons.mark_email_read_outlined, size: 56, color: scheme.primary), const SizedBox(height: 18),
        const Text('CHECK YOUR EMAIL', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, letterSpacing: 1.1)), const SizedBox(height: 10),
        const Text('Confirm your email, then return to MANOX and sign in.', textAlign: TextAlign.center), const SizedBox(height: 24),
        ElevatedButton(onPressed: () => context.go('/auth'), child: const Text('BACK TO SIGN IN')),
      ])))));
    }

    return Scaffold(body: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [scheme.surface, Color.alphaBlend(scheme.primary.withValues(alpha: 0.09), scheme.surface), scheme.surface])), child: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 30, 24, 36), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 500), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Center(child: ManoxBrand()), const SizedBox(height: 30),
      const Text('CREATE YOUR MANOX ACCOUNT', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
      const SizedBox(height: 9), Text('YOUR DIFFERENCE MATTERS', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 3.0)), const SizedBox(height: 28),
      Row(children: [Expanded(child: TextFormField(controller: first, decoration: fieldDecoration('First name', Icons.person_outline), validator: (v) => requiredField(v, 'First name'))), const SizedBox(width: 12), Expanded(child: TextFormField(controller: surname, decoration: fieldDecoration('Surname', Icons.badge_outlined), validator: (v) => requiredField(v, 'Surname')))]),
      const SizedBox(height: 14), TextFormField(controller: mobile, decoration: fieldDecoration('Mobile number', Icons.phone_outlined), keyboardType: TextInputType.phone, validator: (v) => v == null || v.replaceAll(RegExp(r'\D'), '').length < 10 ? 'Enter a valid mobile number' : null),
      const SizedBox(height: 14), TextFormField(key: const Key('signup-email'), controller: email, decoration: fieldDecoration('Email address', Icons.mail_outline), keyboardType: TextInputType.emailAddress, validator: (v) { final value = v?.trim() ?? ''; if (value.isEmpty) return 'Email address is required'; return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value) ? null : 'Enter a valid email'; }),
      const SizedBox(height: 14), TextFormField(key: const Key('signup-password'), controller: password, obscureText: obscure, decoration: fieldDecoration('Password', Icons.lock_outline).copyWith(suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined), onPressed: () => setState(() => obscure = !obscure))), validator: passwordValidator),
      const SizedBox(height: 6),
      Text('Password: 8+ characters • 1 uppercase • 1 lowercase • 1 number • 1 special character', style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 14), TextFormField(key: const Key('signup-confirm'), controller: confirm, obscureText: true, decoration: fieldDecoration('Confirm password', Icons.lock_reset_outlined), validator: (v) => v != password.text ? 'Passwords do not match' : null),
      const SizedBox(height: 20), if (error != null) ...[Text(error!, key: const Key('signup-error'), textAlign: TextAlign.center, style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)), const SizedBox(height: 10)],
      SizedBox(height: 52, child: ElevatedButton(key: const Key('signup-submit'), onPressed: loading ? null : submit, child: loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('CREATE ACCOUNT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.0)))),
      const SizedBox(height: 12), TextButton(onPressed: loading ? null : () => context.go('/auth'), child: const Text('ALREADY HAVE AN ACCOUNT? SIGN IN')),
    ])))))));
  }
}
