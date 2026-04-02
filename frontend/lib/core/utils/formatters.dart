import 'package:intl/intl.dart';

class AppFormatters {
  static final _currency = NumberFormat.currency(locale: 'zh_CN', symbol: '¥', decimalDigits: 2);
  static final _dateTime = DateFormat('MM-dd HH:mm');
  static final _date = DateFormat('yyyy-MM-dd');

  static String currency(num value) => _currency.format(value);
  static String dateTime(DateTime value) => _dateTime.format(value);
  static String date(DateTime value) => _date.format(value);
}
