import 'package:flutter/material.dart';
import 'app_data.dart'; // Or wherever kPlaceholderAvatars / kAvatarAssetPaths are

class AvatarSelectionScreen extends StatelessWidget {
  final int? currentAvatarIndex;
  final bool useIconPlaceholders; // Add this flag

  const AvatarSelectionScreen({
    super.key, 
    this.currentAvatarIndex,
    this.useIconPlaceholders = false, // Default to false (expecting assets)
  });

  @override
  Widget build(BuildContext context) {
    final avatarCount = useIconPlaceholders ? kPlaceholderAvatars.length : kAvatarAssetPaths.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Avatar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.0,
                ),
                itemCount: avatarCount,
                itemBuilder: (context, index) {
                  bool isSelected = index == currentAvatarIndex;
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context, index); // Return selected index
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.15),
                            spreadRadius: 1,
                            blurRadius: 3,
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0), // Padding inside the avatar item
                          child: useIconPlaceholders
                              ? Icon(kPlaceholderAvatars[index], size: 50, color: Colors.grey.shade700)
                              : Image.asset(kAvatarAssetPaths[index], fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
                child:ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, currentAvatarIndex);
                },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorDark,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            )
          ],
        ),
      ),
    );
  }
}