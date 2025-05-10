// lib/player_profile_bar.dart
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:mathzy/app_data.dart'; // For avatar and country data
// To potentially fetch data if needed directly, or pass it

class PlayerProfileBar extends StatelessWidget {
  final String? userName;
  final int? avatarIndex;
  final String? countryCodeISO;
  final VoidCallback onEditProfile;
  final bool useIconPlaceholdersForAvatar; // From WelcomeScreen for consistency

  const PlayerProfileBar({
    super.key,
    required this.userName,
    this.avatarIndex,
    this.countryCodeISO,
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
    if (countryCodeISO != null && countryCodeISO!.isNotEmpty) {
      try {
        // Attempt to get CountryCode object to access its flagUri
        // This is a bit of a workaround as the picker is UI, not just data access.
        // The package primarily uses CountryCode for its internal display.
        // A more direct way would be if the package exposed a static method
        // to get flag URI from ISO code.
        
        // For direct flag display using the package's assets, if the CountryCode
        // object provides a direct path to its flag asset, you can use it.
        // Example: if CountryCode object has a flagUri property:
        final country = CountryCode.fromCountryCode(countryCodeISO!); // May throw if code not found
        if (country.flagUri != null) {
           return Image.asset(
             country.flagUri!,
             package: 'country_code_picker',
             width: 28,
             height: 20,
             fit: BoxFit.contain,
             errorBuilder: (context, error, stackTrace) => const Icon(Icons.public, size: 22, color: Colors.black54),
           );
        }
      } catch (e) {
        // Fallback if code not found or other error
        // print("Error getting flag for $countryCodeISO: $e");
      }
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
      child: GestureDetector(
        onTap: onEditProfile,
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey.shade300,
              child: _getAvatarWidget(),
            ),
            const SizedBox(width: 10),
            Text(
              userName ?? 'Player', // Default name
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 10),
            _getFlagWidget(),
          ],
        ),
      ),
    );
  }
}