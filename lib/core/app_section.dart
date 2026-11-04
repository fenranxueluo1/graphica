import '../l10n/l10n.dart';

/// Top-level destinations in the app shell.
enum AppSection {
  home,
  graph,
  calculator,
  matrix,
  geometry,
  threeD,
  settings;

  String label(L10n l10n) => l10n.t('section.$name.label');

  String description(L10n l10n) => l10n.t('section.$name.description');
}
