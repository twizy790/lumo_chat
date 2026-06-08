import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_user.dart';
import '../models/chat_dialog.dart';
import '../models/chat_message.dart';
import '../services/app_controller.dart';
import '../widgets/app_scope.dart';
import '../widgets/message_bubble.dart';
import '../widgets/section_card.dart';
import '../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.dialogId});

  final String dialogId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.of(context).markDialogRead(widget.dialogId);
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final dialog = controller.dialogs.where((item) => item.id == widget.dialogId).firstOrNull;
    final me = controller.currentUser;
    if (dialog == null || me == null) {
      return const Scaffold(body: Center(child: Text('Диалог не найден')));
    }

    final messages = controller.messagesForDialog(dialog.id);
    final displayMessages = messages.reversed.toList();
    final otherUsers = dialog.participantIds
        .where((id) => id != me.id)
        .map((id) => controller.users.where((user) => user.id == id).firstOrNull)
        .whereType<AppUser>()
        .toList();
    final participantsText = dialog.isGroup
        ? '${dialog.participantIds.length} участников'
        : (otherUsers.isNotEmpty ? otherUsers.first.name : dialog.title);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(
              name: dialog.title,
              avatarData: dialog.isGroup || otherUsers.isEmpty ? null : otherUsers.first.avatarData,
              size: 38,
              isGroup: dialog.isGroup,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dialog.isGroup ? dialog.title : participantsText),
                Text(
                  dialog.isGroup ? participantsText : 'Личный чат',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (dialog.isGroup)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SectionCard(
                child: Text(
                  'Групповой чат: ${dialog.participantIds.length} участников',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: displayMessages.length,
              itemBuilder: (context, index) {
                final message = displayMessages[index];
                final isMe = message.authorId == me.id;
                final sender = controller.users.where((user) => user.id == message.authorId).firstOrNull;
                if (sender == null) return const SizedBox.shrink();
                final seenLabel = _seenLabel(dialog, message, me.id);
                return MessageBubble(
                  message: message,
                  dialog: dialog,
                  isMe: isMe,
                  sender: sender,
                  seenLabel: seenLabel,
                );
              },
            ),
          ),
          _Composer(
            controller: controller,
            dialog: dialog,
            textController: _text,
          ),
        ],
      ),
    );
  }

  String _seenLabel(ChatDialog dialog, ChatMessage message, String myId) {
    if (message.authorId != myId) return '';
    final others = dialog.participantIds.where((id) => id != myId).toList();
    if (others.isEmpty) return '✓';
    final seenCount = message.readBy.where((id) => id != myId).length;
    if (seenCount == 0) return '✓';
    if (!dialog.isGroup && seenCount > 0) return '✓✓';
    return 'seen $seenCount/${others.length}';
  }
}

class _Composer extends StatefulWidget {
  const _Composer({
    required this.controller,
    required this.dialog,
    required this.textController,
  });

  final AppController controller;
  final ChatDialog dialog;
  final TextEditingController textController;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _busy ? null : _pickImage,
              icon: const Icon(Icons.add_photo_alternate_outlined),
            ),
            Expanded(
              child: TextField(
                controller: widget.textController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Написать сообщение...',
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : _sendText,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendText() async {
    final text = widget.textController.text;
    if (text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.controller.sendTextMessage(widget.dialog.id, text);
      widget.textController.clear();
      await widget.controller.markDialogRead(widget.dialog.id);
    } on MessengerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickImage() async {
    setState(() => _busy = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final encoded = base64Encode(bytes);
      await widget.controller.sendTextMessage(
        widget.dialog.id,
        widget.textController.text,
        imageData: encoded,
      );
      widget.textController.clear();
    } on MessengerException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
