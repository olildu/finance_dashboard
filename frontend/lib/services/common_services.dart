import 'package:intl/intl.dart';

String formatIndianSystem(int number) {
  String numStr = number.toString();
  if (numStr.length <= 3) {
    return numStr;
  }

  String lastThree = numStr.substring(numStr.length - 3);
  String remaining = numStr.substring(0, numStr.length - 3);
  String formattedRemaining = '';

  while (remaining.length > 2) {
    formattedRemaining = ',${remaining.substring(remaining.length - 2)}$formattedRemaining';
    remaining = remaining.substring(0, remaining.length - 2);
  }

  return '$remaining$formattedRemaining,$lastThree';
}

String formatNumber(double number) {
  if (number >= 1000) {
    return '${(number / 1000).toStringAsFixed(1)}k';
  } else if (number >= 100) {
    return '0.${(number ~/ 100)}k'; 
  }
  return '0.0k';
}

String formatDate(String dateString) {
  DateTime date = DateTime.parse(dateString);
  String formattedDate = DateFormat('MMMM dd y').format(date);

  return formattedDate;
}

int daysLeftInMonth() {
  final today = DateTime.now();
  final nextMonth = DateTime(today.year, today.month + 1, 1);
  final daysLeft = nextMonth.subtract(const Duration(days: 1)).day - today.day;
  return daysLeft;
}
