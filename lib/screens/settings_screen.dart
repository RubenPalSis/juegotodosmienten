import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../services/theme_service.dart';
import '../services/app_localizations.dart';
import '../utils/ui_helpers.dart';

// Definición de LanguageOption, corregida.
class LanguageOption {
  final Locale locale;
  final String nameKey;
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
  late Locale _selectedLocale;
  late ThemeMode _selectedThemeMode;
  bool _isLoading = false;
  bool _codeSent = false;

  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _helpSubjectController = TextEditingController();
  final _helpMessageController = TextEditingController();

  // La lista ahora usa la clase LanguageOption corregida.
  final List<LanguageOption> _languageOptions = [
    const LanguageOption(Locale('es'), 'language_spanish', '🇪🇸'),
    const LanguageOption(Locale('en'), 'language_english', '🇬🇧'),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageService = Provider.of<LanguageService>(
      context,
      listen: false,
    );
    final themeService = Provider.of<ThemeService>(context, listen: false);
    _selectedLocale = languageService.appLocale;
    _selectedThemeMode = themeService.themeMode;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _helpSubjectController.dispose();
    _helpMessageController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode(AuthService authService) async {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      showCustomSnackBar(
        context,
        localizations.translate('settings_email_invalid'),
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await authService.sendVerificationCode(
      _emailController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _codeSent = true);
      showCustomSnackBar(
        context,
        localizations.translate('settings_email_sent'),
      );
    } else {
      showCustomSnackBar(
        context,
        localizations.translate('settings_email_link_error'),
        isError: true,
      );
    }
  }

  Future<void> _verifyAndLinkAccount(AuthService authService) async {
    if (!mounted) return;
    final localizations = AppLocalizations.of(context)!;
    if (_codeController.text.isEmpty) {
      showCustomSnackBar(
        context,
        localizations.translate('settings_code_invalid'),
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await authService.verifyAndLinkAccount(
      _emailController.text,
      _codeController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showCustomSnackBar(
        context,
        localizations.translate('settings_email_link_success'),
      );
    } else {
      showCustomSnackBar(
        context,
        localizations.translate('settings_code_invalid'),
        isError: true,
      );
    }
  }

  Future<void> _unlinkAccount(AuthService authService) async {
    setState(() => _isLoading = true);
    await authService.unlinkEmail();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _codeSent = false;
      _emailController.clear();
      _codeController.clear();
    });
    showCustomSnackBar(context, "Tu cuenta ha sido desvinculada.");
  }

  Future<void> _sendHelpEmail(AuthService authService) async {
    if (_helpSubjectController.text.isEmpty ||
        _helpMessageController.text.isEmpty) {
      showCustomSnackBar(
        context,
        "Por favor, rellena todos los campos de ayuda.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await authService.sendHelpEmail(
      subject: _helpSubjectController.text,
      message: _helpMessageController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      showCustomSnackBar(context, "Email de ayuda enviado con éxito.");
      _helpSubjectController.clear();
      _helpMessageController.clear();
    } else {
      showCustomSnackBar(
        context,
        "Error al enviar el email de ayuda.",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context);

    final fabBackgroundColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final fabIconColor = isDarkMode ? Colors.white : Colors.lightBlue;

    final backgroundImage = isDarkMode
        ? 'assets/img/Backgound_darkMode.png'
        : 'assets/img/Background_lightMode.png';

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Image.asset(
            backgroundImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(
                        localizations.translate('settings_title'),
                      ),
                      _buildAccountSection(localizations, theme, authService),
                      const SizedBox(height: 30),
                      _buildSectionTitle(
                        localizations.translate('settings_section_general'),
                      ),
                      _buildThemeSection(localizations, theme),
                      const SizedBox(height: 16),
                      _buildLanguageSection(localizations, theme),
                      const SizedBox(height: 30),
                      _buildSectionTitle("Ayuda y Soporte"),
                      _buildHelpSection(theme, authService),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: FloatingActionButton(
              onPressed: () => Navigator.of(context).pop(),
              backgroundColor: fabBackgroundColor,
              child: Icon(Icons.arrow_back, color: fabIconColor),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildAccountSection(
    AppLocalizations localizations,
    ThemeData theme,
    AuthService authService,
  ) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.white.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.translate('settings_section_account'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Show unlink button if email is verified
          if (authService.isEmailVerified) ...[
            Text(
              "Correo vinculado: ${authService.userEmail}",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => _unlinkAccount(authService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? Colors.red.shade900
                      : Colors.red.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  textStyle: theme.textTheme.labelLarge,
                ),
                child: const Text("Desvincular Cuenta"),
              ),
            ),
          ] else ...[
            Text(
              localizations.translate('settings_account_description'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(
              _emailController,
              localizations.translate('settings_label_email'),
              theme: theme,
            ),
            if (_codeSent)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _buildTextField(
                  _codeController,
                  localizations.translate('settings_label_code'),
                  theme: theme,
                ),
              ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_codeSent
                          ? () => _verifyAndLinkAccount(authService)
                          : () => _sendVerificationCode(authService)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? Colors.blue.shade800
                      : Colors.lightBlueAccent,
                  foregroundColor: isDarkMode ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  textStyle: theme.textTheme.labelLarge,
                ),
                child: Text(
                  _codeSent
                      ? localizations.translate('settings_button_verify')
                      : localizations.translate('settings_button_send_code'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHelpSection(ThemeData theme, AuthService authService) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.white.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(_helpSubjectController, "Asunto", theme: theme),
          const SizedBox(height: 16),
          _buildTextField(
            _helpMessageController,
            "Mensaje",
            theme: theme,
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _sendHelpEmail(authService),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode
                    ? Colors.teal.shade800
                    : Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                textStyle: theme.textTheme.labelLarge,
              ),
              child: const Text("Enviar Mensaje de Ayuda"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(AppLocalizations localizations, ThemeData theme) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.white.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: SwitchListTile(
        title: Text(
          localizations.translate('settings_label_dark_mode'),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        value: _selectedThemeMode == ThemeMode.dark,
        onChanged: (value) {
          final newMode = value ? ThemeMode.dark : ThemeMode.light;
          Provider.of<ThemeService>(context, listen: false).setTheme(newMode);
          setState(() => _selectedThemeMode = newMode);
        },
        activeColor: Colors.lightBlueAccent,
      ),
    );
  }

  Widget _buildLanguageSection(
    AppLocalizations localizations,
    ThemeData theme,
  ) {
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.white.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonFormField<Locale>(
        value: _selectedLocale,
        dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.language,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          border: InputBorder.none,
        ),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        items: _languageOptions.map((option) {
          return DropdownMenuItem<Locale>(
            value: option.locale,
            child: Row(
              children: [
                Text(option.flag, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 16),
                Text(localizations.translate(option.nameKey)),
              ],
            ),
          );
        }).toList(),
        onChanged: (newLocale) async {
          if (newLocale != null) {
            await Provider.of<LanguageService>(
              context,
              listen: false,
            ).changeLanguage(newLocale);
            setState(() => _selectedLocale = newLocale);
          }
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    required ThemeData theme,
    int maxLines = 1,
  }) {
    final isDarkMode = theme.brightness == Brightness.dark;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black54,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white54 : Colors.black54,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: isDarkMode ? Colors.lightBlueAccent : Colors.blue.shade700,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
