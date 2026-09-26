// KodeKecil SSH — Host repository.
//
// v0.1: JSON file in the app documents directory. No secrets here —
// private keys and saved passwords live in SecureStore (OS keyring).
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/host.dart';
import '../models/snippet.dart';
import 'secure_store.dart';

class HostStore extends ChangeNotifier {
  List<Host> _hosts = [];
  List<Snippet> _snippets = [];

  List<Host> get hosts => List.unmodifiable(_hosts);
  List<Snippet> get snippets => List.unmodifiable(_snippets);

  List<String> get groups {
    final set = <String>{..._hosts.map((h) => h.group)};
    final list = set.toList()..sort();
    return list;
  }

  Future<File> _dbFile() async {
    // Prefer the documents dir; fall back gracefully on systems where
    // path_provider cannot resolve it (minimal containers, odd XDG setups).
    Directory? dir;
    for (final getter in [
      getApplicationDocumentsDirectory,
      getApplicationSupportDirectory,
    ]) {
      try {
        dir = await getter();
        break;
      } catch (_) {
        // try the next candidate
      }
    }
    dir ??= Directory(
        p.join(Platform.environment['HOME'] ?? '.', '.kodekecil-ssh'));
    await dir.create(recursive: true);
    return File(p.join(dir.path, 'kodekecil_ssh.json'));
  }

  Future<void> load() async {
    try {
      final file = await _dbFile();
      if (!await file.exists()) {
        _seed();
        return;
      }
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _hosts = (data['hosts'] as List? ?? [])
          .map((e) => Host.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      _snippets = (data['snippets'] as List? ?? [])
          .map((e) => Snippet.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      _seed();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final file = await _dbFile();
    await file.writeAsString(jsonEncode({
      'hosts': _hosts.map((h) => h.toJson()).toList(),
      'snippets': _snippets.map((s) => s.toJson()).toList(),
    }));
  }

  void _seed() {
    _snippets = const [
      Snippet(
          id: 's1',
          title: 'Update & upgrade',
          command: 'sudo apt update && sudo apt upgrade -y'),
      Snippet(id: 's2', title: 'Disk usage', command: 'df -h'),
      Snippet(
          id: 's3',
          title: 'Docker ps',
          command:
              'docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"'),
    ];
  }

  Future<void> addHost(Host host) async {
    _hosts.add(host);
    await _persist();
    notifyListeners();
  }

  Future<void> updateHost(Host host) async {
    final i = _hosts.indexWhere((h) => h.id == host.id);
    if (i != -1) {
      _hosts[i] = host;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> removeHost(String id) async {
    final i = _hosts.indexWhere((h) => h.id == id);
    if (i == -1) return;
    final host = _hosts[i];
    _hosts.removeAt(i);
    await _persist();
    // Wipe secrets too: private key + saved password must not linger.
    if (host.keyId != null) {
      await SecureStore.instance.deleteKey(host.keyId!);
    }
    await SecureStore.instance.deletePassword(host.id);
    notifyListeners();
  }

  Future<void> addSnippet(Snippet s) async {
    _snippets.add(s);
    await _persist();
    notifyListeners();
  }

  Future<void> removeSnippet(String id) async {
    _snippets.removeWhere((s) => s.id == id);
    await _persist();
    notifyListeners();
  }
}
