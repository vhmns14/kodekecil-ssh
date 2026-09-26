import 'package:flutter_test/flutter_test.dart';
import 'package:kodekecil_ssh/models/snippet.dart';

void main() {
  test('Snippet JSON round-trip preserves fields', () {
    const s = Snippet(id: '1', title: 'Disk usage', command: 'df -h');
    final restored = Snippet.fromJson(s.toJson());
    expect(restored.id, '1');
    expect(restored.title, 'Disk usage');
    expect(restored.command, 'df -h');
  });
}
