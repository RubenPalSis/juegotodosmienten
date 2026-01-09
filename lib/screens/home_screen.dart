import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../widgets/main_layout.dart';
import '../widgets/alias_creation_dialog.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserService>(
        builder: (context, userService, child) {
          if (userService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (!userService.hasUser) {
            // Show the alias creation dialog if no user is found
            return const AliasCreationDialog();
          } else {
            // Show the main layout if the user exists
            return const MainLayout();
          }
        },
      ),
    );
  }
}
