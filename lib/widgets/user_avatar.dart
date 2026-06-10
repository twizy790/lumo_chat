import 'dart:convert';

import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.avatarData,
    this.size = 48,
    this.isGroup = false,
  });

  final String name;
  final String? avatarData;
  final double size;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final gradient = LinearGradient(
      colors: isGroup
          ? [const Color(0xFFC77DFF), const Color(0xFF5B21B6)]
          : [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: avatarData == null ? gradient : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarData == null
            ? Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: size * 0.36,
                  ),
                ),
              )
            : _avatarImage(avatarData!),
      ),
    );
  }

  Widget _avatarImage(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(value, fit: BoxFit.cover);
    }
    return Image.memory(base64Decode(value), fit: BoxFit.cover);
  }

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
