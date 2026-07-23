import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartstitch/ai/config/ai_config.dart';

/// Lightweight cache using SharedPreferences.
/// Caches: detected language, role context summary, conversation snippets.
class AiCache {
  static const _keyLanguage = 'ai_lang';
  static const _keyContextPrefix = 'ai_ctx_';
  static const _keyTimestampPrefix = 'ai_ts_';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Language ──────────────────────────────────────────────────────────────

  Future<void> setLanguage(String lang) async {
    final s = await _store;
    await s.setString(_keyLanguage, lang);
  }

  Future<String> getLanguage() async {
    final s = await _store;
    return s.getString(_keyLanguage) ?? 'en';
  }

  // ── Context summary (per user) ────────────────────────────────────────────

  Future<void> setContext(String userId, Map<String, dynamic> ctx) async {
    final s = await _store;
    final key = '$_keyContextPrefix$userId';
    final tsKey = '$_keyTimestampPrefix$userId';
    await s.setString(key, jsonEncode(ctx));
    await s.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>?> getContext(String userId) async {
    final s = await _store;
    final tsKey = '$_keyTimestampPrefix$userId';
    final ts = s.getInt(tsKey);
    if (ts == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > AiConfig.cacheExpiry.inMilliseconds) {
      await _clearContext(userId, s);
      return null;
    }

    final raw = s.getString('$_keyContextPrefix$userId');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearContext(String userId, SharedPreferences s) async {
    await s.remove('$_keyContextPrefix$userId');
    await s.remove('$_keyTimestampPrefix$userId');
  }

  Future<void> clearAll() async {
    final s = await _store;
    final keys = s.getKeys().where(
          (k) => k.startsWith(_keyContextPrefix) || k.startsWith(_keyTimestampPrefix),
        );
    for (final k in keys) {
      await s.remove(k);
    }
  }
}
