import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:kids_tracing_app/constants/app_constants.dart';

/// Centralized audio playback service for background music and effects.
class AudioService {
  AudioService() : _musicPlayer = AudioPlayer(), _effectPlayer = AudioPlayer();

  final AudioPlayer _musicPlayer;
  final AudioPlayer _effectPlayer;

  StreamSubscription<PlayerState>? _musicStateSubscription;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('AudioService: initializing audio players');
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _musicPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      await _musicPlayer.setVolume(AppConstants.backgroundMusicVolume);

      await _effectPlayer.setReleaseMode(ReleaseMode.stop);
      await _effectPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _effectPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.assistanceSonification,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );

      _musicStateSubscription = _musicPlayer.onPlayerStateChanged.listen((
        state,
      ) {
        debugPrint('AudioService: music state changed -> $state');
      });

      _isInitialized = true;
      debugPrint('AudioService initialized successfully');
    } catch (error, stackTrace) {
      debugPrint('AudioService initialization failed: $error');
      debugPrint(stackTrace.toString());
    }
  }

  /// Play looping background music.
  Future<void> playBackgroundMusic() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      debugPrint('AudioService: starting background music');
      await _musicPlayer.stop();
      await _musicPlayer.play(
        AssetSource(AppConstants.backgroundMusicPath),
        volume: AppConstants.backgroundMusicVolume,
      );

      debugPrint('Background music started and looping');
    } catch (error, stackTrace) {
      debugPrint('Unable to play background music: $error');
      debugPrint(stackTrace.toString());
    }
  }

  /// Stop background music.
  Future<void> stopBackgroundMusic() async {
    try {
      await _musicPlayer.stop();
      debugPrint('Background music stopped');
    } catch (error) {
      debugPrint('Unable to stop background music: $error');
    }
  }

  /// Pause background music.
  Future<void> pauseBackgroundMusic() async {
    try {
      await _musicPlayer.pause();
      debugPrint('Background music paused');
    } catch (error) {
      debugPrint('Unable to pause background music: $error');
    }
  }

  /// Resume paused background music.
  Future<void> resumeBackgroundMusic() async {
    try {
      await _musicPlayer.resume();
      debugPrint('Background music resumed');
    } catch (error) {
      debugPrint('Unable to resume background music: $error');
    }
  }

  /// Play success sound effect.
  Future<void> playSuccessSound() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      await _effectPlayer.stop();
      await _effectPlayer.setSourceAsset(AppConstants.successSoundPath);
      await _effectPlayer.setVolume(AppConstants.successSoundVolume);
      await _effectPlayer.resume();

      debugPrint('Success sound played');
    } catch (error) {
      debugPrint('Unable to play success sound: $error');
    }
  }

  Future<void> dispose() async {
    await _musicStateSubscription?.cancel();
    await _musicPlayer.dispose();
    await _effectPlayer.dispose();
  }
}
