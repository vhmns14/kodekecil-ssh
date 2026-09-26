// KodeKecil SSH — SFTP browser.
//
// Browse, upload, download, rename, delete, mkdir. All transfers show progress.
import 'dart:io';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../utils/remote_path.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/host.dart';
import '../services/ssh_service.dart';

class SftpScreen extends StatefulWidget {
  final Host host;
  final String? password;

  const SftpScreen({super.key, required this.host, this.password});

  @override
  State<SftpScreen> createState() => _SftpScreenState();
}

class _SftpScreenState extends State<SftpScreen> {
  SSHConnection? _conn;
  SftpClient? _sftp;
  String _cwd = '.';
  List<SftpName> _entries = [];
  String _status = 'Connecting…';
  bool _busy = false;
  double? _progress; // 0..1, null = indeterminate
  String _progressLabel = '';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      _conn = await SSHService().connect(widget.host, password: widget.password);
      _sftp = await _conn!.openSftp();
      await refresh();
    } catch (e) {
      _setStatus('Failed: $e');
    }
  }

  void _setStatus(String s) {
    if (!mounted) return;
    setState(() => _status = s);
  }

  Future<void> refresh() async {
    if (_sftp == null) return;
    setState(() => _busy = true);
    try {
      final entries = await _sftp!.listdir(_cwd);
      entries.sort((a, b) {
        final ad = a.attr.isDirectory ? 0 : 1;
        final bd = b.attr.isDirectory ? 0 : 1;
        if (ad != bd) return ad - bd;
        return a.filename.compareTo(b.filename);
      });
      if (!mounted) return;
      setState(() {
        _entries = entries.where((e) => e.filename != '.' && e.filename != '..').toList();
        _status = 'OK';
      });
    } catch (e) {
      _setStatus('Failed to list directory: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _remote(String name) => remoteJoin(_cwd, name);

  void _enter(String dir) {
    setState(() => _cwd = remoteJoin(_cwd, dir));
    refresh();
  }

  void _goUp() {
    setState(() => _cwd = remoteParent(_cwd));
    refresh();
  }

  void _showProgress(String label) {
    setState(() {
      _busy = true;
      _progress = 0;
      _progressLabel = label;
    });
  }

  void _hideProgress() {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _progress = null;
      _progressLabel = '';
    });
  }

  Future<Directory> _downloadDir() async {
    return await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
  }

  Future<void> _download(SftpName entry) async {
    final total = entry.attr.size ?? 0;
    final destDir = await _downloadDir();
    final dest = File(p.join(destDir.path, entry.filename));
    _showProgress('Download ${entry.filename}');
    try {
      final sink = dest.openWrite();
      await _sftp!.download(
        _remote(entry.filename),
        sink,
        onProgress: (read) {
          if (!mounted || total <= 0) return;
          setState(() => _progress = read / total);
        },
        closeDestination: true,
      );
      _setStatus('Tersimpan: ${dest.path}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded to ${dest.path}')),
        );
      }
    } catch (e) {
      _setStatus('Download failed: $e');
    } finally {
      _hideProgress();
    }
  }

  Future<void> _upload() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return;
    final file = picked.single;
    final bytes = await file.readAsBytes();
    final remotePath = _remote(file.name);
    _showProgress('Upload ${file.name}');
    const chunk = 64 * 1024;
    try {
      final f = await _sftp!.open(
        remotePath,
        mode: SftpFileOpenMode.write |
            SftpFileOpenMode.create |
            SftpFileOpenMode.truncate,
      );
      try {
        var sent = 0;
        while (sent < bytes.length) {
          final end = (sent + chunk > bytes.length) ? bytes.length : sent + chunk;
          await f.writeBytes(
            Uint8List.fromList(bytes.sublist(sent, end)),
            offset: sent,
          );
          sent = end;
          if (mounted) setState(() => _progress = sent / bytes.length);
        }
      } finally {
        await f.close();
      }
      _setStatus('Upload OK: ${file.name}');
      await refresh();
    } catch (e) {
      _setStatus('Upload failed: $e');
    } finally {
      _hideProgress();
    }
  }

  Future<void> _rename(SftpName entry) async {
    final ctrl = TextEditingController(text: entry.filename);
    final newName = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == entry.filename) return;
    try {
      await _sftp!.rename(_remote(entry.filename), _remote(newName));
      await refresh();
    } catch (e) {
      _setStatus('Rename failed: $e');
    }
  }

  Future<void> _delete(SftpName entry) async {
    final isDir = entry.attr.isDirectory;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${isDir ? "folder" : "file"}?'),
        content: Text(entry.filename),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      if (isDir) {
        await _sftp!.rmdir(_remote(entry.filename));
      } else {
        await _sftp!.remove(_remote(entry.filename));
      }
      await refresh();
    } catch (e) {
      _setStatus('Delete failed: $e');
    }
  }

  Future<void> _mkdir() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('New folder'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text.trim()), child: const Text('OK')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await _sftp!.mkdir(_remote(name));
      await refresh();
    } catch (e) {
      _setStatus('mkdir failed: $e');
    }
  }

  String _fmtSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  @override
  void dispose() {
    _conn?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_cwd, style: const TextStyle(fontFamily: 'monospace', fontSize: 15)),
        actions: [
          IconButton(icon: const Icon(Icons.arrow_upward), tooltip: 'Naik', onPressed: _goUp),
          IconButton(icon: const Icon(Icons.create_new_folder), tooltip: 'New folder', onPressed: _mkdir),
          IconButton(icon: const Icon(Icons.upload_file), tooltip: 'Upload', onPressed: _upload),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: refresh),
        ],
        bottom: _busy && _progress != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(value: _progress),
                      ),
                      const SizedBox(width: 8),
                      Text(_progressLabel,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(_status, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
          if (_busy && _progress == null)
            const LinearProgressIndicator(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: refresh,
              child: ListView.builder(
                itemCount: _entries.length,
                itemBuilder: (context, i) {
                  final e = _entries[i];
                  final isDir = e.attr.isDirectory;
                  return ListTile(
                    leading: Icon(
                      isDir ? Icons.folder : Icons.insert_drive_file,
                      color: isDir ? const Color(0xFF2F81F7) : null,
                    ),
                    title: Text(e.filename, style: const TextStyle(fontFamily: 'monospace')),
                    subtitle: isDir ? null : Text(_fmtSize(e.attr.size)),
                    onTap: isDir ? () => _enter(e.filename) : null,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'dl') _download(e);
                        if (v == 'rn') _rename(e);
                        if (v == 'del') _delete(e);
                      },
                      itemBuilder: (c) => [
                        if (!isDir)
                          const PopupMenuItem(value: 'dl', child: Text('Download')),
                        const PopupMenuItem(value: 'rn', child: Text('Rename')),
                        const PopupMenuItem(value: 'del', child: Text('Delete')),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
