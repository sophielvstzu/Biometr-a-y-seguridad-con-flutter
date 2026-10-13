import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda datos sensibles de forma CIFRADA, uno por usuario.
/// - Android: llaves del Android Keystore.
/// - iOS: Keychain.
/// NUNCA uses SharedPreferences para tokens: queda en texto plano.
class TokenStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  // ---- Token de sesión (uno por usuario) ----
  Future<void> saveToken(String user, String token) =>
      _storage.write(key: 'token_$user', value: token);
  Future<String?> readToken(String user) => _storage.read(key: 'token_$user');
  Future<void> deleteToken(String user) => _storage.delete(key: 'token_$user');

  // ---- API key de un servicio de IA (una por usuario) ----
  Future<void> saveApiKey(String user, String key) =>
      _storage.write(key: 'ia_key_$user', value: key);
  Future<String?> readApiKey(String user) => _storage.read(key: 'ia_key_$user');
  Future<void> deleteApiKey(String user) => _storage.delete(key: 'ia_key_$user');
}