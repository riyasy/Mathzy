// lib/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:mathzy/app_data.dart';
import 'package:mathzy/main.dart';
import 'package:mathzy/screen_avatar_selection.dart';
import 'package:mathzy/service_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  final bool isEditingProfile;

  const WelcomeScreen({super.key, this.isEditingProfile = false});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final PreferencesService _prefsService = PreferencesService();

  int? _selectedAvatarIndex;
  String? _selectedCountryCodeISO; // Store the ISO code like "US", "IN"
  bool _isLoading = true;

  final bool _useIconPlaceholdersForAvatar = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEditingProfile) {
      _loadExistingProfileData();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingProfileData() async {
    _nameController.text = await _prefsService.getUserName() ?? "";
    _selectedAvatarIndex = await _prefsService.getAvatarIndex();
    _selectedCountryCodeISO =
        await _prefsService.getCountryCode(); // This now loads the ISO code
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
    Widget avatarContent;
    if (_selectedAvatarIndex != null && _selectedAvatarIndex! >= 0) {
      if (_useIconPlaceholdersForAvatar &&
          _selectedAvatarIndex! < kPlaceholderAvatars.length) {
        avatarContent = Icon(
          kPlaceholderAvatars[_selectedAvatarIndex!],
          size: 60,
        );
      } else if (!_useIconPlaceholdersForAvatar &&
          _selectedAvatarIndex! < kAvatarAssetPaths.length) {
        avatarContent = Image.asset(
          kAvatarAssetPaths[_selectedAvatarIndex!],
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        );
      } else {
        avatarContent = const Icon(Icons.person, size: 60, color: Colors.grey);
      }
    } else {
      avatarContent = const Icon(
        Icons.add_a_photo_outlined,
        size: 60,
        color: Colors.grey,
      );
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
    final result = await Navigator.push<int?>(
      context,
      MaterialPageRoute(
        builder:
            (context) => AvatarSelectionScreen(
              currentAvatarIndex: _selectedAvatarIndex,
              useIconPlaceholders: _useIconPlaceholdersForAvatar,
            ),
      ),
    );
    if (result != null && result >= 0) {
      setState(() {
        _selectedAvatarIndex = result;
      });
    } else if (result == -1) {
      // Handle "no avatar" explicitly if needed
      setState(() {
        _selectedAvatarIndex = null;
      });
    }
  }

  void _onCountryChange(CountryCode countryCode) {
    setState(() {
      _selectedCountryCodeISO = countryCode.code; // Store the ISO code
    });
  }

  Future<void> _onContinueOrSave() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      await _prefsService.saveUserName(_nameController.text.trim());

      if (_selectedAvatarIndex != null && _selectedAvatarIndex! >= 0) {
        await _prefsService.saveAvatarIndex(_selectedAvatarIndex!);
      } else {
        await _prefsService.saveAvatarIndex(-1); // Indicate no avatar or clear
      }

      if (_selectedCountryCodeISO != null &&
          _selectedCountryCodeISO!.isNotEmpty) {
        await _prefsService.saveCountryCode(_selectedCountryCodeISO!);
      } else {
        // If no country selected, explicitly clear it from prefs
        await _prefsService.clearCountryCode();
      }

      if (!widget.isEditingProfile) {
        await _prefsService.setFirstRunCompleted();
      }

      if (mounted) {
        if (widget.isEditingProfile) {
          Navigator.pop(context, true);
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
      appBar:
          widget.isEditingProfile
              ? AppBar(
                title:
                    widget.isEditingProfile
                        ? const Text("Edit Profile")
                        : const Text("Create Profile"),
              )
              : null,
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
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 24),
                  decoration: InputDecoration(
                    // labelText: 'Your Name*',
                    hintText: 'Your Name - E.g., Alex',
                    // border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    // prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 80),

                // --- CountryCodePicker Integration ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: CountryCodePicker(
                    onChanged: _onCountryChange,
                    initialSelection:
                        _selectedCountryCodeISO, // Set initial selection from prefs
                    showCountryOnly: true, // Shows only country name and flag
                    showOnlyCountryWhenClosed:
                        true, // Shows only country name and flag when popup is closed
                    alignLeft: true,
                    favorite: const [
                      'US',
                      'IN',
                      'GB',
                      'CA',
                      'AU',
                    ], // Optional: Add some favorites
                    // To show a globe icon when nothing is selected, we need to manage the display
                    // ourselves or customize the picker. The picker itself might not directly show
                    // a globe icon for 'no selection' in its main display.
                    // We can wrap it or use its builder if available for more control.
                    // For now, it will show the 'initialSelection' or the first favorite/default.
                    // If _selectedCountryCodeISO is null, it might default to a favorite or region.
                    // To ensure "Select Country" or globe is shown, we might need to
                    // conditionally display text *next* to it or use a placeholder before selection.

                    // Custom builder for the displayed widget part
                    builder: (countryCode) {
                      if (countryCode == null &&
                          _selectedCountryCodeISO == null) {
                        // Nothing selected and no initial value from prefs
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.public,
                              size: 100,
                              color: Colors.grey.shade700,
                            ), // Larger globe
                            const SizedBox(height: 6),
                            Text(
                              "Select Country",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }
                      // If a country is selected (either initially or by user)
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (countryCode?.flagUri !=
                              null) // The package handles flag display
                            Image.asset(
                              countryCode!.flagUri!,
                              package: 'country_code_picker',
                              width: 100.0,
                              height: 100.0,
                              fit: BoxFit.contain,
                            ),
                          if (countryCode?.flagUri == null &&
                              _selectedCountryCodeISO == null)
                            const Icon(Icons.public, color: Colors.grey),
                          const SizedBox(width: 8.0),
                          Text(
                            countryCode?.name ?? "Select Country",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 24,
                            ),
                          ), // Display country name
                        ],
                      );
                    },
                    // Optional: control padding of the picker dialog
                    dialogBackgroundColor: Theme.of(context).canvasColor,
                    dialogTextStyle: Theme.of(context).textTheme.bodyMedium,
                    searchDecoration: const InputDecoration(
                      hintText: "Search country",
                    ),
                    emptySearchBuilder:
                        (context) =>
                            const Center(child: Text("No country found")),
                  ),
                ),

                // --- End CountryCodePicker ---
                const SizedBox(height: 100),
                ElevatedButton(
                  onPressed: _onContinueOrSave,
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
                    widget.isEditingProfile ? 'Save Changes' : 'Continue',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
