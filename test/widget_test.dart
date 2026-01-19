import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:juegotodosmienten/main.dart';

// Services
import 'package:juegotodosmienten/services/auth_service.dart';
import 'package:juegotodosmienten/services/character_service.dart';
import 'package:juegotodosmienten/services/firestore_service.dart';
import 'package:juegotodosmienten/services/language_service.dart';
import 'package:juegotodosmienten/services/profanity_filter_service.dart';
import 'package:juegotodosmienten/services/theme_service.dart';
import 'package:juegotodosmienten/services/user_service.dart';

// Firebase Mocking
import 'package:firebase_core/firebase_core.dart';
import 'utils/firebase_mock.dart'; // Corrected import path


void main() {
  // Configura los mocks de Firebase antes de que se ejecuten los tests.
  setupFirebaseCoreMocks();

  // Inicializa Firebase una sola vez para todos los tests.
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('MainLayout renders correctly with all buttons', (WidgetTester tester) async {
    // Construye la app con todos los proveedores necesarios.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => ProfanityFilterService()),
          Provider(create: (_) => FirestoreService()),
          Provider(create: (_) => CharacterService()),
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => LanguageService()),
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider(create: (_) => UserService()),
        ],
        child: const TodosMientenApp(),
      ),
    );

    // Espera a que la animación de carga inicial de Firebase termine.
    await tester.pumpAndSettle();

    // Verifica que el título principal se muestra.
    expect(find.text('TODOS MIENTEN'), findsOneWidget);

    // Verifica que los botones del menú principal están presentes.
    expect(find.text('EN LÍNEA'), findsOneWidget);
    expect(find.text('JUGAR EN LOCAL'), findsOneWidget);

    // Verifica que los botones de iconos laterales están presentes.
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.store), findsOneWidget);
  });
}
