import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:kids_tracing_app/constants/app_constants.dart';

/// Plays short offline sound effects for positive feedback.
class AudioService {
  AudioService() : _player = AudioPlayer();

  final AudioPlayer _player;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _player.setReleaseMode(ReleaseMode.stop);
    _isInitialized = true;
  }

  Future<void> playSuccessSound() async {
    try {
      await _player.stop();
      await _player.play(AssetSource(AppConstants.successSoundPath));
    } catch (error) {
      debugPrint('Unable to play success sound: $error');
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
