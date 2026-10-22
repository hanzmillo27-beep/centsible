import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool login = true;
  bool loading = false;
  final email = TextEditingController();
  final password = TextEditingController();
  final displayName = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    displayName.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) return;
    if (!login && displayName.text.trim().isEmpty) return;

    setState(() => loading = true);
    try {
      if (login) {
        await supabase.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      } else {
        final response = await supabase.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'display_name': displayName.text.trim()},
        );

        if (!mounted) return;
        if (response.session == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created. Check your email to verify it, then log in.'),
            ),
          );
          setState(() => login = true);
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    Image.asset(
                      'assets/icon/icon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 16),
                  Text(
                    'Centsible',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plan Remind Save',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  if (!login) ...[
                    TextField(
                      controller: displayName,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: loading ? null : submit,
                    child: Text(loading
                        ? 'Please wait...'
                        : login
                            ? 'Log in'
                            : 'Create account'),
                  ),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() => login = !login),
                    child: Text(login
                        ? 'New here? Create an account'
                        : 'Already have an account? Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
