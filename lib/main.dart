import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'firebase_options.dart';

// Screens
import 'screens/alias_screen.dart';
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

// Services
import 'services/app_localizations.dart';
import 'services/character_service.dart';
import 'services/firestore_service.dart';
import 'services/language_service.dart';
import 'services/navigation_service.dart';
import 'services/profanity_filter_service.dart';
import 'services/theme_service.dart';
import 'services/user_service.dart';

import 'constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const TodosMientenApp());
}

class TodosMientenApp extends StatefulWidget {
  const TodosMientenApp({super.key});

  @override
  State<TodosMientenApp> createState() => _TodosMientenAppState();
}

class _TodosMientenAppState extends State<TodosMientenApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinking();
  }

  Future<void> _initDeepLinking() async {
    _appLinks = AppLinks();
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) _handleIncomingLink(initialUri);
    } on PlatformException {
      // Handle exception
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    }, onError: (err) {
      // Handle exception
    });
  }

  void _handleIncomingLink(Uri uri) {
    if (uri.path.startsWith('/join') && uri.queryParameters.containsKey('room')) {
      final roomCode = uri.queryParameters['room'];
      final userService = Provider.of<UserService>(NavigationService.navigatorKey.currentContext!, listen: false);

      if (userService.hasUser) {
        NavigationService.push(LobbyScreen.routeName, arguments: {'roomCode': roomCode});
      } else {
        NavigationService.push(AliasRedirectScreen.routeName, arguments: {'roomCode': roomCode});
      }
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ProfanityFilterService()),
        Provider(create: (_) => FirestoreService()),
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
            home: const FirebaseInitializer(),
            onGenerateRoute: _onGenerateRoute,
          );
        },
      ),
    );
  }
}

class FirebaseInitializer extends StatefulWidget {
  const FirebaseInitializer({super.key});
  @override
  State<FirebaseInitializer> createState() => _FirebaseInitializerState();
}

class _FirebaseInitializerState extends State<FirebaseInitializer> {
  late final Future<FirebaseApp?> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeFirebase();
  }

  Future<FirebaseApp?> _initializeFirebase() async {
    try {
      return await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        return Firebase.app(); // Use existing app
      }
      rethrow; // Rethrow other Firebase errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(body: Center(child: Text("Error: ${snapshot.error}")));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const HomeScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class AliasRedirectScreen extends StatelessWidget {
  static const routeName = '/alias-redirect';
  const AliasRedirectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final roomCode = args?['roomCode'];
    return AliasScreen(roomCodeToJoin: roomCode);
  }
}

Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  Widget page;
  switch (settings.name) {
    case HomeScreen.routeName:
      page = const HomeScreen();
      break;
    case SettingsScreen.routeName:
      page = const SettingsScreen();
      break;
    case GameRoomsScreen.routeName:
      page = const GameRoomsScreen();
      break;
    case CreateRoomScreen.routeName:
      page = const CreateRoomScreen();
      break;
    case LobbyScreen.routeName:
      page = const LobbyScreen();
      break;
    case AliasRedirectScreen.routeName:
      page = const AliasRedirectScreen();
      break;
    case CustomizeAvatarScreen.routeName:
       final args = settings.arguments as Map<String, dynamic>?;
       page = CustomizeAvatarScreen(characterFile: args?['characterFile'] ?? 'robot.glb');
       break;
    case DayClueScreen.routeName:
       page = const DayClueScreen();
       break;
    case GameOverScreen.routeName:
       page = const GameOverScreen();
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
    case AliasScreen.routeName:
       page = const AliasScreen();
       break;
    default:
      page = const Scaffold(body: Center(child: Text('Page not found')));
  }
  return MaterialPageRoute(builder: (_) => page, settings: settings);
}
