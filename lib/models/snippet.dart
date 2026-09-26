// KodeKecil SSH — Snippet model (reusable command snippets).
class Snippet {
  final String id;
  final String title;
  final String command;

  const Snippet({required this.id, required this.title, required this.command});

  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'command': command};

  factory Snippet.fromJson(Map<String, dynamic> json) => Snippet(
        id: json['id'] as String,
        title: json['title'] as String,
        command: json['command'] as String,
      );
}
