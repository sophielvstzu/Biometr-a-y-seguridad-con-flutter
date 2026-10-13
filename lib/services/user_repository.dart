import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_account.dart';

/// Registro de usuarios del dispositivo (guardado CIFRADO en secure storage).
/// Cerrar sesión NO borra usuarios: así la huella/PIN siempre funcionan.
class UserRepository {
  static const _kUsers = 'users_v1';
  static const _kLast = 'last_user';

  final FlutterSecureStorage _s = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  // ---- utilidades de hash ----
  String _newSalt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  String _hash(String salt, String kind, String value) =>
      sha256.convert(utf8.encode('$salt:$kind:$value')).toString();

  bool checkPassword(UserAccount u, String password) =>
      _hash(u.salt, 'pw', password) == u.passwordHash;

  bool checkPin(UserAccount u, String pin) => _hash(u.salt, 'pin', pin) == u.pinHash;

  // ---- CRUD ----
  Future<List<UserAccount>> all() async {
    final raw = await _s.read(key: _kUsers);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => UserAccount.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveAll(List<UserAccount> users) =>
      _s.write(key: _kUsers, value: jsonEncode(users.map((u) => u.toJson()).toList()));

  Future<UserAccount> register({
    required String username,
    required String displayName,
    required String password,
    required String pin,
  }) async {
    final users = await all();
    final uname = username.trim().toLowerCase();
    if (users.any((u) => u.username == uname)) {
      throw Exception('Ese usuario ya existe');
    }
    final salt = _newSalt();
    final user = UserAccount(
      username: uname,
      displayName: displayName.trim(),
      salt: salt,
      passwordHash: _hash(salt, 'pw', password),
      pinHash: _hash(salt, 'pin', pin),
    );
    await _saveAll([...users, user]);
    return user;
  }

  Future<void> delete(String username) async {
    final users = await all();
    await _saveAll(users.where((u) => u.username != username).toList());
  }

  // ---- último usuario que entró ----
  Future<String?> lastUser() => _s.read(key: _kLast);
  Future<void> setLastUser(String username) => _s.write(key: _kLast, value: username);
}