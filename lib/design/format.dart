import 'package:intl/intl.dart';

final _idr = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

String formatIDR(num value) => _idr.format(value);
