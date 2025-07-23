import 'package:flutter_soloud/flutter_soloud.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioSource? _countdownTickSource;
  AudioSource? _shutterSoundSource;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize SoLoud if not already initialized
      if (!SoLoud.instance.isInitialized) {
        await SoLoud.instance.init();
      }

      // Preload sound effects
      _countdownTickSource = await SoLoud.instance.loadAsset(
        'assets/audio/countdown-tick.mp3',
      );
      _shutterSoundSource = await SoLoud.instance.loadAsset(
        'assets/audio/shutter-sound.mp3',
      );

      _isInitialized = true;
      print('SoundService initialized successfully');
    } catch (e) {
      print('Error initializing SoundService: $e');
    }
  }

  Future<void> playCountdownTick() async {
    if (!_isInitialized || _countdownTickSource == null) {
      await initialize();
      if (!_isInitialized || _countdownTickSource == null) return;
    }

    try {
      await SoLoud.instance.play(_countdownTickSource!);
    } catch (e) {
      print('Error playing countdown tick: $e');
    }
  }

  Future<void> playShutterSound() async {
    if (!_isInitialized || _shutterSoundSource == null) {
      await initialize();
      if (!_isInitialized || _shutterSoundSource == null) return;
    }

    try {
      await SoLoud.instance.play(_shutterSoundSource!);
    } catch (e) {
      print('Error playing shutter sound: $e');
    }
  }

  Future<void> dispose() async {
    try {
      _countdownTickSource = null;
      _shutterSoundSource = null;
      _isInitialized = false;
      // Note: Don't deinit SoLoud.instance here as it's a singleton
      // and might be used elsewhere in the app
    } catch (e) {
      print('Error disposing SoundService: $e');
    }
  }
}
