import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_service.dart';
import '../services/firestore_service.dart';
import '../services/language_service.dart';
import '../services/navigation_service.dart';
import 'home_screen.dart';
import 'lobby_screen.dart';

class AliasScreen extends StatefulWidget {
  static const routeName = '/alias';
  final String? roomCodeToJoin;

  const AliasScreen({super.key, this.roomCodeToJoin});

  @override
  State<AliasScreen> createState() => _AliasScreenState();
}

class _AliasScreenState extends State<AliasScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitAlias() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    final alias = _aliasController.text.trim();
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final langService = Provider.of<LanguageService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final uid = userCredential.user?.uid;

      if (uid == null) throw Exception('Authentication failed');

      final isTaken = await firestoreService.isAliasTaken(alias);
      if (isTaken) {
        messenger.showSnackBar(const SnackBar(content: Text('This alias is already taken.')));
        setState(() => _isLoading = false);
        return;
      }

      await firestoreService.createUserProfile(alias: alias, uid: uid, language: langService.appLocale.languageCode);
      
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.createUser(alias, uid);

      // Navigate based on whether a room code was provided
      if (widget.roomCodeToJoin != null) {
        NavigationService.pushReplacementNamed(LobbyScreen.routeName, arguments: {'roomCode': widget.roomCodeToJoin});
      } else {
        NavigationService.pushReplacementNamed(HomeScreen.routeName);
      }

    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error creating user: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Alias'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _aliasController,
                decoration: const InputDecoration(labelText: 'Alias'),
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'Alias must be at least 3 characters long.';
                  }
                  if (RegExp(r'[^a-zA-Z0-9_]').hasMatch(value)) {
                    return 'Only letters, numbers, and underscores are allowed.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitAlias,
                      child: const Text('Save and Enter'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
