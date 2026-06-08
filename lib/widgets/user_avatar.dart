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
          ? [const Color(0xFF7C8CFF), const Color(0xFF1B998B)]
          : [const Color(0xFF1B998B), const Color(0xFF5DE2D1)],
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
            : Image.memory(
                base64Decode(avatarData!),
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  String _initials(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}
