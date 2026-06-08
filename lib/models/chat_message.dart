class ChatMessage {
  ChatMessage({
    required this.id,
    required this.dialogId,
    required this.authorId,
    required this.sentAt,
    this.text = '',
    this.imageData,
    this.readBy = const [],
  });

  final String id;
  final String dialogId;
  final String authorId;
  final String text;
  final String? imageData;
  final DateTime sentAt;
  final List<String> readBy;

  ChatMessage copyWith({
    String? text,
    String? imageData,
    DateTime? sentAt,
    List<String>? readBy,
  }) {
    return ChatMessage(
      id: id,
      dialogId: dialogId,
      authorId: authorId,
      text: text ?? this.text,
      imageData: imageData ?? this.imageData,
      sentAt: sentAt ?? this.sentAt,
      readBy: readBy ?? this.readBy,
    );
  }

  bool isReadBy(String userId) => readBy.contains(userId);

  Map<String, dynamic> toJson() => {
        'id': id,
        'dialogId': dialogId,
        'authorId': authorId,
        'text': text,
        'imageData': imageData,
        'sentAt': sentAt.toIso8601String(),
        'readBy': readBy,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      dialogId: json['dialogId'] as String,
      authorId: json['authorId'] as String,
      text: json['text'] as String? ?? '',
      imageData: json['imageData'] as String?,
      sentAt: DateTime.tryParse(json['sentAt'] as String? ?? '') ?? DateTime.now(),
      readBy: (json['readBy'] as List<dynamic>? ?? const []).cast<String>(),
    );
  }
}
