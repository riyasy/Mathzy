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


class Country {
  final String name;
  final String code; // ISO 3166-1 alpha-2 code
  final String flagEmoji;

  Country({required this.name, required this.code, required this.flagEmoji});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

final List<Country> kAppCountries = [
  Country(name: "United States", code: "US", flagEmoji: "🇺🇸"),
  Country(name: "India", code: "IN", flagEmoji: "🇮🇳"),
  Country(name: "Canada", code: "CA", flagEmoji: "🇨🇦"),
  Country(name: "United Kingdom", code: "GB", flagEmoji: "🇬🇧"),
  Country(name: "Australia", code: "AU", flagEmoji: "🇦🇺"),
  Country(name: "Germany", code: "DE", flagEmoji: "🇩🇪"),
  Country(name: "Japan", code: "JP", flagEmoji: "🇯🇵"),
  // Add more countries
];