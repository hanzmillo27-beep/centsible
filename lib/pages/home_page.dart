import 'package:flutter/material.dart';

import '../main.dart';
import '../utils/money.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;

  String name = 'there';

  List<Map<String, dynamic>> incomes = [];
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> savings = [];
  List<Map<String, dynamic>> bills = [];
  List<Map<String, dynamic>> oneTimeExpenses = [];


  // ===========================================================================
  // INCOME CALCULATIONS
  // ===========================================================================

  double get totalMonthlyIncome => incomes.fold(
        0.0,
        (sum, item) => sum + monthlyIncomeValue(item),
      );

  double monthlyIncomeValue(Map<String, dynamic> item) {
    final rawAmount = item['amount'];
    final amount = rawAmount is num ? rawAmount.toDouble() : 0.0;

    final frequency = item['frequency'] as String? ?? 'monthly';

    switch (frequency) {
      case 'daily':
        return amount * 30;

      case 'weekly':
        return amount * 4;

      case 'monthly':
        return amount;

      default:
        return amount;
    }
  }

  // ===========================================================================
  // DAILY EXPENSES
  // ===========================================================================

  double get monthlyDailyExpenses => expenses.fold(
        0.0,
        (sum, item) {
          final rawAmount = item['daily_amount'];
          final dailyAmount =
              rawAmount is num ? rawAmount.toDouble() : 0.0;

          return sum + (dailyAmount * daysPerMonth);
        },
      );

// ===========================================================================
// ONE-TIME EXPENSE CALCULATIONS
// ===========================================================================

double get monthlyOneTimeExpenses {
  final now = DateTime.now();

  return oneTimeExpenses.fold(
    0.0,
    (sum, expense) {
      final rawDate = expense['expense_date'];

      if (rawDate == null) {
        return sum;
      }

      final date = DateTime.parse(rawDate.toString());

      // Only include one-time expenses from the current month.
      if (date.year != now.year || date.month != now.month) {
        return sum;
      }

      final rawAmount = expense['amount'];
      final amount =
          rawAmount is num ? rawAmount.toDouble() : 0.0;

      return sum + amount;
    },
  );
}


// ===========================================================================
// BILL CALCULATIONS
// ===========================================================================

// All bills count as monthly expenses,
// regardless of whether they are paid or unpaid.
double get monthlyBillsTotal => bills.fold(
      0.0,
      (sum, bill) {
        final rawAmount = bill['amount'];
        final amount =
            rawAmount is num ? rawAmount.toDouble() : 0.0;

        return sum + amount;
      },
    );

// Only unpaid bills are used for the reminder/notification display.
double get unpaidBillsTotal => bills.fold(
      0.0,
      (sum, bill) {
        final isPaid = bill['is_paid'] == true;

        if (isPaid) return sum;

        final rawAmount = bill['amount'];
        final amount =
            rawAmount is num ? rawAmount.toDouble() : 0.0;

        return sum + amount;
      },
    );

// Monthly expenses include:
// 1. Daily expenses
// 2. ALL bills, paid or unpaid
double get monthlyExpenses =>
    monthlyDailyExpenses +
    monthlyBillsTotal +
    monthlyOneTimeExpenses;

  // ===========================================================================
  // SAVINGS / LEFTOVER
  // ===========================================================================

  double get totalSaved {
    final saved = totalMonthlyIncome - monthlyExpenses;

    return saved > 0 ? saved : 0.0;
  }

  double get leftover => totalMonthlyIncome - monthlyExpenses;

  double get suggestedSavings =>
      leftover > 0 ? leftover * 0.20 : 0.0;

  double get dailySpendable {
    if (leftover <= 0 || daysPerMonth <= 0) {
      return 0.0;
    }

    return (leftover - suggestedSavings) / daysPerMonth;
  }

  // ===========================================================================
  // LOAD DATA
  // ===========================================================================

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final results = await Future.wait([
        db.displayName(),
        db.incomes(),
        db.expenses(),
        db.savings(),
        db.bills(),
        db.oneTimeExpenses(),
      ]);

      name = results[0] as String;
      incomes = results[1] as List<Map<String, dynamic>>;
      expenses = results[2] as List<Map<String, dynamic>>;
      savings = results[3] as List<Map<String, dynamic>>;
      bills = results[4] as List<Map<String, dynamic>>;
      oneTimeExpenses =
    results[5] as List<Map<String, dynamic>>;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load your plan: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  // ===========================================================================
  // ADD INCOME
  // ===========================================================================

  Future<void> addIncomeDialog() async {
    final source = TextEditingController();
    final amount = TextEditingController();

    String frequency = 'monthly';

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add income'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: source,
                decoration: const InputDecoration(
                  labelText: 'Source',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: amount,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱ ',
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                initialValue: frequency,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'daily',
                    child: Text('Daily'),
                  ),
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Text('Weekly'),
                  ),
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text('Monthly'),
                  ),
                ],
                onChanged: (v) {
                  setDialogState(
                    () => frequency = v ?? 'monthly',
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final value = double.tryParse(
                  amount.text.replaceAll(',', ''),
                );

                if (source.text.trim().isEmpty ||
                    value == null ||
                    value <= 0) {
                  return;
                }

                await db.addIncome(
                  source: source.text,
                  amount: value,
                  frequency: frequency,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                await load();
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    source.dispose();
    amount.dispose();
  }

  // ===========================================================================
  // ADD DAILY EXPENSE
  // ===========================================================================

  Future<void> addExpenseDialog() async {
    final expense = TextEditingController();
    final amount = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add daily expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: expense,
              decoration: const InputDecoration(
                labelText: 'Expense name',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: amount,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Daily amount',
                prefixText: '₱ ',
                helperText:
                    'Example: food ₱200 per day',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final value = double.tryParse(
                amount.text.replaceAll(',', ''),
              );

              if (expense.text.trim().isEmpty ||
                  value == null ||
                  value <= 0) {
                return;
              }

              await db.addExpense(
                name: expense.text,
                dailyAmount: value,
              );

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }

              await load();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    expense.dispose();
    amount.dispose();
  }

  // ===========================================================================
  // ADD BILL
  // ===========================================================================

  Future<void> addBillDialog() async {
    final billName = TextEditingController();
    final amount = TextEditingController();

    DateTime selectedDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add bill'),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: billName,
                  decoration: const InputDecoration(
                    labelText: 'Bill name',
                    hintText: 'Example: Electricity',
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₱ ',
                  ),
                ),

                const SizedBox(height: 16),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_month,
                  ),
                  title: const Text('Due date'),
                  subtitle: Text(
                    _formatDate(selectedDate),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      final picked =
                          await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );

                      if (picked != null) {
                        setDialogState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                    child: const Text('Select'),
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'This bill will be included in your monthly expenses.',
                  style: TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),

              FilledButton(
                onPressed: () async {
                  final value = double.tryParse(
                    amount.text.replaceAll(',', ''),
                  );

                  if (billName.text.trim().isEmpty ||
                      value == null ||
                      value <= 0) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Enter a valid bill name and amount.',
                        ),
                      ),
                    );

                    return;
                  }

                  await db.addBill(
                    name: billName.text,
                    amount: value,
                    dueDate: selectedDate,
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  await load();
                },
                child: const Text('Add bill'),
              ),
            ],
          );
        },
      ),
    );

    billName.dispose();
    amount.dispose();
  }

  // ===========================================================================
  // BILL HELPERS
  // ===========================================================================

  DateTime _billDate(Map<String, dynamic> bill) {
    return DateTime.parse(
      bill['due_date'].toString(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String billStatus(Map<String, dynamic> bill) {
    if (bill['is_paid'] == true) {
      return 'Paid';
    }

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final due = _billDate(bill);

    final dueDay = DateTime(
      due.year,
      due.month,
      due.day,
    );

    final difference =
        dueDay.difference(today).inDays;

    if (difference < 0) {
      return 'Overdue';
    }

    if (difference == 0) {
      return 'Due today';
    }

    if (difference == 1) {
      return 'Due tomorrow';
    }

    if (difference <= 7) {
      return 'Due in $difference days';
    }

    return 'Upcoming';
  }

  Color billStatusColor(Map<String, dynamic> bill) {
    if (bill['is_paid'] == true) {
      return Colors.green;
    }

    final status = billStatus(bill);

    if (status == 'Overdue') {
      return Colors.red;
    }

    if (status == 'Due today') {
      return Colors.orange;
    }

    if (status == 'Due tomorrow') {
      return Colors.deepOrange;
    }

    return Colors.indigo;
  }

  // ===========================================================================
  // LOGOUT
  // ===========================================================================

  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('MoneyPlan'),
        actions: [
          IconButton(
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),

      floatingActionButton: PopupMenuButton<String>(
        icon: const FloatingActionButton(
          onPressed: null,
          child: Icon(Icons.add),
        ),

        onSelected: (value) {
          if (value == 'income') {
            addIncomeDialog();
          }

          if (value == 'expense') {
            addExpenseDialog();
          }

          if (value == 'bill') {
            addBillDialog();
          }

          if (value == 'one_time_expense') {
              addOneTimeExpenseDialog();
            }
        },

        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'income',
            child: Text('Add income'),
          ),

          PopupMenuItem(
            value: 'expense',
            child: Text('Add daily expense'),
          ),

          PopupMenuItem(
            value: 'bill',
            child: Text('Add bill'),
          ),

          PopupMenuItem(
            value: 'one_time_expense',
            child: Text('Add one-time expense'),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: load,

        child: ListView(
          padding: const EdgeInsets.all(16),

          children: [
            Text(
              'Hi, $name',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Here is your monthly money plan.',
            ),

            const SizedBox(height: 16),

            _summaryCard(),

            const SizedBox(height: 16),

            _planCard(),

            const SizedBox(height: 16),

            _billsSection(),

            const SizedBox(height: 16),

            _section(
              'Daily expenses',

              expenses.isEmpty
                  ? const Text(
                      'No expenses yet. Tap + to add one.',
                    )
                  : Column(
                      children: expenses.map((e) {
                        final daily =
                            (e['daily_amount'] as num)
                                .toDouble();

                        return ListTile(
                          contentPadding:
                              EdgeInsets.zero,

                          leading: const CircleAvatar(
                            child: Icon(
                              Icons.receipt_long,
                            ),
                          ),

                          title: Text(
                            e['name'] as String,
                          ),

                          subtitle: Text(
                            '${money(daily)} / day • '
                            '${money(daily * daysPerMonth)} / month',
                          ),

                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                            ),

                            onPressed: () async {
                              await db.deleteExpense(
                                e['id'] as String,
                              );

                              await load();
                            },
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 16),

            _section(
              'Income sources',

              incomes.isEmpty
                  ? const Text(
                      'No income sources yet.',
                    )
                  : Column(
                      children: incomes.map((e) {
                        final amount =
                            (e['amount'] as num)
                                .toDouble();

                        final monthly =
                            monthlyIncomeValue(e);

                        return ListTile(
                          contentPadding:
                              EdgeInsets.zero,

                          leading: const CircleAvatar(
                            child: Icon(
                              Icons.payments_outlined,
                            ),
                          ),

                          title: Text(
                            e['source'] as String,
                          ),

                          subtitle: Text(
                            '${money(amount)} / '
                            '${e['frequency']} • '
                            '${money(monthly)} / month',
                          ),

                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                            ),

                            onPressed: () async {
                              await db.deleteIncome(
                                e['id'] as String,
                              );

                              await load();
                            },
                          ),
                        );
                      }).toList(),
                    ),
            ),

            const SizedBox(height: 16),

_section(
  'One-time expenses',

  oneTimeExpenses.isEmpty
      ? const Text(
          'No one-time expenses yet.',
        )
      : Column(
          children: oneTimeExpenses.map((e) {
            final amount =
                (e['amount'] as num).toDouble();

            final date =
                DateTime.parse(
              e['expense_date'].toString(),
            );

            return ListTile(
              contentPadding: EdgeInsets.zero,

              leading: const CircleAvatar(
                child: Icon(
                  Icons.shopping_bag_outlined,
                ),
              ),

              title: Text(
                e['name'].toString(),
              ),

              subtitle: Text(
                '${money(amount)} • '
                '${_formatDate(date)}',
              ),

              trailing: IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                ),

                onPressed: () async {
                  await db.deleteOneTimeExpense(
                    e['id'].toString(),
                  );

                  await load();
                },
              ),
            );
          }).toList(),
        ),
),

            const SizedBox(height: 16),

            _section(
              'Savings',

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    money(totalSaved),
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    'Automatically calculated from your income and expenses.',
                  ),

                  if (savings.isNotEmpty) ...[
                    const Divider(),

                    ...savings.take(5).map(
                      (e) => ListTile(
                        contentPadding:
                            EdgeInsets.zero,

                        title: Text(
                          money(
                            (e['amount'] as num)
                                .toDouble(),
                          ),
                        ),

                        subtitle: Text(
                          (e['note'] as String?) ??
                              'Saved money',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BILLS SECTION
  // ===========================================================================

  Widget _billsSection() {
    if (bills.isEmpty) {
      return _section(
        'Bills & reminders',
        const Text(
          'No bills yet. Tap + and select "Add bill".',
        ),
      );
    }

    final sortedBills = [...bills];

    sortedBills.sort((a, b) {
      final aPaid = a['is_paid'] == true;
      final bPaid = b['is_paid'] == true;

      if (aPaid && !bPaid) return 1;
      if (!aPaid && bPaid) return -1;

      return _billDate(a).compareTo(
        _billDate(b),
      );
    });

    return _section(
      'Bills & reminders',

      Column(
        children: [
          if (unpaidBillsTotal > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(
                bottom: 8,
              ),
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(12),
                color: Colors.orange.shade50,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_active,
                    color: Colors.orange,
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'You have ${money(unpaidBillsTotal)} '
                      'in unpaid bills.',
                      style: const TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          ...sortedBills.map(
            (bill) {
              final amount =
                  (bill['amount'] as num)
                      .toDouble();

              final paid =
                  bill['is_paid'] == true;

              final status =
                  billStatus(bill);

              final statusColor =
                  billStatusColor(bill);

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 8,
                ),

                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),

                  leading: CircleAvatar(
                    backgroundColor:
                        paid
                            ? Colors.green.shade100
                            : statusColor
                                .withValues(alpha: 0.12),
                    child: Icon(
                      paid
                          ? Icons.check
                          : Icons
                              .notifications_outlined,
                      color: paid
                          ? Colors.green
                          : statusColor,
                    ),
                  ),

                  title: Text(
                    bill['name'].toString(),
                    style: TextStyle(
                      fontWeight:
                          FontWeight.w600,
                      decoration: paid
                          ? TextDecoration
                              .lineThrough
                          : null,
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 3),

                      Text(
                        money(amount),
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),

                      Text(
                        'Due ${_formatDate(_billDate(bill))}',
                      ),

                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'paid') {
                        await db.markBillPaid(
                          bill['id'].toString(),
                          !paid,
                        );

                        await load();
                      }

                      if (value == 'delete') {
                        await db.deleteBill(
                          bill['id'].toString(),
                        );

                        await load();
                      }
                    },

                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'paid',
                        child: Text(
                          paid
                              ? 'Mark as unpaid'
                              : 'Mark as paid',
                        ),
                      ),

                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete bill'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SUMMARY
  // ===========================================================================

  Widget _summaryCard() {
    final deficit = leftover < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          children: [
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                _metric(
                  'Monthly income',
                  totalMonthlyIncome,
                ),

                _metric(
                  'Monthly expenses',
                  monthlyExpenses,
                ),
              ],
            ),

            const Divider(height: 28),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

              children: [
                _metric(
                  deficit
                      ? 'Monthly deficit'
                      : 'Money left',
                  leftover.abs(),
                ),

                _metric(
                  'Saved',
                  totalSaved,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // METRIC
  // ===========================================================================

  Widget _metric(
    String label,
    double value,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium,
          ),

          const SizedBox(height: 4),

          Text(
            money(value),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(
                  fontWeight:
                      FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DISTRIBUTION PLAN
  // ===========================================================================

  Widget _planCard() {
    final deficit = leftover < 0;

    return Card(
      color: deficit
          ? Colors.red.shade50
          : Colors.indigo.shade50,

      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              'Your distribution plan',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 12),

            if (deficit)
              Text(
                'Your planned expenses are '
                '${money(leftover.abs())} above your '
                'normalized monthly income. Reduce '
                'expenses or add another income source.',
              )
            else ...[
              _planRow(
                'Planned expenses',
                monthlyExpenses,
              ),

              _planRow(
                'Suggested savings (20% of leftover)',
                suggestedSavings,
              ),

              _planRow(
                'Flexible spending / buffer',
                leftover - suggestedSavings,
              ),

              const Divider(),

              Text(
                'Daily flexible spending target: '
                '${money(dailySpendable)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _planRow(
    String label,
    double amount,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 5),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

        children: [
          Expanded(
            child: Text(label),
          ),

          Text(
            money(amount),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // GENERIC SECTION
  // ===========================================================================

  Widget _section(
    String title,
    Widget child,
  ) {
    return Card(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          8,
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    fontWeight:
                        FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 8),

            child,
          ],
        ),
      ),
    );
  }

  // ===========================================================================
// ADD ONE-TIME EXPENSE
// ===========================================================================

Future<void> addOneTimeExpenseDialog() async {
  final expenseName = TextEditingController();
  final amount = TextEditingController();

  DateTime selectedDate = DateTime.now();

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Add one-time expense'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: expenseName,
                decoration: const InputDecoration(
                  labelText: 'Expense name',
                  hintText: 'Example: New clothes',
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: amount,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₱ ',
                ),
              ),

              const SizedBox(height: 16),

              ListTile(
                contentPadding: EdgeInsets.zero,

                leading: const Icon(
                  Icons.calendar_month,
                ),

                title: const Text('Expense date'),

                subtitle: Text(
                  _formatDate(selectedDate),
                ),

                trailing: OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      setDialogState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: const Text('Select'),
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'This expense is counted only once and will not repeat daily.',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () async {
                final value = double.tryParse(
                  amount.text.replaceAll(',', ''),
                );

                if (expenseName.text.trim().isEmpty ||
                    value == null ||
                    value <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Enter a valid expense name and amount.',
                      ),
                    ),
                  );

                  return;
                }

                await db.addOneTimeExpense(
                  name: expenseName.text,
                  amount: value,
                  expenseDate: selectedDate,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }

                await load();
              },
              child: const Text('Add expense'),
            ),
          ],
        );
      },
    ),
  );

  expenseName.dispose();
  amount.dispose();
}
}
