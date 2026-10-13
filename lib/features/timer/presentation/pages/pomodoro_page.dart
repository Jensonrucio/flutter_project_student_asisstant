import 'dart:async';

import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../../../core/theme/glass_theme.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  static const int _maxSeconds = 25 * 60;
  int _secondsRemaining = _maxSeconds;
  Timer? _timer;
  bool _isRunning = false;

  void _startTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _isRunning = false;
        }
      });
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
      backgroundColor: GlassTheme.primaryDark,
      appBar: AppBar(
        title: const Text('Focus Pomodoro Timer', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              progressColor: GlassTheme.cyanAccent,
              backgroundColor: Colors.white10,
              circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 48,
                  icon: Icon(
                    _isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: GlassTheme.accentNeon,
                  ),
                  onPressed: _isRunning ? _pauseTimer : _startTimer,
                ),
                const SizedBox(width: 20),
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.replay, color: Colors.white54),
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
