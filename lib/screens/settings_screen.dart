import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/firestore_service.dart';
import '../services/app_localizations.dart'; // Import localizations

// A simple class to represent a language option
class LanguageOption {
  final Locale locale;
  final String nameKey; // Use a key for translation
  final String flag;

  const LanguageOption(this.locale, this.nameKey, this.flag);
}

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Local state to track pending changes
  late Locale _selectedLocale;
  late ThemeMode _selectedThemeMode;
  bool _hasChanges = false;

  // Use keys for language names
  final List<LanguageOption> _languageOptions = [
    const LanguageOption(Locale('es'), 'language_spanish', '🇪🇸'),
    const LanguageOption(Locale('en'), 'language_english', '🇬🇧'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize local state with current provider values
    _selectedLocale = Provider.of<LanguageService>(context, listen: false).appLocale;
    _selectedThemeMode = Provider.of<ThemeService>(context, listen: false).themeMode;
  }

  void _saveChanges() async {
    final langService = Provider.of<LanguageService>(context, listen: false);
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = Provider.of<UserService>(context, listen: false).currentUser;
    final localizations = AppLocalizations.of(context)!;

    // Save language if changed
    if (langService.appLocale != _selectedLocale) {
      await langService.changeLanguage(_selectedLocale);
      if (user != null) {
        // Also update in Firestore
        await firestoreService.updateUserLanguage(user.alias, _selectedLocale.languageCode);
      }
    }

    // Save theme if changed
    if (themeService.themeMode != _selectedThemeMode) {
      themeService.setTheme(_selectedThemeMode);
    }

    // Hide the save button and show a confirmation
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(localizations.translate('settings_changes_saved'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('settings_title')),
      ),
      body: Consumer<UserService>(
        builder: (context, userService, child) {
          if (userService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = userService.currentUser;
          final level = userService.level;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    if (user != null)
                      ..._buildUserProfileSection(context, user, level, localizations),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, localizations.translate('settings_section_theme')),
                    _buildThemeSection(context, localizations),
                    const SizedBox(height: 24),
                    _buildSectionTitle(context, localizations.translate('settings_section_language')),
                    _buildLanguageSection(context, localizations),
                  ],
                ),
              ),
              if (_hasChanges)
                _buildSaveChangesButton(localizations),
            ],
          );
        },
      ),
    );
  }

  // --- Section Builder Widgets ---

  List<Widget> _buildUserProfileSection(BuildContext context, user, int level, AppLocalizations localizations) {
    return [
      _buildSectionTitle(context, localizations.translate('settings_section_user_profile')),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildUserInfoRow(localizations.translate('settings_label_alias'), user.alias),
              const Divider(),
              _buildUserInfoRow(localizations.translate('settings_label_level'), level.toString()),
              const Divider(),
              _buildUserInfoRow(localizations.translate('settings_label_total_exp'), user.totalExp.toString()),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildThemeSection(BuildContext context, AppLocalizations localizations) {
    return Card(
      child: SwitchListTile.adaptive(
        title: Text(localizations.translate('settings_label_dark_mode')),
        value: _selectedThemeMode == ThemeMode.dark,
        onChanged: (value) {
          setState(() {
            _selectedThemeMode = value ? ThemeMode.dark : ThemeMode.light;
            _hasChanges = true;
          });
        },
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context, AppLocalizations localizations) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButtonFormField<Locale>(
          initialValue: _selectedLocale,
          decoration: const InputDecoration(
            border: InputBorder.none, // Clean look
            contentPadding: EdgeInsets.zero,
          ),
          items: _languageOptions.map((option) {
            return DropdownMenuItem<Locale>(
              value: option.locale,
              child: Row(
                children: [
                  Text(option.flag, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 16),
                  Text(localizations.translate(option.nameKey)), // Translate language name
                ],
              ),
            );
          }).toList(),
          onChanged: (newLocale) {
            if (newLocale != null) {
              setState(() {
                _selectedLocale = newLocale;
                _hasChanges = true;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildSaveChangesButton(AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _saveChanges,
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        child: Text(localizations.translate('settings_button_save')),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildUserInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}
