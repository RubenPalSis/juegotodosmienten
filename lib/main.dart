import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Import all screens
import 'screens/alias_screen.dart';
import 'screens/avatar_screen.dart';
import 'screens/create_room_screen.dart';
import 'screens/customize_avatar_screen.dart';
import 'screens/day_clue_screen.dart';
import 'screens/game_over_screen.dart';
import 'screens/game_rooms_screen.dart';
import 'screens/home_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/night_action_screen.dart';
import 'screens/role_screen.dart';
import 'screens/round_result_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/vote_screen.dart';

// Import all services
import 'services/app_localizations.dart';
import 'services/character_service.dart';
import 'services/language_service.dart';
import 'services/navigation_service.dart';
import 'services/theme_service.dart';
import 'services/user_service.dart';

import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const TodosMientenApp());
}

class TodosMientenApp extends StatelessWidget {
  const TodosMientenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => CharacterService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => UserService()),
      ],
      child: Consumer2<LanguageService, ThemeService>(
        builder: (context, languageService, themeService, child) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            locale: languageService.appLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorKey: NavigationService.navigatorKey,
            home: const FirebaseInitializer(), // Set new home
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }
}

// Widget to handle Firebase Initialization robustly
class FirebaseInitializer extends StatefulWidget {
  const FirebaseInitializer({super.key});

  @override
  State<FirebaseInitializer> createState() => _FirebaseInitializerState();
}

class _FirebaseInitializerState extends State<FirebaseInitializer> {
  Future<FirebaseApp>? _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeFirebase();
  }

  // This is the definitive way to initialize Firebase safely.
  Future<FirebaseApp> _initializeFirebase() async {
    if (Firebase.apps.isNotEmpty) {
      return Firebase.app(); // Use existing app
    }
    return Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        // Check for errors
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Error initializing Firebase: ${snapshot.error}", textAlign: TextAlign.center),
            ),
          );
        }

        // Once complete, show your application
        if (snapshot.connectionState == ConnectionState.done) {
          return const HomeScreen();
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}


// Use onGenerateRoute to handle all routes with arguments
Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  Widget page;
  switch (settings.name) {
    case HomeScreen.routeName:
      page = const HomeScreen();
      break;
    case SettingsScreen.routeName:
      page = const SettingsScreen();
      break;
    case LobbyScreen.routeName:
      page = const LobbyScreen();
      break;
    case AliasScreen.routeName:
      page = const AliasScreen();
      break;
    case AvatarScreen.routeName:
      page = const AvatarScreen();
      break;
    case CreateRoomScreen.routeName:
      page = const CreateRoomScreen();
      break;
    case DayClueScreen.routeName:
      page = const DayClueScreen();
      break;
    case GameOverScreen.routeName:
      page = const GameOverScreen();
      break;
    case GameRoomsScreen.routeName:
      page = const GameRoomsScreen();
      break;
    case NightActionScreen.routeName:
      page = const NightActionScreen();
      break;
    case RoleScreen.routeName:
      page = const RoleScreen();
      break;
    case RoundResultScreen.routeName:
      page = const RoundResultScreen();
      break;
    case VoteScreen.routeName:
      page = const VoteScreen();
      break;
    case CustomizeAvatarScreen.routeName:
      final args = settings.arguments as Map<String, dynamic>?;
      page = CustomizeAvatarScreen(
        characterFile: args?['characterFile'] ?? 'robot.glb',
      );
      break;
    default:
      page = const Scaffold(body: Center(child: Text('Page not found')));
      break;
  }
  return MaterialPageRoute(builder: (_) => page, settings: settings);
}
