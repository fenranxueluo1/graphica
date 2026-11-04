import 'package:flutter/material.dart';

import 'app.dart';
import 'core/storage/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.open();
  runApp(GraphicaApp(store: store));
}
