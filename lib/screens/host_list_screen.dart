// KodeKecil SSH — Host list + add/edit dialog.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/host.dart';
import '../services/host_store.dart';
import '../services/secure_store.dart';
import 'terminal_screen.dart';

class HostListScreen extends StatelessWidget {
  const HostListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HostStore>();
    final hosts = store.hosts;

    return Scaffold(
      appBar: AppBar(title: const Text('KodeKecil SSH')),
      body: hosts.isEmpty
          ? const Center(
              child: Text(
                'No servers yet.\nAdd one with the + button',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.builder(
              itemCount: hosts.length,
              itemBuilder: (context, i) {
                final h = hosts[i];
                return ListTile(
                  leading: const Icon(Icons.dns, color: Color(0xFF2F81F7)),
                  title: Text(h.label, style: const TextStyle(fontFamily: 'monospace')),
                  subtitle: Text('${h.username}@${h.hostname}:${h.port} • ${h.group}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _showHostDialog(context, existing: h),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Delete server?'),
                              content: Text(h.label),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancel')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (ok == true) store.removeHost(h.id);
                        },
                      ),
                    ],
                  ),
                  onTap: () => _connect(context, h),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHostDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _connect(BuildContext context, Host host) async {
    String? password;
    if (host.authType == 'password') {
      password = await _askPassword(context, host);
      if (password == null) return;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TerminalScreen(host: host, password: password),
      ),
    );
  }

  Future<String?> _askPassword(BuildContext context, Host host) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Password — ${host.label}'),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'password'),
          onSubmitted: (_) => Navigator.pop(context, ctrl.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showHostDialog(BuildContext context, {Host? existing}) {
    final store = context.read<HostStore>();
    final label = TextEditingController(text: existing?.label ?? '');
    final hostname = TextEditingController(text: existing?.hostname ?? '');
    final port = TextEditingController(text: '${existing?.port ?? 22}');
    final username = TextEditingController(text: existing?.username ?? 'root');
    final group = TextEditingController(text: existing?.group ?? 'Default');
    String authType = existing?.authType ?? 'password';
    final keyPem = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'Add server' : 'Edit server'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: label, decoration: const InputDecoration(labelText: 'Label')),
                TextField(controller: hostname, decoration: const InputDecoration(labelText: 'Hostname / IP')),
                Row(
                  children: [
                    Expanded(child: TextField(controller: port, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Port'))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: username, decoration: const InputDecoration(labelText: 'Username'))),
                  ],
                ),
                TextField(controller: group, decoration: const InputDecoration(labelText: 'Group')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: authType,
                  items: const [
                    DropdownMenuItem(value: 'password', child: Text('Password')),
                    DropdownMenuItem(value: 'key', child: Text('Private key')),
                  ],
                  onChanged: (v) => setState(() => authType = v ?? 'password'),
                  decoration: const InputDecoration(labelText: 'Auth'),
                ),
                if (authType == 'key')
                  TextField(
                    controller: keyPem,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Private key (PEM)',
                      hintText: '-----BEGIN OPENSSH PRIVATE KEY-----',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final id = existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
                String? keyId;
                if (authType == 'key' && keyPem.text.trim().isNotEmpty) {
                  keyId = 'key_$id';
                  // Private keys are ONLY stored in the OS keyring, never the database.
                  await SecureStore.instance.saveKey(keyId, keyPem.text.trim());
                }
                final host = Host(
                  id: id,
                  label: label.text.trim().isEmpty ? hostname.text.trim() : label.text.trim(),
                  hostname: hostname.text.trim(),
                  port: int.tryParse(port.text.trim()) ?? 22,
                  username: username.text.trim().isEmpty ? 'root' : username.text.trim(),
                  group: group.text.trim().isEmpty ? 'Default' : group.text.trim(),
                  authType: authType,
                  // Switching away from key auth orphans the old key: wipe it.
                  keyId: authType == 'key' ? (keyId ?? existing?.keyId) : null,
                );
                if (authType != 'key' && existing?.keyId != null) {
                  await SecureStore.instance.deleteKey(existing!.keyId!);
                }
                if (existing == null) {
                  await store.addHost(host);
                } else {
                  await store.updateHost(host);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
