String formatRupiah(double value) {
  final chars = value.toInt().toString().split('');
  final buffer = StringBuffer();
  for (int i = 0; i < chars.length; i++) {
    if (i > 0 && (chars.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(chars[i]);
  }
  return buffer.toString();
}
