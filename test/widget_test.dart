import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:juegotodosmienten/main.dart';
import 'package:juegotodosmienten/services/user_service.dart';
import 'package:juegotodosmienten/services/language_service.dart';
import 'package:juegotodosmienten/services/theme_service.dart';
import 'package:juegotodosmienten/services/character_service.dart';
import 'package:juegotodosmienten/services/profanity_filter_service.dart';

// Imports needed for Firebase and user model mocking
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:juegotodosmienten/models/user_model.dart' as user_model;


// This is a common pattern for testing Flutter apps using Firebase.
// It mocks the native platform calls that Firebase makes during initialization.
typedef Callback = void Function(MethodCall call);

void setupFirebaseCoreMocks([Callback? customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();
  MethodChannelFirebase.channel.setMockMethodCallHandler((call) async {
    if (call.method == 'Firebase#initialize') {
      return [
        {
          'name': defaultFirebaseAppName,
          'options': {
            'apiKey': '123',
            'appId': '1:123:android:123',
            'messagingSenderId': '123',
            'projectId': 'test-project',
          },
          'pluginConstants': {},
        }
      ];
    }
    if (customHandlers != null) {
      customHandlers(call);
    }
    return null;
  });
}

// A mock version of UserService to control its state for tests.
// This mock simulates the behavior of a user who has not created an alias yet.
class MockUserService extends ChangeNotifier implements UserService {
  bool _isLoading = true;
  user_model.User? _currentUser;

  MockUserService() {
    loadUser();
  }

  @override
  bool get isLoading => _isLoading;

  @override
  bool get hasUser => _currentUser != null;

  @override
  user_model.User? get currentUser => _currentUser;

  @override
  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();
    // Simulate a network/database call
    await Future.delayed(const Duration(milliseconds: 50)); 
    _isLoading = false;
    _currentUser = null; // Simulate that no user was found
    notifyListeners();
  }
  
  // By using `noSuchMethod`, we avoid having to implement every single method
  // from the `UserService` interface, which makes our mock cleaner.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  // Setup Firebase mocks before any tests are run.
  setupFirebaseCoreMocks();

  // Initialize Firebase before the tests.
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Shows AliasCreationDialog when no user is found', (WidgetTester tester) async {
    // Build our app with all the necessary providers, using the MockUserService.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider(create: (_) => CharacterService()),
          ChangeNotifierProvider(create: (_) => LanguageService()),
          ChangeNotifierProvider(create: (_) => ThemeService()),
          ChangeNotifierProvider<UserService>(create: (_) => MockUserService()),
          Provider(create: (_) => ProfanityFilterService()),
        ],
        child: const TodosMientenApp(),
      ),
    );

    // The app first shows a loading indicator while Firebase initializes.
    expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: "Should show loading indicator during Firebase init");
    
    // Wait for all animations and futures to complete (e.g., Firebase init).
    await tester.pumpAndSettle();

    // After init, HomeScreen is shown, which uses UserService.
    // MockUserService simulates loading, so we might see another indicator.
    // pumpAndSettle should handle this as well.

    // Verify that the alias creation dialog is displayed because no user exists.
    expect(find.text('¡Bienvenido a Todos Mienten!'), findsOneWidget);
    expect(find.text('Elige un alias para empezar a jugar'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Guardar y Entrar'), findsOneWidget);
  });
}
