// lib/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:mathzy/service_preferences.dart';
import 'package:mathzy/screen_avatar_selection.dart';
import 'package:mathzy/app_data.dart';
import 'package:mathzy/main.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Or your game screen import

class WelcomeScreen extends StatefulWidget {
  final bool isEditingProfile; // New flag

  const WelcomeScreen({super.key, this.isEditingProfile = false}); // Default to false

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final PreferencesService _prefsService = PreferencesService();

  int? _selectedAvatarIndex;
  Country? _selectedCountry;
  bool _isLoading = true; // For loading existing data when editing

  final bool _useIconPlaceholdersForAvatar = true; // Keep consistent

  @override
  void initState() {
    super.initState();
    if (widget.isEditingProfile) {
      _loadExistingProfileData();
    } else {
      setState(() {
        _isLoading = false; // Not loading if it's the first run
      });
    }
  }

  Future<void> _loadExistingProfileData() async {
    _nameController.text = await _prefsService.getUserName() ?? "";
    _selectedAvatarIndex = await _prefsService.getAvatarIndex();
    final countryCode = await _prefsService.getCountryCode();
    if (countryCode != null) {
      _selectedCountry = kAppCountries.firstWhere((c) => c.code == countryCode, orElse: () => null as Country);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _buildAvatarDisplay() {
    // ... (remains the same as previous version) ...
    Widget avatarContent;
    if (_selectedAvatarIndex != null && _selectedAvatarIndex! >= 0) { // Check for non-negative index
      if (_useIconPlaceholdersForAvatar && _selectedAvatarIndex! < kPlaceholderAvatars.length) {
        avatarContent = Icon(kPlaceholderAvatars[_selectedAvatarIndex!], size: 60, color: Colors.grey.shade800);
      } else if (!_useIconPlaceholdersForAvatar && _selectedAvatarIndex! < kAvatarAssetPaths.length) {
        avatarContent = Image.asset(kAvatarAssetPaths[_selectedAvatarIndex!], width: 80, height: 80, fit: BoxFit.cover);
      } else {
        avatarContent = const Icon(Icons.person, size: 60, color: Colors.grey);
      }
    } else {
      avatarContent = const Icon(Icons.add_a_photo_outlined, size: 60, color: Colors.grey);
    }

    return GestureDetector(
      onTap: _selectAvatar,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Center(child: avatarContent),
      ),
    );
  }

  void _selectAvatar() async {
    // ... (remains the same as previous version) ...
    final result = await Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder: (context) => AvatarSelectionScreen(
          currentAvatarIndex: _selectedAvatarIndex,
          useIconPlaceholders: _useIconPlaceholdersForAvatar,
        ),
      ),
    );

    if (result != null && result >=0) {
      setState(() {
        _selectedAvatarIndex = result;
      });
    } else if (result == null || result == -1) { 
        setState(() {
             // If user explicitly chose "no avatar" or backed out without choosing one
             // and previously had one, we might want to clear it.
             // If they just backed out, keep the previous one.
             // For simplicity, allow setting to null if they came from a state of having one.
             _selectedAvatarIndex = (result == -1) ? null : _selectedAvatarIndex;
        });
    }
  }

  Future<void> _onContinueOrSave() async { // Renamed for clarity
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      await _prefsService.saveUserName(_nameController.text.trim());
      if (_selectedAvatarIndex != null && _selectedAvatarIndex! >= 0) { // Save only valid index
        await _prefsService.saveAvatarIndex(_selectedAvatarIndex!);
      } else {
        // If clearing avatar, save a specific value like -1 or remove the key
        await _prefsService.saveAvatarIndex(-1); // Or handle null appropriately in service
      }

      if (_selectedCountry != null) {
        await _prefsService.saveCountryCode(_selectedCountry!.code);
      } else {
        // If clearing country, remove the key or save an empty string
        final prefs = await SharedPreferences.getInstance(); // Temporary instance
        await prefs.remove('mathzy_country_code'); // Example of removing key
      }


      if (!widget.isEditingProfile) { // Only set first run completed if not editing
        await _prefsService.setFirstRunCompleted();
      }

      if (mounted) {
        if (widget.isEditingProfile) {
          Navigator.pop(context, true); // Pop with a result indicating changes might have been made
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MathScribbleGame()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: widget.isEditingProfile ? AppBar(title: const Text("Edit Profile")) : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (!widget.isEditingProfile) ...[
                  const Text(
                    'Let\'s Get Started!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Personalize your experience.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                ],

                _buildAvatarDisplay(),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _selectAvatar,
                  child: Text(widget.isEditingProfile ? 'Change Avatar' : 'Choose Avatar (Optional)'),
                ),
                const SizedBox(height: 30),

                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name*',
                    hintText: 'E.g., Alex',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 24),

                DropdownButtonFormField<Country>(
                  decoration: InputDecoration(
                    labelText: 'Country (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                     prefixIcon: _selectedCountry != null 
                                  ? Padding(padding: const EdgeInsets.all(10.0), child: Text(_selectedCountry!.flagEmoji, style: const TextStyle(fontSize: 18))) 
                                  : const Icon(Icons.flag_outlined),
                  ),
                  value: _selectedCountry,
                  hint: const Text('Select your country'),
                  isExpanded: true,
                  items: kAppCountries.map((Country country) {
                    return DropdownMenuItem<Country>(
                      value: country,
                      child: Row(
                        children: [
                          Text(country.flagEmoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(country.name, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (Country? newValue) {
                    setState(() {
                      _selectedCountry = newValue;
                    });
                  },
                ),
                const SizedBox(height: 50),

                ElevatedButton(
                  onPressed: _onContinueOrSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorDark,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(widget.isEditingProfile ? 'Save Changes' : 'Continue', style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}