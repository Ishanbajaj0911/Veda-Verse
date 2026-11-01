import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The Gemini API keys the user typed in Settings: up to [maxKeys], tried in
/// order so a backup key takes over when one hits its free limit or stops
/// working.
///
/// Stored only on this device, in secure storage (Android Keystore, iOS
/// Keychain, encrypted browser storage on web). Never compiled into the app,
/// never committed to git, never logged. With no key the app works offline.
class AiKey {
  AiKey._();

  static const maxKeys = 3;
  static const _storeKey = 'vv.gemini_api_keys';
  static const _legacyKey = 'vv.gemini_api_key'; // single key, before backups
  static const _storage = FlutterSecureStorage();
  static List<String> _keys = [];

  /// Bumps whenever keys are added or removed, so screens can refresh.
  static final changes = ValueNotifier<int>(0);

  /// Saved keys, primary first.
  static List<String> get keys => List.unmodifiable(_keys);
  static bool get isSet => _keys.isNotEmpty;
  static bool get isFull => _keys.length >= maxKeys;

  /// "AIza…1a2b" for showing a key without revealing it.
  static String mask(String k) => k.length <= 8 ? '••••' : '${k.substring(0, 4)}…${k.substring(k.length - 4)}';

  /// Google AI Studio issues two key formats: the classic "AIza…" (39
  /// characters) and the newer "AQ.…" (about 53). Placeholders like
  /// "paste-your-key-here" never match.
  static bool looksValid(String k) =>
      RegExp(r'^(AIza[A-Za-z0-9_\-]{30,60}|AQ\.[A-Za-z0-9_\-.]{30,90})$').hasMatch(k.trim());

  /// Loads saved keys at start-up. Never throws.
  static Future<void> load() async {
    try {
      final raw = await _storage.read(key: _storeKey);
      if (raw != null) {
        _keys = [for (final k in (jsonDecode(raw) as List)) if (k is String && looksValid(k)) k];
      } else {
        final legacy = await _storage.read(key: _legacyKey);
        _keys = legacy != null && looksValid(legacy) ? [legacy] : [];
      }
    } catch (e) {
      debugPrint('AiKey.load failed');
    }
  }

  static Future<void> _persist() async {
    try {
      await _storage.write(key: _storeKey, value: jsonEncode(_keys));
      await _storage.delete(key: _legacyKey);
    } catch (e) {
      debugPrint('AiKey.save failed'); // kept for this session only
    }
    changes.value++;
  }

  /// Adds a key at the end of the list. Returns false if the list is full or
  /// the key is already saved.
  static Future<bool> add(String key) async {
    final k = key.trim();
    if (isFull || _keys.contains(k)) return false;
    _keys = [..._keys, k];
    await _persist();
    return true;
  }

  static Future<void> removeAt(int i) async {
    if (i < 0 || i >= _keys.length) return;
    _keys = [..._keys]..removeAt(i);
    await _persist();
  }

  static Future<void> clear() async {
    _keys = [];
    await _persist();
  }
}
