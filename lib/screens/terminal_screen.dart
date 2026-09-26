// KodeKecil SSH — Terminal screen (xterm wired to an SSH shell).
import 'dart:async';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import '../models/host.dart';
import '../services/ssh_service.dart';
import '../theme.dart';
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
  bool _connected = false;
  bool _failed = false;
  String _hint = 'Connecting…';

  @override
  void initState() {
    super.initState();
    _terminal.write('KodeKecil SSH v0.1.0 — ${widget.host.label}\r\n');
    _connect();
  }

  Future<void> _connect() async {
    try {
      _conn =
          await SSHService().connect(widget.host, password: widget.password);
      _shell = await _conn!.openShell();
      _shell!.resizeTerminal(_terminal.viewWidth, _terminal.viewHeight);

      _terminal.onResize = (w, h, pw, ph) => _shell?.resizeTerminal(w, h);
      _terminal.onOutput = (data) {
        _shell?.stdin.add(Uint8List.fromList(data.codeUnits));
      };

      _shellSub = _shell!.stdout.listen(
        (data) => _terminal.write(String.fromCharCodes(data)),
        onDone: () => _setState(false, false, 'Connection closed.'),
        onError: (e) => _setState(false, true, 'Error: $e'),
      );
      _shell!.stderr
          .listen((data) => _terminal.write(String.fromCharCodes(data)));

      _setState(true, false, 'Connected');
    } catch (e) {
      _terminal.write('\r\n*** Connection failed: $e ***\r\n');
      _setState(false, true, 'Connection failed');
    }
  }

  void _setState(bool connected, bool failed, String hint) {
    if (!mounted) return;
    setState(() {
      _connected = connected;
      _failed = failed;
      _hint = hint;
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
    final dot =
        _failed ? KKColors.red : (_connected ? KKColors.green : KKColors.muted);
    return Scaffold(
      backgroundColor: KKColors.terminalBg,
      appBar: AppBar(
        backgroundColor: KKColors.rail,
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.host.label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _hint,
                    style: const TextStyle(fontSize: 11, color: KKColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_outlined),
            tooltip: 'SFTP browser',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SftpScreen(host: widget.host, password: widget.password),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: TerminalView(
          _terminal,
          padding: const EdgeInsets.all(10),
          textStyle: const TerminalStyle(
            fontSize: 13,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
