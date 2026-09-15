import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_session.dart';
import 'token_store.dart';

/// Web token store: `shared_preferences` (localStorage-backed) — same
/// store as the app's other persisted prefs. Tokens in web storage are
/// readable by page scripts; accepted for the single-user MVP.
class PrefsTokenStore implements TokenStore {
  PrefsTokenStore({SharedPreferences? prefs}) : _prefs = prefs;

  static const _key = 'auth.session';

  SharedPreferences? _prefs;

  Future<SharedPreferences> _resolve() async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<AuthSession?> read() async {
    final prefs = await _resolve();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AuthSession.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) async {
    final prefs = await _resolve();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  @override
  Future<void> clear() async {
    final prefs = await _resolve();
    await prefs.remove(_key);
  }
}

TokenStore createTokenStore() => PrefsTokenStore();
