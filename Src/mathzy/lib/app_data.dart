// lib/app_data.dart (or constants.dart)
import 'package:flutter/material.dart';

// Placeholder: Replace with your actual asset paths or more complex avatar objects
final List<String> kAvatarAssetPaths = List.generate(9, (index) => 'assets/avatars/avatar_${index + 1}.png');
// For simplicity, if you don't have assets yet, use Icons:
final List<IconData> kPlaceholderAvatars = [
  Icons.face_retouching_natural, Icons.face, Icons.account_circle,
  Icons.tag_faces, Icons.person_outline, Icons.emoji_emotions,
  Icons.face_2_outlined, Icons.face_3_outlined, Icons.face_4_outlined,
];


