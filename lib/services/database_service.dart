import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart';

class DatabaseService {
  User get user => supabase.auth.currentUser!;

  // ===========================================================================
  // ONBOARDING
  // ===========================================================================

  Future<bool> hasCompletedOnboarding() async {
    final profile = await supabase
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) return false;

    final income = await supabase
        .from('income_sources')
        .select('id')
        .eq('user_id', user.id)
        .limit(1);

    return income.isNotEmpty;
  }

  // ===========================================================================
  // PROFILE
  // ===========================================================================

  Future<void> saveProfile(String displayName) async {
    await supabase.from('profiles').upsert({
      'id': user.id,
      'display_name': displayName.trim(),
    });
  }

  Future<String> displayName() async {
    final row = await supabase
        .from('profiles')
        .select('display_name')
        .eq('id', user.id)
        .maybeSingle();

    return (row?['display_name'] as String?) ??
        (user.userMetadata?['display_name'] as String?) ??
        'there';
  }

  // ===========================================================================
  // INCOME
  // ===========================================================================

  Future<void> addIncome({
    required String source,
    required double amount,
    required String frequency,
  }) async {
    await supabase.from('income_sources').insert({
      'user_id': user.id,
      'source': source.trim(),
      'amount': amount,
      'frequency': frequency,
    });
  }

  Future<void> deleteIncome(String id) async {
    await supabase
        .from('income_sources')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<List<Map<String, dynamic>>> incomes() async {
    final rows = await supabase
        .from('income_sources')
        .select()
        .eq('user_id', user.id)
        .order('created_at');

    return List<Map<String, dynamic>>.from(rows);
  }

  // ===========================================================================
  // DAILY EXPENSES
  // ===========================================================================

  Future<void> addExpense({
    required String name,
    required double dailyAmount,
  }) async {
    await supabase.from('expenses').insert({
      'user_id': user.id,
      'name': name.trim(),
      'daily_amount': dailyAmount,
    });
  }

  Future<void> deleteExpense(String id) async {
    await supabase
        .from('expenses')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<List<Map<String, dynamic>>> expenses() async {
    final rows = await supabase
        .from('expenses')
        .select()
        .eq('user_id', user.id)
        .order('created_at');

    return List<Map<String, dynamic>>.from(rows);
  }

  // ===========================================================================
  // ONE-TIME EXPENSES
  // ===========================================================================

  Future<void> addOneTimeExpense({
    required String name,
    required double amount,
    required DateTime expenseDate,
  }) async {
    await supabase.from('one_time_expenses').insert({
      'user_id': user.id,
      'name': name.trim(),
      'amount': amount,
      'expense_date':
          expenseDate.toIso8601String().split('T').first,
    });
  }

  Future<List<Map<String, dynamic>>> oneTimeExpenses() async {
    final rows = await supabase
        .from('one_time_expenses')
        .select()
        .eq('user_id', user.id)
        .order('expense_date', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> deleteOneTimeExpense(String id) async {
    await supabase
        .from('one_time_expenses')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  // ===========================================================================
  // BILLS
  // ===========================================================================

  Future<void> addBill({
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    await supabase.from('bills').insert({
      'user_id': user.id,
      'name': name.trim(),
      'amount': amount,
      'due_date':
          dueDate.toIso8601String().split('T').first,
      'is_paid': false,
    });
  }

  Future<List<Map<String, dynamic>>> bills() async {
    final rows = await supabase
        .from('bills')
        .select()
        .eq('user_id', user.id)
        .order('due_date', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> markBillPaid(
    String id,
    bool paid,
  ) async {
    await supabase
        .from('bills')
        .update({
          'is_paid': paid,
        })
        .eq('id', id)
        .eq('user_id', user.id);
  }

  Future<void> deleteBill(String id) async {
    await supabase
        .from('bills')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }

  // ===========================================================================
  // SAVINGS
  // ===========================================================================

  Future<void> addSaving({
    required double amount,
    String? note,
  }) async {
    await supabase.from('savings').insert({
      'user_id': user.id,
      'amount': amount,
      'note': note?.trim().isEmpty == true
          ? null
          : note?.trim(),
    });
  }

  Future<List<Map<String, dynamic>>> savings() async {
    final rows = await supabase
        .from('savings')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows);
  }
}