import 'package:flutter/material.dart';

import '../main.dart';
import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int step = 0;
  final name = TextEditingController();
  final source = TextEditingController();
  final amount = TextEditingController();
  String frequency = 'monthly';
  bool loading = false;

  @override
  void dispose() {
    name.dispose();
    source.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> next() async {
    if (step == 0) {
      if (name.text.trim().isEmpty) return;
      setState(() => step = 1);
      return;
    }

    if (source.text.trim().isEmpty ||
        double.tryParse(amount.text.replaceAll(',', '')) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid income source and amount.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      await db.saveProfile(name.text);
      await db.addIncome(
        source: source.text,
        amount: double.parse(amount.text.replaceAll(',', '')),
        frequency: frequency,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save setup: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = step == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(first ? 'About you' : 'Your income'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: first ? .5 : 1),
                  const SizedBox(height: 28),
                  Text(
                    first ? 'What should we call you?' : 'Where does your money come from?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(first
                      ? 'This name is shown on your dashboard.'
                      : 'Example: salary, allowance, freelance work, business.'),
                  const SizedBox(height: 24),
                  if (first)
                    TextField(
                      controller: name,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    )
                  else ...[
                    TextField(
                      controller: source,
                      decoration: const InputDecoration(
                        labelText: 'Income source',
                        prefixIcon: Icon(Icons.work_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount received',
                        prefixText: '₱ ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: frequency,
                      decoration: const InputDecoration(
                        labelText: 'How often do you receive it?',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      ],
                      onChanged: (value) =>
                          setState(() => frequency = value ?? 'monthly'),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: loading ? null : next,
                    child: Text(loading
                        ? 'Saving...'
                        : first
                            ? 'Continue'
                            : 'Finish setup'),
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
