// KodeKecil SSH — SSH connection service built on dartssh2.
import 'dart:async';
import 'package:dartssh2/dartssh2.dart';
import '../models/host.dart';
import 'secure_store.dart';

/// Wraps one SSH connection: shell + sftp.
class SSHConnection {
  final SSHClient client;

  SSHConnection(this.client);

  Future<SSHSession> openShell() => client.shell();

  Future<SftpClient> openSftp() => client.sftp();

  void close() => client.close();
}

class SSHService {
  /// Connect to [host].
  ///
  /// - password auth: [password] must be provided.
  /// - key auth: private key PEM is read from secure storage via [host.keyId].
  Future<SSHConnection> connect(Host host, {String? password}) async {
    final socket = await SSHSocket.connect(host.hostname, host.port);

    late final SSHClient client;
    if (host.authType == 'key') {
      final keyId = host.keyId;
      if (keyId == null) {
        socket.destroy();
        throw StateError('Host "${host.label}" needs a key but none is set.');
      }
      final pem = await SecureStore.instance.readKey(keyId);
      if (pem == null) {
        socket.destroy();
        throw StateError('Private key "$keyId" not found in secure storage.');
      }
      client = SSHClient(
        socket,
        username: host.username,
        // fromPem() returns List<SSHKeyPair> already.
        identities: SSHKeyPair.fromPem(pem),
      );
    } else {
      if (password == null) {
        socket.destroy();
        throw StateError('Password required for "${host.label}".');
      }
      client = SSHClient(
        socket,
        username: host.username,
        onPasswordRequest: () => password,
      );
    }
    return SSHConnection(client);
  }
}
