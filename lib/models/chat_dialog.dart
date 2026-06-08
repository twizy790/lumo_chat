class ChatDialog {
  ChatDialog({
    required this.id,
    required this.participantIds,
    required this.isGroup,
    required this.title,
    required this.createdAt,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.lastMessageSenderId,
  });

  final String id;
  final List<String> participantIds;
  final bool isGroup;
  final String title;
  final DateTime createdAt;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;

  ChatDialog copyWith({
    List<String>? participantIds,
    bool? isGroup,
    String? title,
    DateTime? createdAt,
    String? lastMessagePreview,
    DateTime? lastMessageAt,
    String? lastMessageSenderId,
  }) {
    return ChatDialog(
      id: id,
      participantIds: participantIds ?? this.participantIds,
      isGroup: isGroup ?? this.isGroup,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'participantIds': participantIds,
        'isGroup': isGroup,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'lastMessagePreview': lastMessagePreview,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
        'lastMessageSenderId': lastMessageSenderId,
      };

  factory ChatDialog.fromJson(Map<String, dynamic> json) {
    return ChatDialog(
      id: json['id'] as String,
      participantIds: (json['participantIds'] as List<dynamic>? ?? const []).cast<String>(),
      isGroup: json['isGroup'] as bool? ?? false,
      title: json['title'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      lastMessagePreview: json['lastMessagePreview'] as String?,
      lastMessageAt: DateTime.tryParse(json['lastMessageAt'] as String? ?? ''),
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
    );
  }
}
