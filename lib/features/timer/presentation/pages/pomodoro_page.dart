import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../core/theme/glass_theme.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  static const int _maxSeconds = 15 * 60;
  int _secondsRemaining = _maxSeconds;
  Timer? _timer;
  bool _isRunning = false;
  bool _soundEnabled = true;

  @override
  void dispose() {
    _timer?.cancel();
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
          unawaited(
            SystemSound.play(SystemSoundType.alert).catchError((Object error) {
              debugPrint('Unable to play Pomodoro completion sound: $error');
            }),
          );
        }
        return;
      }

      setState(() => _secondsRemaining--);
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    _pauseTimer();
    setState(() => _secondsRemaining = _maxSeconds);
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
        title: const Text('Focus Pomodoro Timer'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: _soundEnabled
                ? 'Mute completion sound'
                : 'Enable completion sound',
            onPressed: () => setState(() => _soundEnabled = !_soundEnabled),
            icon: Icon(
              _soundEnabled
                  ? Icons.volume_up_outlined
                  : Icons.volume_off_outlined,
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularPercentIndicator(
              radius: 120.0,
              lineWidth: 12.0,
              percent: _secondsRemaining / _maxSeconds,
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
          ],
        ),
      ),
    );
  }
}
