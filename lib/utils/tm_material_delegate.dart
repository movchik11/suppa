import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class TmMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const TmMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tk';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    // Load 'tk' (Turkmen) material localizations for 'tm' locale
    // We try 'tk' first, if that fails (e.g. older flutter), fallback to 'en'
    try {
      return await GlobalMaterialLocalizations.delegate.load(
        const Locale('tk'),
      );
    } catch (_) {
      return await GlobalMaterialLocalizations.delegate.load(
        const Locale('en'),
      );
    }
  }

  @override
  bool shouldReload(
    covariant LocalizationsDelegate<MaterialLocalizations> old,
  ) => false;
}
