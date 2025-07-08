import 'package:go_router/go_router.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_capture_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_filter_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_organize_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_print_screen.dart';
import 'package:photocafe_windows/features/classic/presentation/screens/classic_start_screen.dart';
import 'package:photocafe_windows/features/flipbook/presentation/screens/flipbook_capture_screen.dart';
import 'package:photocafe_windows/features/flipbook/presentation/screens/flipbook_frame_screen.dart';
import 'package:photocafe_windows/features/flipbook/presentation/screens/flipbook_print_screen.dart';
import 'package:photocafe_windows/features/flipbook/presentation/screens/flipbook_start_screen.dart';
import 'package:photocafe_windows/features/start/presentation/screens/start_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AppStartScreen()),
    GoRoute(
      path: '/classic/start',
      builder: (context, state) => const ClassicStartScreen(),
    ),
    GoRoute(
      path: '/classic/capture',
      builder: (context, state) => const ClassicCaptureScreen(),
    ),
    GoRoute(
      path: '/classic/organize',
      builder: (context, state) => const ClassicOrganizeScreen(),
    ),
    GoRoute(
      path: '/classic/filter',
      builder: (context, state) => const ClassicFilterScreen(),
    ),
    GoRoute(
      path: '/classic/print',
      builder: (context, state) => const ClassicPrintScreen(),
    ),
    GoRoute(
      path: '/flipbook/start',
      builder: (context, state) => const FlipbookStartScreen(),
    ),
    GoRoute(
      path: '/flipbook/capture',
      builder: (context, state) => const FlipbookCaptureScreen(),
    ),
    GoRoute(
      path: '/flipbook/frame',
      builder: (context, state) => const FlipbookFrameScreen(),
    ),
    GoRoute(
      path: '/flipbook/print',
      builder: (context, state) => const FlipbookPrintScreen(),
    ),
  ],
);
