// KodeKecil SSH — Terminal screen (xterm wired to an SSH shell).
import 'dart:async';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import '../models/host.dart';
import '../services/ssh_service.dart';
import 'sftp_screen.dart';

class TerminalScreen extends StatefulWidget {
  final Host host;
  final String? password;

  const TerminalScreen({super.key, required this.host, this.password});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _terminal = Terminal(maxLines: 10000);
  SSHConnection? _conn;
  SSHSession? _shell;
  StreamSubscription<Uint8List>? _shellSub;
  String _status = 'Connecting…';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _terminal.write('KodeKecil SSH v0.1.0 — ${widget.host.label}\r\n');
    _connect();
  }

  Future<void> _connect() async {
    try {
      _conn = await SSHService()
          .connect(widget.host, password: widget.password);
      _shell = await _conn!.openShell();
      _shell!.resizeTerminal(_terminal.viewWidth, _terminal.viewHeight);

      _terminal.onResize = (w, h, pw, ph) => _shell?.resizeTerminal(w, h);

      _terminal.onOutput = (data) {
        _shell?.stdin.add(Uint8List.fromList(data.codeUnits));
      };

      _shellSub = _shell!.stdout.listen(
        (data) => _terminal.write(String.fromCharCodes(data)),
        onDone: () => _setStatus('Connection closed.', failed: false),
        onError: (e) => _setStatus('Error: $e', failed: true),
      );

      // stderr -> also show it in the terminal
      _shell!.stderr.listen((data) => _terminal.write(String.fromCharCodes(data)));

      _setStatus('Connected', failed: false);
    } catch (e) {
      _terminal.write('\r\n*** Connection failed: $e ***\r\n');
      _setStatus('Failed: $e', failed: true);
    }
  }

  void _setStatus(String s, {required bool failed}) {
    if (!mounted) return;
    setState(() {
      _status = s;
      _failed = failed;
    });
  }

  @override
  void dispose() {
    _shellSub?.cancel();
    _shell?.close();
    _conn?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.host.label, style: const TextStyle(fontFamily: 'monospace')),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'SFTP browser',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SftpScreen(host: widget.host, password: widget.password),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            color: _failed ? const Color(0xFF3A1414) : const Color(0xFF0F2A1A),
            child: Text(
              _status,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: _failed ? const Color(0xFFFF7B72) : const Color(0xFF7EE787),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TerminalView(
          _terminal,
          padding: const EdgeInsets.all(8),
          textStyle: const TerminalStyle(fontSize: 13),
        ),
      ),
    );
  }
}
