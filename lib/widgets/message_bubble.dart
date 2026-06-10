import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/chat_dialog.dart';
import '../models/chat_message.dart';
import '../utils/formatters.dart';
import 'user_avatar.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.dialog,
    required this.isMe,
    required this.sender,
    required this.seenLabel,
  });

  final ChatMessage message;
  final ChatDialog dialog;
  final bool isMe;
  final AppUser sender;
  final String seenLabel;

  @override
  Widget build(BuildContext context) {
    final bg = isMe
        ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFB14CFF)])
        : LinearGradient(
            colors: [
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF251637)
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1A1029)
                  : Theme.of(context).colorScheme.surface,
            ],
          );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          UserAvatar(name: sender.name, avatarData: sender.avatarData, size: 32, isGroup: dialog.isGroup),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: bg,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dialog.isGroup && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      sender.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white70 : Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (message.imageData != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _messageImage(message.imageData!),
                  ),
                  if (message.text.isNotEmpty) const SizedBox(height: 8),
                ],
                if (message.text.isNotEmpty)
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatShortTime(message.sentAt),
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Text(
                        seenLabel,
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _messageImage(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(value, width: 240, fit: BoxFit.cover);
    }
    return Image.memory(base64Decode(value), width: 240, fit: BoxFit.cover);
  }
}
