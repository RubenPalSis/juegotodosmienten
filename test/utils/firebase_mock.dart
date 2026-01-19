import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';

// Este mock simula la inicialización nativa de Firebase para que los tests puedan correr.
typedef Callback = void Function(MethodCall call);

void setupFirebaseCoreMocks({Callback? customHandlers}) {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Intercepta las llamadas al canal de Firebase Core
  MethodChannelFirebase.channel.setMockMethodCallHandler((call) async {
    if (call.method == 'Firebase#initialize') {
      return [
        {
          'name': defaultFirebaseAppName,
          'options': {
            'apiKey': 'mock_api_key',
            'appId': 'mock_app_id',
            'messagingSenderId': 'mock_sender_id',
            'projectId': 'mock_project_id',
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
