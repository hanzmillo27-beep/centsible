const double daysPerMonth = 365.0 / 12.0;

double monthlyIncome(double amount, String frequency) {
  switch (frequency) {
    case 'daily':
      return amount * daysPerMonth;
    case 'weekly':
      return amount * 52.0 / 12.0;
    case 'monthly':
    default:
      return amount;
  }
}

String money(double value) => '₱${value.toStringAsFixed(2)}';
