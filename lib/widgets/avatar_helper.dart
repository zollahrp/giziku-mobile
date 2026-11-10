import 'dart:convert';
import 'package:flutter/material.dart';

ImageProvider getProfileImageProvider(String? photoUrl) {
  if (photoUrl == null || photoUrl.trim().isEmpty) {
    return const AssetImage('assets/profile/profile.png');
  }
  final clean = photoUrl.trim();
  if (clean.startsWith('data:image') || clean.startsWith('data:application')) {
    try {
      final base64Str = clean.contains(',') ? clean.split(',').last : clean;
      return MemoryImage(base64Decode(base64Str.trim()));
    } catch (_) {
      return const AssetImage('assets/profile/profile.png');
    }
  }
  try {
    return NetworkImage(clean);
  } catch (_) {
    return const AssetImage('assets/profile/profile.png');
  }
}

