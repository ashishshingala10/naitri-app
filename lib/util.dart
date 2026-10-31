import 'package:intl/intl.dart';

final _rupee = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
String money(num? n) => _rupee.format(n ?? 0);

String shortDate(String? iso) {
  if (iso == null || iso.isEmpty) return '-';
  try {
    final d = DateTime.parse(iso);
    return DateFormat('d MMM yyyy').format(d);
  } catch (_) {
    return iso;
  }
}
