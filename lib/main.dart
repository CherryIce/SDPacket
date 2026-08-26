import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_repository.dart';
import 'data/app_store.dart';
import 'l10n/app_localizations.dart';
import 'l10n/app_localizations_en.dart';
import 'l10n/app_localizations_zh.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final languageCode =
      WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  final isChinese = languageCode.toLowerCase().startsWith('zh');
  final AppLocalizations l10n = isChinese
      ? AppLocalizationsZh()
      : AppLocalizationsEn();
  final store = AppStore(repository: FileAppRepository());
  store.initialize(
    SampleSeed(
      projectName: l10n.sampleProjectName,
      origin: l10n.sampleOrigin,
      destination: l10n.sampleDestination,
      memo: l10n.sampleMemo,
    ),
  );
  runApp(MovingBoxApp(store: store));
}
