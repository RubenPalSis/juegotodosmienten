
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/navigation_service.dart';
import '../services/language_service.dart';
import 'home_screen.dart';

class AliasScreen extends StatefulWidget {
  static const routeName = '/alias';

  const AliasScreen({super.key});

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

    final langService = Provider.of<LanguageService>(context, listen: false);
    final userId = ModalRoute.of(context)!.settings.arguments as String;

    try {


      if (mounted) {
        NavigationService.pushReplacementNamed(HomeScreen.routeName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear el perfil: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea tu Alias'),
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
                    return 'El alias debe tener al menos 3 caracteres.';
                  }
                  if (RegExp(r'[^a-zA-Z0-9_]').hasMatch(value)) {
                    return 'Solo se permiten letras, números y guiones bajos.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitAlias,
                      child: const Text('Guardar y Entrar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
