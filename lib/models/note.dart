class Note {
  final int? id;
  final String title;
  final String content;
  final DateTime scheduledAt; // thời điểm nhắc
  final bool done;
  final String? ttsVoice; // giọng FPT (vd: "banmai")

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.scheduledAt,
    this.done = false,
    this.ttsVoice,
  });

  Note copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? scheduledAt,
    bool? done,
    String? ttsVoice,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      done: done ?? this.done,
      ttsVoice: ttsVoice ?? this.ttsVoice,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'scheduledAt': scheduledAt.millisecondsSinceEpoch,
        'done': done ? 1 : 0,
        'ttsVoice': ttsVoice,
      };

  static Note fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as int?,
        title: m['title'] as String,
        content: m['content'] as String,
        scheduledAt:
            DateTime.fromMillisecondsSinceEpoch(m['scheduledAt'] as int),
        done: (m['done'] as int) == 1,
        ttsVoice: m['ttsVoice'] as String?,
      );
}
