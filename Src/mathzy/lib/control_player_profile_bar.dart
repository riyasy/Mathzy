// lib/player_profile_bar.dart
import 'package:flutter/material.dart';
import 'package:mathzy/app_data.dart'; // For avatar and country data
// To potentially fetch data if needed directly, or pass it

class PlayerProfileBar extends StatelessWidget {
  final String? userName;
  final int? avatarIndex;
  final String? countryCode;
  final VoidCallback onEditProfile;
  final bool useIconPlaceholdersForAvatar; // From WelcomeScreen for consistency

  const PlayerProfileBar({
    super.key,
    required this.userName,
    this.avatarIndex,
    this.countryCode,
    required this.onEditProfile,
    this.useIconPlaceholdersForAvatar = true, // Match WelcomeScreen's default
  });

  Widget _getAvatarWidget() {
    if (avatarIndex != null && avatarIndex! >= 0) {
      if (useIconPlaceholdersForAvatar && avatarIndex! < kPlaceholderAvatars.length) {
        return Icon(kPlaceholderAvatars[avatarIndex!], size: 24, color: Colors.black87);
      } else if (!useIconPlaceholdersForAvatar && avatarIndex! < kAvatarAssetPaths.length) {
        return ClipOval(
          child: Image.asset(
            kAvatarAssetPaths[avatarIndex!],
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 24, color: Colors.black87),
          ),
        );
      }
    }
    return const Icon(Icons.account_circle, size: 24, color: Colors.black87); // Default avatar
  }

  Widget _getFlagWidget() {
    if (countryCode != null && countryCode!.isNotEmpty) {
      final country = kAppCountries.firstWhere((c) => c.code == countryCode, orElse: () => kAppCountries.first); // Fallback needed
      // A simple way to find, but might be slow if kAppCountries is huge. Consider a map.
      return Text(country.flagEmoji, style: const TextStyle(fontSize: 20));
        }
    return const Icon(Icons.public, size: 22, color: Colors.black54); // Default global icon
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      // color: Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0.1) ?? Colors.blueGrey.shade100, // Subtle background
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onEditProfile,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              child: _getAvatarWidget(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              userName ?? 'Player', // Default name
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          _getFlagWidget(),
        ],
      ),
    );
  }
}