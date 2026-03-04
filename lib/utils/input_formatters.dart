import 'package:flutter/services.dart';

class LicensePlateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toUpperCase();

    // Remove all non-alphanumeric
    text = text.replaceAll(RegExp(r'[^A-Z0-9]'), '');

    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2 || i == 6) {
        formatted += '-';
      }
      formatted += text[i];
      if (formatted.length >= 10) break; // XX-1234-XX
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Must start with +993
    if (!text.startsWith('+993')) {
      text = '+993${text.replaceAll(RegExp(r'[^0-9]'), '')}';
    }

    // Keep only digits after +
    String digits = text.substring(1).replaceAll(RegExp(r'[^0-9]'), '');

    // Limits
    if (digits.length > 11) digits = digits.substring(0, 11);

    String formatted = '+';
    for (int i = 0; i < digits.length; i++) {
      if (i == 3 || i == 5 || i == 7 || i == 9) {
        formatted += '-';
      }
      formatted += digits[i];
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
