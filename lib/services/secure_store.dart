// KodeKecil SSH — Secure storage for private keys & passwords.
//
// Android: Android Keystore. Linux: Secret Service (GNOME Keyring / KWallet).
// Nothing secret ever touches the app's plain files or database.
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore._();
  static final SecureStore instance = SecureStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  String _keyRef(String id) => 'sshkey_$id';
  String _passRef(String hostId) => 'sshpass_$hostId';

  Future<void> saveKey(String id, String pem) =>
      _storage.write(key: _keyRef(id), value: pem);

  Future<String?> readKey(String id) => _storage.read(key: _keyRef(id));

  Future<void> deleteKey(String id) => _storage.delete(key: _keyRef(id));

  /// Optional: remember password per host (user opt-in only).
  Future<void> savePassword(String hostId, String password) =>
      _storage.write(key: _passRef(hostId), value: password);

  Future<String?> readPassword(String hostId) =>
      _storage.read(key: _passRef(hostId));

  Future<void> deletePassword(String hostId) =>
      _storage.delete(key: _passRef(hostId));
}
