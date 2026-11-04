import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Small JSON-file store used for settings and the graph document.
///
/// Uses only dart:io + path_provider so it works on desktop, mobile and
/// HarmonyOS. Every failure degrades to in-memory state instead of crashing.
class AppStore {
  AppStore._(this._directory, this.settings, this.graph, this.surface);

  /// In-memory store used by tests and as a safe fallback.
  factory AppStore.inMemory({
    Map<String, dynamic>? settings,
    Map<String, dynamic>? graph,
    Map<String, dynamic>? surface,
  }) {
    return AppStore._(
      null,
      settings ?? <String, dynamic>{},
      graph ?? <String, dynamic>{},
      surface ?? <String, dynamic>{},
    );
  }

  final Directory? _directory;
  Map<String, dynamic> settings;
  Map<String, dynamic> graph;
  Map<String, dynamic> surface;

  Timer? _settingsTimer;
  Timer? _graphTimer;
  Timer? _surfaceTimer;

  static Future<AppStore> open() async {
    Directory? directory;
    try {
      directory = await getApplicationSupportDirectory();
    } catch (_) {
      try {
        directory = await getApplicationDocumentsDirectory();
      } catch (_) {
        try {
          directory = Directory.systemTemp;
        } catch (_) {
          directory = null;
        }
      }
    }

    final settings = await _read(directory, 'settings.json');
    final graph = await _read(directory, 'graph.json');
    final surface = await _read(directory, 'surface3d.json');
    return AppStore._(directory, settings, graph, surface);
  }

  static Future<Map<String, dynamic>> _read(
    Directory? directory,
    String name,
  ) async {
    if (directory == null) return <String, dynamic>{};
    try {
      final file = File('${directory.path}${Platform.pathSeparator}$name');
      if (!await file.exists()) return <String, dynamic>{};
      final text = await file.readAsString();
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Corrupt or unreadable files simply start fresh.
    }
    return <String, dynamic>{};
  }

  void saveSettings(Map<String, dynamic> data) {
    settings = data;
    _settingsTimer?.cancel();
    _settingsTimer = Timer(const Duration(milliseconds: 350), () {
      _write('settings.json', data);
    });
  }

  void saveGraph(Map<String, dynamic> data) {
    graph = data;
    _graphTimer?.cancel();
    _graphTimer = Timer(const Duration(milliseconds: 450), () {
      _write('graph.json', data);
    });
  }

  void saveSurface(Map<String, dynamic> data) {
    surface = data;
    _surfaceTimer?.cancel();
    _surfaceTimer = Timer(const Duration(milliseconds: 450), () {
      _write('surface3d.json', data);
    });
  }

  Future<void> _write(String name, Map<String, dynamic> data) async {
    final directory = _directory;
    if (directory == null) return;
    try {
      await directory.create(recursive: true);
      final file = File('${directory.path}${Platform.pathSeparator}$name');
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (_) {
      // Ignore write failures; the session still works.
    }
  }

  Future<void> flush() async {
    _settingsTimer?.cancel();
    _graphTimer?.cancel();
    _surfaceTimer?.cancel();
    await _write('settings.json', settings);
    await _write('graph.json', graph);
    await _write('surface3d.json', surface);
  }

  /// Path shown next to an exported PNG.
  Future<Directory> exportDirectory() async {
    if (!Platform.isAndroid &&
        !Platform.isIOS &&
        !Platform.isWindows &&
        !Platform.isLinux &&
        !Platform.isMacOS) {
      // HarmonyOS and anything unexpected: use the app support directory.
      final support = _directory;
      if (support != null) return support;
    }
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      try {
        final downloads = await getDownloadsDirectory();
        if (downloads != null) return downloads;
      } catch (_) {
        // Fall through to the support directory.
      }
    }
    final support = _directory;
    if (support != null) return support;
    return Directory.systemTemp;
  }
}
