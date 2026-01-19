import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photocafe_windows/core/colors/app_theme.dart';
import 'package:photocafe_windows/core/router/router.dart';
import 'package:photocafe_windows/features/photos/domain/data/providers/photo_notifier.dart';
import 'package:photocafe_windows/features/print/domain/data/providers/printer_notifier.dart';
import 'package:photocafe_windows/features/videos/domain/data/providers/video_notifier.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:window_manager/window_manager.dart';

// 16:9 aspect ratio constant
const double kAspectRatio = 16 / 9;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager
  await windowManager.ensureInitialized();

  // Configure window options with 16:9 aspect ratio (1280x720 is a common 16:9 resolution)
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.black,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Set aspect ratio to maintain 16:9
    await windowManager.setAspectRatio(kAspectRatio);
    await windowManager.show();
    await windowManager.focus();
  });

  // Initialize SoLoud
  await SoLoud.instance.init();

  await dotenv.load(fileName: ".env");
  runApp(ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize providers on app startup
    return FutureBuilder(
      future: _initializeProviders(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: kAspectRatio,
                    child: Material(
                      type: MaterialType.transparency,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            home: Scaffold(
              body: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.lightTheme.colorScheme.primary,
                      AppTheme.lightTheme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Photo Cafe',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Initializing...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          print('Provider initialization error: ${snapshot.error}');
          return MaterialApp(
            theme: AppTheme.lightTheme,
            builder: (context, child) {
              return Container(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: kAspectRatio,
                    child: Material(
                      type: MaterialType.transparency,
                      child: child,
                    ),
                  ),
                ),
              );
            },
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text('Initialization failed'),
                    SizedBox(height: 8),
                    Text('${snapshot.error}'),
                  ],
                ),
              ),
            ),
          );
        }

        return MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
          builder: (context, child) {
            // Wrap the entire app in a 16:9 aspect ratio container with black bars
            // Material widget prevents yellow underlines on Text widgets
            return Container(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: kAspectRatio,
                  child: Material(
                    type: MaterialType.transparency,
                    child: child,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _initializeProviders(WidgetRef ref) async {
    print('Initializing providers...');

    try {
      // Initialize photo provider first
      final photoState = await ref.read(photoProvider.future);
      print(
        'Photo provider initialized with capture count: ${photoState.captureCount}',
      );

      // Initialize printer provider
      final printerState = await ref.read(printerProvider.future);
      print('Printer provider initialized');

      // Apply saved fullscreen setting
      if (printerState.isFullscreen) {
        await windowManager.setFullScreen(true);
      }

      // Initialize video provider
      final videoState = await ref.read(videoProvider.future);
      print('Video provider initialized');

      print('All providers initialized successfully');
    } catch (e) {
      print('Provider initialization error: $e');
      throw e;
    }
  }
}
