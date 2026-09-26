// KodeKecil SSH — Host model.
class Host {
  final String id;
  final String label;
  final String hostname;
  final int port;
  final String username;
  final String group;
  final String authType; // 'password' | 'key'
  final String? keyId; // reference into secure storage, never the key itself

  const Host({
    required this.id,
    required this.label,
    required this.hostname,
    this.port = 22,
    required this.username,
    this.group = 'Default',
    this.authType = 'password',
    this.keyId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'hostname': hostname,
        'port': port,
        'username': username,
        'group': group,
        'authType': authType,
        'keyId': keyId,
      };

  factory Host.fromJson(Map<String, dynamic> json) => Host(
        id: json['id'] as String,
        label: json['label'] as String,
        hostname: json['hostname'] as String,
        port: (json['port'] as num?)?.toInt() ?? 22,
        username: json['username'] as String,
        group: json['group'] as String? ?? 'Default',
        authType: json['authType'] as String? ?? 'password',
        keyId: json['keyId'] as String?,
      );

  Host copyWith({
    String? label,
    String? hostname,
    int? port,
    String? username,
    String? group,
    String? authType,
    String? keyId,
  }) =>
      Host(
        id: id,
        label: label ?? this.label,
        hostname: hostname ?? this.hostname,
        port: port ?? this.port,
        username: username ?? this.username,
        group: group ?? this.group,
        authType: authType ?? this.authType,
        keyId: keyId ?? this.keyId,
      );
}
