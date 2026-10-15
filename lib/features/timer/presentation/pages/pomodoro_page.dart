import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../core/theme/glass_theme.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  static const int _minDurationMinutes = 1;
  static const int _maxDurationMinutes = 180;
  final AudioPlayer _completionPlayer = AudioPlayer();
  int _durationMinutes = 15;
  int _secondsRemaining = 15 * 60;
  Timer? _timer;
  bool _isRunning = false;
  bool _isAlarmPlaying = false;
  bool _soundEnabled = true;

  int get _durationSeconds => _durationMinutes * 60;

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_completionPlayer.dispose());
    super.dispose();
  }

  void _startTimer() {
    if (_secondsRemaining == 0) return;
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _isRunning = false;
        });
        if (_soundEnabled) {
          unawaited(_playCompletionSound());
        }
        return;
      }

      setState(() => _secondsRemaining--);
    });
  }

  Future<void> _playCompletionSound() async {
    if (!mounted || !_soundEnabled) return;

    setState(() => _isAlarmPlaying = true);
    try {
      await _completionPlayer.setReleaseMode(ReleaseMode.loop);
      if (!mounted || !_isAlarmPlaying) return;
      await _completionPlayer.play(AssetSource('audio/pomodoro_complete.wav'));
    } on Object catch (error) {
      debugPrint('Unable to play Pomodoro completion sound: $error');
      if (mounted) {
        setState(() => _isAlarmPlaying = false);
      }
    }
  }

  Future<void> _stopAlarm() async {
    if (mounted) {
      setState(() => _isAlarmPlaying = false);
    }
    try {
      await _completionPlayer.stop();
    } on Object catch (error) {
      debugPrint('Unable to stop Pomodoro completion sound: $error');
      if (mounted) {
        setState(() => _isAlarmPlaying = true);
      }
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _pauseTimer();
    unawaited(_stopAlarm());
    setState(() => _secondsRemaining = _durationSeconds);
  }

  void _changeDuration(int minutes) {
    final updatedDuration = _durationMinutes + minutes;
    if (_isRunning ||
        updatedDuration < _minDurationMinutes ||
        updatedDuration > _maxDurationMinutes) {
      return;
    }

    setState(() {
      _durationMinutes = updatedDuration;
      _secondsRemaining = _durationSeconds;
    });
  }

  String get _timeString {
    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.background(context),
      appBar: AppBar(
        title: const Text('Focus Buddy Timer'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: _soundEnabled
                ? 'Mute completion sound'
                : 'Enable completion sound',
            onPressed: () {
              final soundEnabled = !_soundEnabled;
              setState(() => _soundEnabled = soundEnabled);
              if (!soundEnabled && _isAlarmPlaying) {
                unawaited(_stopAlarm());
              }
            },
            icon: Icon(
              _soundEnabled
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
                    onPressed:
                        !_isRunning && _durationMinutes > _minDurationMinutes
                        ? () => _changeDuration(-1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(
                    width: 112,
                    child: Text(
                      '$_durationMinutes min',
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
                    onPressed:
                        !_isRunning && _durationMinutes < _maxDurationMinutes
                        ? () => _changeDuration(1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 12.0,
                percent: _secondsRemaining / _durationSeconds,
                center: Text(
                  _timeString,
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
                    iconSize: 48,
                    icon: Icon(
                      _isRunning
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                      color: GlassTheme.accentNeon,
                    ),
                    onPressed: _isRunning ? _pauseTimer : _startTimer,
                  ),
                  const SizedBox(width: 20),
                  IconButton(
                    iconSize: 36,
                    icon: Icon(
                      Icons.replay,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: _resetTimer,
                  ),
                ],
              ),
              if (_isAlarmPlaying) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _stopAlarm,
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
