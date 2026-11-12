import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/app_bloc_observer.dart';
import 'core/platform/local_backend.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (!const bool.fromEnvironment('JSM_LOCAL_DESKTOP')) {
      await dotenv.load(fileName: ".env");
    }
  } catch (e) {
    log('Could not load .env file, fallback to defaults/dart-define: $e');
  }

  if (const bool.fromEnvironment('JSM_LOCAL_DESKTOP')) {
    try {
      await startLocalBackend();
    } catch (e, stack) {
      log('Could not start the local JSM service: $e', stackTrace: stack);
    }
  }

  runApp(await builder());
}
