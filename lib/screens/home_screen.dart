import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../widgets/main_layout.dart';
import '../widgets/alias_creation_dialog.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/';

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isDialogVisible = false;

  @override
  void initState() {
    super.initState();
    // Comprobación inicial después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userService = Provider.of<UserService>(context, listen: false);
      if (!userService.hasUser && !userService.isLoading) {
        _showAliasDialogIfNeeded();
      }
    });
  }

  void _showAliasDialogIfNeeded() {
    if (_isDialogVisible || !mounted) return;

    setState(() => _isDialogVisible = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AliasCreationDialog(),
    ).then((_) {
      if (mounted) {
        setState(() => _isDialogVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserService>(
      builder: (context, userService, child) {
        // Comprueba el estado en cada rebuild y planifica mostrar el diálogo si es necesario.
        if (!userService.hasUser && !userService.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showAliasDialogIfNeeded();
          });
        }

        return Scaffold(
          body: Stack(
            children: [
              const MainLayout(),
              // Muestra un indicador de carga global si el servicio está ocupado
              if (userService.isLoading)
                Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }
}
