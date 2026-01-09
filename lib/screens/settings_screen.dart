import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatelessWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: Consumer<UserService>(
        builder: (context, userService, child) {
          final user = userService.currentUser;
          final level = userService.level;

          // Show a loading indicator while the user is being loaded
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle(context, 'Perfil de Usuario'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildUserInfoRow('Alias', user.alias),
                      const Divider(),
                      _buildUserInfoRow('Nivel', level.toString()),
                      const Divider(),
                      _buildUserInfoRow('Experiencia Total', user.totalExp.toString()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Tema'),
              Card(
                child: ListTile(
                  title: const Text('Modo Oscuro'),
                  trailing: Switch.adaptive(
                    value: themeService.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      themeService.toggleTheme();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Idioma'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Español'),
                      leading: Radio<Locale>(
                        value: const Locale('es'),
                        groupValue: languageService.appLocale,
                        onChanged: (val) {
                          if (val != null) languageService.changeLanguage(val);
                        },
                      ),
                      onTap: () => languageService.changeLanguage(const Locale('es')),
                    ),
                    ListTile(
                      title: const Text('English'),
                      leading: Radio<Locale>(
                        value: const Locale('en'),
                        groupValue: languageService.appLocale,
                        onChanged: (val) {
                          if (val != null) languageService.changeLanguage(val);
                        },
                      ),
                      onTap: () => languageService.changeLanguage(const Locale('en')),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 16.0),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
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
