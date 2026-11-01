import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veda_verse/state/app_state.dart';
import 'package:veda_verse/state/quiz_store.dart';

/// One VedaVerse account on this phone.
class Account {
  /// Unique id, e.g. "VV-3F9A21C7". Every saved item of the account is
  /// stored under it.
  final String id;
  final String email;
  final String salt;
  final String hash;
  final int created;

  const Account({required this.id, required this.email, required this.salt, required this.hash, required this.created});

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        email: j['email'] as String,
        salt: j['salt'] as String,
        hash: j['hash'] as String,
        created: (j['created'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object> toJson() => {'id': id, 'email': email, 'salt': salt, 'hash': hash, 'created': created};
}

/// Email + password accounts stored on this phone.
///
/// Each account has its own id and its own saved profile, quiz result and
/// daily ticks, so several people can share one phone. Passwords are never
/// stored: only a salted, repeated SHA-256 hash. Accounts do not sync between
/// phones yet; Firebase Authentication replaces this later.
class Accounts {
  Accounts._();

  static const _kAccounts = 'vv.accounts';
  static const _kSession = 'vv.session';
  static const minPassword = 6;

  static Account? _current;
  static Account? get current => _current;

  static String _profileKey(String id) => 'vv.u.$id.profile';

  /// The error texts below are English keys; show them with tr().
  static const errEmail = 'Enter a valid email, like name@gmail.com';
  static const errPassword = 'Password must be at least 6 characters';
  static const errMismatch = 'The two passwords don’t match';
  static const errExists = 'An account with this email already exists. Log in instead.';
  static const errNoAccount = 'No account with this email. Create an account first.';
  static const errWrongPassword = 'Wrong password. Please try again.';
  static const errStorage = 'Couldn’t save on this phone. Please try again.';

  static String normalise(String email) => email.trim().toLowerCase();

  static bool validEmail(String email) => RegExp(r'^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$').hasMatch(email.trim());

  static String _hash(String salt, String password) {
    List<int> d = utf8.encode('$salt:$password');
    for (var i = 0; i < 5000; i++) {
      d = sha256.convert(d).bytes;
    }
    return base64Url.encode(d);
  }

  static String _random(int bytes) {
    final r = Random.secure();
    return [for (var i = 0; i < bytes; i++) r.nextInt(256).toRadixString(16).padLeft(2, '0')].join();
  }

  static Future<List<Account>> all() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_kAccounts);
      if (raw == null) return [];
      return [for (final j in jsonDecode(raw) as List) Account.fromJson(j as Map<String, dynamic>)];
    } catch (e) {
      debugPrint('Accounts.all failed');
      return [];
    }
  }

  static Future<Account?> _find(String email) async {
    final e = normalise(email);
    for (final a in await all()) {
      if (a.email == e) return a;
    }
    return null;
  }

  /// Creates an account and logs into it with an empty profile. Returns an
  /// error key (see err*) or null on success.
  static Future<String?> signUp(String email, String password, {String? confirm}) async {
    if (!validEmail(email)) return errEmail;
    if (password.length < minPassword) return errPassword;
    if (confirm != null && confirm != password) return errMismatch;
    if (await _find(email) != null) return errExists;
    final list = await all();
    final ids = {for (final a in list) a.id};
    var id = '';
    do {
      id = 'VV-${_random(4).toUpperCase()}';
    } while (ids.contains(id));
    final salt = _random(16);
    final acc = Account(
      id: id,
      email: normalise(email),
      salt: salt,
      hash: _hash(salt, password),
      created: DateTime.now().millisecondsSinceEpoch,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAccounts, jsonEncode([...list.map((a) => a.toJson()), acc.toJson()]));
    } catch (e) {
      return errStorage;
    }
    _current = acc;
    QuizStore.user = acc.id;
    AppState.instance.resetForNewAccount(id: acc.id, email: acc.email);
    await _setSession(acc.id);
    await save();
    return null;
  }

  /// Logs into an existing account and loads its saved data. Returns an
  /// error key (see err*) or null on success.
  static Future<String?> logIn(String email, String password) async {
    if (!validEmail(email)) return errEmail;
    if (password.isEmpty) return errPassword;
    final acc = await _find(email);
    if (acc == null) return errNoAccount;
    if (_hash(acc.salt, password) != acc.hash) return errWrongPassword;
    await _open(acc);
    await _setSession(acc.id);
    return null;
  }

  static Future<void> _open(Account acc) async {
    _current = acc;
    QuizStore.user = acc.id;
    final s = AppState.instance;
    Map<String, Object?> profile = const {};
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_profileKey(acc.id));
      if (raw != null) profile = (jsonDecode(raw) as Map).cast<String, Object?>();
    } catch (e) {
      debugPrint('Accounts: profile unreadable, starting empty');
    }
    s.loadProfile(profile, id: acc.id, email: acc.email);
    await QuizStore.restore(s);
  }

  static Future<void> _setSession(String? id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      id == null ? await prefs.remove(_kSession) : await prefs.setString(_kSession, id);
    } catch (e) {
      debugPrint('Accounts: session not saved');
    }
  }

  /// At start-up: reopens the account that was logged in last time. Returns
  /// true when it has finished onboarding, so the app can open on Home.
  static Future<bool> restoreSession() async {
    try {
      final id = (await SharedPreferences.getInstance()).getString(_kSession);
      if (id == null) return false;
      final acc = (await all()).where((a) => a.id == id).firstOrNull;
      if (acc == null) return false;
      await _open(acc);
      return AppState.instance.onboarded;
    } catch (e) {
      debugPrint('Accounts.restoreSession failed');
      return false;
    }
  }

  /// Saves the logged-in account's profile and quiz data. Never throws.
  static Future<void> save() async {
    final acc = _current;
    if (acc == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey(acc.id), jsonEncode(AppState.instance.toProfile()));
      await QuizStore.save(AppState.instance);
    } catch (e) {
      debugPrint('Accounts.save failed');
    }
  }

  /// Marks consent + intake as done for this account.
  static Future<void> finishOnboarding() async {
    AppState.instance.update((s) => s.onboarded = true);
    await save();
  }

  /// Logs out. The account and its data stay on the phone for next time.
  static Future<void> logOut() async {
    await save();
    _current = null;
    QuizStore.user = null;
    AppState.instance.clearAccount();
    await _setSession(null);
  }

  /// Deletes the logged-in account and everything saved under its id from
  /// this phone (right to erasure), then logs out. Never throws.
  static Future<void> deleteCurrent() async {
    final acc = _current;
    if (acc == null) return;
    _current = null; // stop auto-save first
    QuizStore.user = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().where((k) => k.startsWith('vv.u.${acc.id}.')).toList()) {
        await prefs.remove(k);
      }
      final rest = [for (final a in await all()) if (a.id != acc.id) a.toJson()];
      await prefs.setString(_kAccounts, jsonEncode(rest));
    } catch (e) {
      debugPrint('Accounts.deleteCurrent failed');
    }
    AppState.instance.clearAccount();
    await _setSession(null);
  }

  /// Keeps saving the account whenever the app state changes.
  static void attach(AppState s) => s.addListener(save);

}
