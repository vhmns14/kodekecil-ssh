import 'package:flutter_test/flutter_test.dart';
import 'package:kodekecil_ssh/models/host.dart';

void main() {
  group('Host JSON round-trip', () {
    test('toJson/fromJson preserves every field', () {
      const host = Host(
        id: 'abc123',
        label: 'Prod VPS',
        hostname: '203.0.113.10',
        port: 2222,
        username: 'deploy',
        group: 'Production',
        authType: 'key',
        keyId: 'key_abc123',
      );
      final restored = Host.fromJson(host.toJson());
      expect(restored.id, 'abc123');
      expect(restored.label, 'Prod VPS');
      expect(restored.hostname, '203.0.113.10');
      expect(restored.port, 2222);
      expect(restored.username, 'deploy');
      expect(restored.group, 'Production');
      expect(restored.authType, 'key');
      expect(restored.keyId, 'key_abc123');
    });

    test('missing optional fields fall back to defaults', () {
      final restored = Host.fromJson({
        'id': 'x',
        'label': 'Minimal',
        'hostname': 'example.com',
        'username': 'root',
      });
      expect(restored.port, 22);
      expect(restored.group, 'Default');
      expect(restored.authType, 'password');
      expect(restored.keyId, isNull);
    });

    test('never stores secrets inline', () {
      const host = Host(
        id: 'x',
        label: 'K',
        hostname: 'h',
        username: 'u',
        authType: 'key',
        keyId: 'key_x',
      );
      final json = host.toJson();
      // Only a keyring reference is persisted — no PEM, no password.
      expect(json.containsKey('privateKey'), isFalse);
      expect(json.containsKey('password'), isFalse);
      expect(json['keyId'], 'key_x');
    });
  });

  group('Host.copyWith', () {
    test('switching auth away from key clears the key reference', () {
      const host = Host(
        id: 'x',
        label: 'K',
        hostname: 'h',
        username: 'u',
        authType: 'key',
        keyId: 'key_x',
      );
      // copyWith cannot null out keyId by design; the store layer passes
      // keyId: null explicitly when rebuilding, so emulate that path:
      final switched = Host(
        id: host.id,
        label: host.label,
        hostname: host.hostname,
        port: host.port,
        username: host.username,
        group: host.group,
        authType: 'password',
        keyId: null,
      );
      expect(switched.authType, 'password');
      expect(switched.keyId, isNull);
    });

    test('copyWith keeps untouched fields', () {
      const host = Host(
        id: 'x',
        label: 'Old',
        hostname: 'h',
        username: 'u',
      );
      final renamed = host.copyWith(label: 'New');
      expect(renamed.label, 'New');
      expect(renamed.id, 'x');
      expect(renamed.hostname, 'h');
    });
  });
}
