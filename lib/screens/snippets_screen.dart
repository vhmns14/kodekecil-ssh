// KodeKecil SSH — Snippets: save favorite commands, tap to copy.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/snippet.dart';
import '../services/host_store.dart';

class SnippetsScreen extends StatelessWidget {
  const SnippetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HostStore>();
    final snippets = store.snippets;

    return Scaffold(
      appBar: AppBar(title: const Text('Snippets')),
      body: ListView.builder(
        itemCount: snippets.length,
        itemBuilder: (context, i) {
          final s = snippets[i];
          return ListTile(
            leading: const Icon(Icons.terminal, color: Color(0xFF2F81F7)),
            title: Text(s.title),
            subtitle: Text(s.command,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => store.removeSnippet(s.id),
            ),
            onTap: () {
              Clipboard.setData(ClipboardData(text: s.command));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied — paste into the terminal')),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final store = context.read<HostStore>();
    final title = TextEditingController();
    final command = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New snippet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(
              controller: command,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Command'),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await store.addSnippet(Snippet(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: title.text.trim(),
                command: command.text.trim(),
              ));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
