// KodeKecil SSH — Hosts screen, Termius style.
//
// Big title, search, Date/Name sort, group cards, host rows with
// colored tiles, and a "Host Details" editor.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/host.dart';
import '../services/host_store.dart';
import '../services/secure_store.dart';
import '../theme.dart';
import 'terminal_screen.dart';

class HostListScreen extends StatefulWidget {
  const HostListScreen({super.key});

  @override
  State<HostListScreen> createState() => _HostListScreenState();
}

class _HostListScreenState extends State<HostListScreen> {
  String _query = '';
  bool _sortByName = false;
  String? _groupFilter;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HostStore>();
    final hosts = _visibleHosts(store.hosts);
    final groups = _groups(store.hosts);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    const Text(
                      'Hosts',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: KKColors.text,
                      ),
                    ),
                    const Spacer(),
                    SortSegmented(
                      sortByName: _sortByName,
                      onChanged: (v) => setState(() => _sortByName = v),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.add, color: KKColors.blue, size: 28),
                      tooltip: 'New host',
                      onPressed: () => _showHostEditor(context),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: KKSearchField(
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            if (groups.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionTitle('Groups')),
              SliverToBoxAdapter(child: _buildGroups(groups, store)),
            ],
            const SliverToBoxAdapter(child: SectionTitle('Hosts')),
            if (hosts.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'No servers yet.\nTap + to add one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: KKColors.muted, fontSize: 15),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _buildHostRow(context, hosts[i]),
                  childCount: hosts.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ----- data helpers -----

  List<String> _groups(List<Host> hosts) {
    final set = <String>{};
    for (final h in hosts) {
      set.add(h.group);
    }
    final list = set.toList()..sort();
    return list;
  }

  List<Host> _visibleHosts(List<Host> hosts) {
    var list = hosts.where((h) {
      if (_groupFilter != null && h.group != _groupFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return h.label.toLowerCase().contains(q) ||
          h.hostname.toLowerCase().contains(q) ||
          h.username.toLowerCase().contains(q);
    }).toList();
    if (_sortByName) {
      list.sort(
          (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    }
    return list;
  }

  int _countInGroup(List<Host> hosts, String group) =>
      hosts.where((h) => h.group == group).length;

  // ----- groups -----

  Widget _buildGroups(List<String> groups, HostStore store) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth > 560;
          final cols = wide ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 92,
            ),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final g = groups[i];
              final active = _groupFilter == g;
              return GestureDetector(
                onTap: () => setState(() => _groupFilter = active ? null : g),
                child: Container(
                  decoration: BoxDecoration(
                    color: active ? KKColors.surface2 : KKColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: active
                        ? Border.all(color: KKColors.blue, width: 1.5)
                        : null,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      HostTile(
                        color: KKColors.tileColorFor('group:$g'),
                        icon: Icons.grid_view_rounded,
                        size: 46,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              g,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: KKColors.text,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_countInGroup(store.hosts, g)} Hosts',
                              style: const TextStyle(
                                fontSize: 13,
                                color: KKColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ----- host rows -----

  Widget _buildHostRow(BuildContext context, Host h) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 8, 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _connect(context, h),
        child: Container(
          decoration: BoxDecoration(
            color: KKColors.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              HostTile(color: KKColors.tileColorFor(h.label)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: KKColors.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ssh, ${h.username}, ${h.group}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: KKColors.muted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: KKColors.muted),
                onSelected: (v) {
                  if (v == 'connect') _connect(context, h);
                  if (v == 'edit') _showHostEditor(context, existing: h);
                  if (v == 'delete') _confirmDelete(context, h);
                },
                itemBuilder: (c) => const [
                  PopupMenuItem(value: 'connect', child: Text('Connect')),
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- actions -----

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
          style: const TextStyle(color: KKColors.text),
          decoration: const InputDecoration(hintText: 'Password'),
          onSubmitted: (_) => Navigator.pop(context, ctrl.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: KKColors.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: KKColors.blue),
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Host h) async {
    final store = context.read<HostStore>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete server?'),
        content: Text(h.label),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child:
                const Text('Cancel', style: TextStyle(color: KKColors.muted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: KKColors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) store.removeHost(h.id);
  }

  // ----- host editor (Termius "Host Details" style) -----

  void _showHostEditor(BuildContext context, {Host? existing}) {
    final store = context.read<HostStore>();
    final label = TextEditingController(text: existing?.label ?? '');
    final hostname = TextEditingController(text: existing?.hostname ?? '');
    final port = TextEditingController(text: '${existing?.port ?? 22}');
    final username = TextEditingController(text: existing?.username ?? 'root');
    final group = TextEditingController(text: existing?.group ?? 'Default');
    final keyPem = TextEditingController();
    String authType = existing?.authType ?? 'password';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Host Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: KKColors.text,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: KKColors.muted),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  EditorSection(
                    title: 'Address',
                    children: [
                      EditorField(controller: hostname, label: 'Hostname / IP'),
                      Row(
                        children: [
                          const Text('SSH on',
                              style: TextStyle(color: KKColors.muted)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: EditorField(
                              controller: port,
                              label: 'Port',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  EditorSection(
                    title: 'General',
                    children: [
                      EditorField(controller: label, label: 'Label'),
                      EditorField(controller: username, label: 'Username'),
                      EditorField(controller: group, label: 'Group'),
                    ],
                  ),
                  EditorSection(
                    title: 'Credentials',
                    children: [
                      Row(
                        children: [
                          _authChip('Password', 'password', authType,
                              (v) => setState(() => authType = v)),
                          const SizedBox(width: 8),
                          _authChip('Private key', 'key', authType,
                              (v) => setState(() => authType = v)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (authType == 'key')
                        EditorField(
                          controller: keyPem,
                          label: 'Private key (PEM)',
                          maxLines: 5,
                        )
                      else
                        const Text(
                          'The password is asked on every connect and never stored.',
                          style: TextStyle(color: KKColors.muted, fontSize: 13),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  WideBlueButton(
                    label: existing == null ? 'Add Host' : 'Save',
                    onPressed: () async {
                      final id = existing?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString();
                      String? keyId;
                      if (authType == 'key' && keyPem.text.trim().isNotEmpty) {
                        keyId = 'key_$id';
                        // Private keys live ONLY in the OS keyring.
                        await SecureStore.instance
                            .saveKey(keyId, keyPem.text.trim());
                      }
                      final host = Host(
                        id: id,
                        label: label.text.trim().isEmpty
                            ? hostname.text.trim()
                            : label.text.trim(),
                        hostname: hostname.text.trim(),
                        port: int.tryParse(port.text.trim()) ?? 22,
                        username: username.text.trim().isEmpty
                            ? 'root'
                            : username.text.trim(),
                        group: group.text.trim().isEmpty
                            ? 'Default'
                            : group.text.trim(),
                        authType: authType,
                        keyId: authType == 'key'
                            ? (keyId ?? existing?.keyId)
                            : null,
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
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _authChip(
      String label, String value, String current, ValueChanged<String> onTap) {
    final active = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? KKColors.blue : KKColors.surface2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : KKColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
