import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../core/theme/glass_theme.dart';

class PomodoroTimerController extends ChangeNotifier {
  static const int _minDurationMinutes = 1;
  static const int _maxDurationMinutes = 180;
  final AudioPlayer _completionPlayer = AudioPlayer();
  int _durationMinutes = 15;
  int _secondsRemaining = 15 * 60;
  Timer? _timer;
  bool _disposed = false;
  bool _isRunning = false;
  bool _isAlarmPlaying = false;
  bool _soundEnabled = true;
  bool _isMinimized = false;
  bool _hasSession = false;

  int get _durationSeconds => _durationMinutes * 60;
  int get durationMinutes => _durationMinutes;
  int get secondsRemaining => _secondsRemaining;
  bool get isRunning => _isRunning;
  bool get isAlarmPlaying => _isAlarmPlaying;
  bool get soundEnabled => _soundEnabled;
  bool get isMinimized => _isMinimized;
  bool get hasSession => _hasSession;
  bool get canDecreaseDuration =>
      !_isRunning && _durationMinutes > _minDurationMinutes;
  bool get canIncreaseDuration =>
      !_isRunning && _durationMinutes < _maxDurationMinutes;
  double get progress => _secondsRemaining / _durationSeconds;

  String get timeString {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_completionPlayer.dispose());
    super.dispose();
  }

  void start() {
    if (_secondsRemaining == 0) return;
    _timer?.cancel();
    _isRunning = true;
    _hasSession = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _secondsRemaining = 0;
        _isRunning = false;
        notifyListeners();
        if (_soundEnabled) {
          unawaited(_playCompletionSound());
        }
        return;
      }

      _secondsRemaining--;
      notifyListeners();
    });
  }

  Future<void> _playCompletionSound() async {
    if (_disposed || !_soundEnabled) return;

    _isAlarmPlaying = true;
    notifyListeners();
    try {
      await _completionPlayer.setReleaseMode(ReleaseMode.loop);
      if (_disposed || !_isAlarmPlaying) return;
      await _completionPlayer.play(AssetSource('audio/pomodoro_complete.wav'));
    } on Object catch (error) {
      debugPrint('Unable to play Pomodoro completion sound: $error');
      if (!_disposed) {
        _isAlarmPlaying = false;
        notifyListeners();
      }
    }
  }

  Future<void> stopAlarm() async {
    _isAlarmPlaying = false;
    notifyListeners();
    try {
      await _completionPlayer.stop();
    } on Object catch (error) {
      debugPrint('Unable to stop Pomodoro completion sound: $error');
      if (!_disposed) {
        _isAlarmPlaying = true;
        notifyListeners();
      }
    }
  }

  void pause() {
    _timer?.cancel();
    _isRunning = false;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _isRunning = false;
    _secondsRemaining = _durationSeconds;
    _hasSession = false;
    _isMinimized = false;
    notifyListeners();
    unawaited(stopAlarm());
  }

  void changeDuration(int minutes) {
    final updatedDuration = _durationMinutes + minutes;
    if (_isRunning ||
        updatedDuration < _minDurationMinutes ||
        updatedDuration > _maxDurationMinutes) {
      return;
    }

    _durationMinutes = updatedDuration;
    _secondsRemaining = _durationSeconds;
    _hasSession = true;
    notifyListeners();
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    notifyListeners();
    if (!_soundEnabled && _isAlarmPlaying) {
      unawaited(stopAlarm());
    }
  }

  void minimize() {
    _isMinimized = true;
    notifyListeners();
  }

  void restore() {
    _isMinimized = false;
    notifyListeners();
  }

  void closeSession() {
    reset();
  }
}

class PomodoroPage extends StatelessWidget {
  const PomodoroPage({
    required this.controller,
    required this.onMinimize,
    super.key,
  });

  final PomodoroTimerController controller;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return _buildPage(context);
      },
    );
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.background(context),
      appBar: AppBar(
        title: const Text('Streak Buddy'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Minimize timer to dashboard',
            onPressed: () {
              controller.minimize();
              onMinimize();
            },
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          IconButton(
            tooltip: controller.soundEnabled
                ? 'Mute completion sound'
                : 'Enable completion sound',
            onPressed: controller.toggleSound,
            icon: Icon(
              controller.soundEnabled
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Focus duration',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Decrease duration by one minute',
                    onPressed: controller.canDecreaseDuration
                        ? () => controller.changeDuration(-1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 112,
                    child: Text(
                      '${controller.durationMinutes} min',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Increase duration by one minute',
                    onPressed: controller.canIncreaseDuration
                        ? () => controller.changeDuration(1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 12.0,
                percent: controller.progress,
                center: Text(
                  controller.timeString,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                progressColor: GlassTheme.cyanAccent,
                backgroundColor: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: 0.1),
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: controller.isRunning ? 'Pause timer' : 'Start timer',
                    iconSize: 48,
                    icon: Icon(
                      controller.isRunning
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: GlassTheme.accentNeon,
                    ),
                    onPressed: controller.isRunning
                        ? controller.pause
                        : controller.start,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    iconSize: 36,
                    icon: Icon(
                      Icons.replay,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: controller.reset,
                  ),
                ],
              ),
              if (controller.isAlarmPlaying) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: controller.stopAlarm,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop alarm'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
