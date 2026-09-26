// KodeKecil SSH — Remote POSIX path helpers (SFTP).
//
// Kept in a pure utility so path logic is unit-testable without an SSH server.
import 'package:path/path.dart' as p;

/// Join [name] onto remote directory [dir], normalizing `.` / `..` segments.
///
/// Always uses POSIX separators regardless of the local platform.
String remoteJoin(String dir, String name) =>
    p.posix.normalize(p.posix.join(dir, name));

/// Parent of a remote path; root's parent is root, and the SFTP default
/// directory ('.') stays at '.'.
String remoteParent(String path) {
  final normalized = p.posix.normalize(path);
  if (normalized == '/') return '/';
  final parent = p.posix.dirname(normalized);
  return parent.isEmpty ? '.' : parent;
}
