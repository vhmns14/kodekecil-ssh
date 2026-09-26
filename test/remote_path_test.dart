import 'package:flutter_test/flutter_test.dart';
import 'package:kodekecil_ssh/utils/remote_path.dart';

void main() {
  group('remoteJoin', () {
    test('joins relative to SFTP default dir', () {
      expect(remoteJoin('.', 'file.txt'), 'file.txt');
    });

    test('joins onto absolute dir', () {
      expect(remoteJoin('/home/user', 'docs'), '/home/user/docs');
    });

    test('normalizes dot segments', () {
      expect(remoteJoin('/home/user', './docs'), '/home/user/docs');
      expect(remoteJoin('/home/user', 'a/../b'), '/home/user/b');
    });

    test('rejects escaping above root via ..', () {
      expect(remoteJoin('/', '../etc'), '/etc');
    });
  });

  group('remoteParent', () {
    test('root stays at root', () {
      expect(remoteParent('/'), '/');
    });

    test('SFTP default dir stays put', () {
      expect(remoteParent('.'), '.');
    });

    test('returns parent directory', () {
      expect(remoteParent('/home/user/docs'), '/home/user');
      expect(remoteParent('/home'), '/');
    });
  });
}
