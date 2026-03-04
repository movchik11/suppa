import 'package:flutter/cupertino.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

class TmCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const TmCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'tk';

  @override
  Future<CupertinoLocalizations> load(Locale locale) {
    // Fallback to Russian for Cupertino widgets as it's closest regionally/technically
    // or English if preferred. Using Russian as it likely has better Cyrillic support if needed.
    return GlobalCupertinoLocalizations.delegate.load(const Locale('ru'));
  }

  @override
  bool shouldReload(TmCupertinoLocalizationsDelegate old) => false;
}
