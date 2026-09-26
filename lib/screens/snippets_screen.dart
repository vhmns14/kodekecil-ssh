// KodeKecil SSH — Snippets, Termius style.
//
// Save favorite commands; tap to copy, "..." for more actions.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/snippet.dart';
import '../services/host_store.dart';
import '../theme.dart';

class SnippetsScreen extends StatelessWidget {
  const SnippetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<HostStore>();
    final snippets = store.snippets;

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
                      'Snippets',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: KKColors.text,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon:
                          const Icon(Icons.add, color: KKColors.blue, size: 28),
                      tooltip: 'New snippet',
                      onPressed: () => _showAddDialog(context),
                    ),
                  ],
                ),
              ),
            ),
            if (snippets.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(
                    child: Text(
                      'No snippets yet.\nTap + to save a command.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: KKColors.muted, fontSize: 15),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final s = snippets[i];
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 8, 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: KKColors.surface,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          leading: const HostTile(
                            color: KKColors.green,
                            icon: Icons.code_rounded,
                            size: 46,
                          ),
                          title: Text(
                            s.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: KKColors.text,
                            ),
                          ),
                          subtitle: Text(
                            s.command,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: KKColors.muted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy_rounded,
                                    color: KKColors.blue),
                                tooltip: 'Copy',
                                onPressed: () => _copy(context, s),
                              ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_horiz,
                                    color: KKColors.muted),
                                onSelected: (v) {
                                  if (v == 'del') {
                                    store.removeSnippet(s.id);
                                  }
                                },
                                itemBuilder: (c) => const [
                                  PopupMenuItem(
                                      value: 'del', child: Text('Delete')),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _copy(context, s),
                        ),
                      ),
                    );
                  },
                  childCount: snippets.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context, Snippet s) {
    Clipboard.setData(ClipboardData(text: s.command));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied — paste into the terminal')),
    );
  }

  void _showAddDialog(BuildContext context) {
    final store = context.read<HostStore>();
    final title = TextEditingController();
    final command = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'New Snippet',
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
                title: 'Snippet',
                children: [
                  EditorField(controller: title, label: 'Title'),
                  EditorField(
                      controller: command, label: 'Command', maxLines: 3),
                ],
              ),
              const SizedBox(height: 20),
              WideBlueButton(
                label: 'Save Snippet',
                onPressed: () async {
                  if (command.text.trim().isEmpty) return;
                  await store.addSnippet(Snippet(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: title.text.trim().isEmpty
                        ? command.text.trim()
                        : title.text.trim(),
                    command: command.text.trim(),
                  ));
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
