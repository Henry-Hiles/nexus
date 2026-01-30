import "dart:developer";
import "dart:io";
import "package:fast_immutable_collections/fast_immutable_collections.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nexus/controllers/client_controller.dart";
import "package:nexus/controllers/client_state_controller.dart";
import "package:nexus/controllers/header_controller.dart";
import "package:nexus/controllers/multi_provider_controller.dart";
import "package:nexus/controllers/shared_prefs_controller.dart";
import "package:nexus/helpers/extensions/better_when.dart";
import "package:nexus/helpers/extensions/scheme_to_theme.dart";
import "package:nexus/pages/chat_page.dart";
import "package:nexus/pages/login_page.dart";
import "package:nexus/pages/verify_page.dart";
import "package:nexus/widgets/error_dialog.dart";
import "package:nexus/widgets/loading.dart";
import "package:window_manager/window_manager.dart";
import "package:flutter/material.dart";
import "package:dynamic_system_colors/dynamic_system_colors.dart";
import "package:window_size/window_size.dart";

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final class Logger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) => debugPrint("""
Time: ${DateTime.now().toIso8601String()}
Provider: ${context.provider}
Previous Value: ${previousValue is AsyncData ? previousValue.value : previousValue}
New Value: ${newValue is AsyncData ? newValue.value : newValue}
}""");
}

void showError(Object error, [StackTrace? stackTrace]) {
  if (error.toString().contains("DioException")) return;
  if (error.toString().contains("Invalid source")) return;
  if (error.toString().contains("UTF-16")) return;
  if (error.toString().contains("HTTP request failed")) return;
  if (error.toString().contains("Invalid image data")) return;

  debugPrintStack(stackTrace: stackTrace, label: error.toString());
  debugger();
  if (navigatorKey.currentContext != null) {
    Future.delayed(
      Duration.zero,
      () => showDialog(
        context: navigatorKey.currentContext!,
        builder: (_) => ErrorDialog(error, stackTrace),
        barrierDismissible: false,
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    WindowOptions(titleBarStyle: TitleBarStyle.hidden),
  );

  if (Platform.isLinux) {
    setWindowMinSize(const Size.square(500));
  } else {
    await windowManager.setMinimumSize(Size.square(500));
  }

  FlutterError.onError = (FlutterErrorDetails details) =>
      showError(details.exception.toString(), details.stack);

  runApp(
    ProviderScope(
      observers: [
        // Change false to true if you want debug information on provider reloads
        // ignore: dead_code
        if (false && kDebugMode) Logger(),
      ],
      child: const App(),
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => DynamicColorBuilder(
    builder: (lightDynamic, darkDynamic) => MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      // Use indigo to work around bugs in theme generation
      theme: (lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.indigo))
          .theme,
      darkTheme:
          (darkDynamic ??
                  ColorScheme.fromSeed(
                    seedColor: Colors.indigo,
                    brightness: Brightness.dark,
                  ))
              .theme,
      home: Scaffold(
        body: Consumer(
          builder: (_, ref, _) => ref
              .watch(
                MultiProviderController.provider(
                  IListConst([
                    SharedPrefsController.provider,
                    ClientController.provider,
                    HeaderController.provider,
                  ]),
                ),
              )
              .betterWhen(
                data: (_) => Consumer(
                  builder: (_, ref, _) {
                    final clientState = ref.watch(
                      ClientStateController.provider,
                    );
                    if (clientState == null || !clientState.isInitialized) {
                      return Loading();
                    }

                    if (!clientState.isLoggedIn) {
                      return LoginPage();
                    } else if (!clientState.isVerified) {
                      return VerifyPage();
                    } else {
                      return ChatPage();
                    }
                  },
                ),
              ),
        ),
      ),
    ),
  );
}
