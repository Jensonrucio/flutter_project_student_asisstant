import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/glass_theme.dart';
import '../../data/ai_quiz_api.dart';
import '../../data/study_notes_extractor.dart';

class QuizChatPage extends StatefulWidget {
  const QuizChatPage({this.accessToken = '', super.key});

  final String accessToken;

  @override
  State<QuizChatPage> createState() => _QuizChatPageState();
}

class _QuizChatPageState extends State<QuizChatPage> {
  static const int _maxNotesLength = 12000;
  static const int _maxFileBytes = 10 * 1024 * 1024;
  static const int _passingScorePercent = 60;
  static const List<int> _questionCountOptions = [5, 10, 15, 20];

  final TextEditingController _notesController = TextEditingController();
  final GlobalKey _firstQuestionKey = GlobalKey();
  final AiQuizApi _aiQuizApi = AiQuizApi();
  final StudyNotesExtractor _notesExtractor = const StudyNotesExtractor();
  bool _isLoadingFile = false;
  bool _isGeneratingQuiz = false;
  String? _selectedFileName;
  int _questionCount = 5;
  List<Map<String, dynamic>> _quizQuestions = [];
  final Map<int, int> _selectedAnswers = {};
  bool _quizSubmitted = false;
  int _score = 0;

  bool get _hasPassed =>
      _quizQuestions.isNotEmpty &&
      _score * 100 >= _quizQuestions.length * _passingScorePercent;

  Future<void> _pickNotes() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'txt', 'docx'],
      );
      if (files.isEmpty || !mounted) return;

      final file = files.single;
      final extension = file.extension?.toLowerCase();
      if (extension == null ||
          !const {'pdf', 'txt', 'docx'}.contains(extension)) {
        _showMessage('Choose a PDF, TXT, or DOCX notes file.');
        return;
      }
      final fileSize = await file.length();
      if (fileSize == null) {
        _showMessage('Could not determine the file size. Please try again.');
        return;
      }
      if (fileSize > _maxFileBytes) {
        _showMessage('The notes file must be smaller than 10 MB.');
        return;
      }

      setState(() => _isLoadingFile = true);
      final Uint8List bytes = await file.readAsBytes();
      final notes = await _notesExtractor.extract(
        bytes: bytes,
        extension: extension,
      );
      if (notes.trim().isEmpty) {
        throw const FormatException(
          'No readable text was found. For PDFs, use a text-based document.',
        );
      }
      if (notes.length > _maxNotesLength) {
        throw const FormatException(
          'These notes are too long. Shorten them to 12,000 characters or less.',
        );
      }
      if (!mounted) return;
      setState(() {
        _notesController.text = notes;
        _selectedFileName = file.name;
        _quizQuestions = [];
        _selectedAnswers.clear();
        _quizSubmitted = false;
        _score = 0;
      });
    } on FormatException catch (error) {
      if (mounted) _showMessage(error.message.toString());
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Could not read that notes file. Check that it is not damaged.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingFile = false);
    }
  }

  Future<void> _generateQuiz() async {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) {
      _showMessage('Upload a notes file or paste your notes first.');
      return;
    }
    if (notes.length > _maxNotesLength) {
      _showMessage('Shorten your notes to 12,000 characters or less.');
      return;
    }
    if (widget.accessToken.isEmpty) {
      _showMessage('Sign in to generate a Study Buddy quiz.');
      return;
    }

    setState(() {
      _isGeneratingQuiz = true;
      _quizQuestions = [];
      _selectedAnswers.clear();
      _quizSubmitted = false;
      _score = 0;
    });

    try {
      final questions = await _aiQuizApi.generateQuiz(
        notes: notes,
        accessToken: widget.accessToken,
        questionCount: _questionCount,
      );
      if (!mounted) return;
      setState(() {
        _quizQuestions = questions;
        _isGeneratingQuiz = false;
      });
    } on AiQuizApiException catch (error) {
      if (!mounted) return;
      setState(() => _isGeneratingQuiz = false);
      _showMessage(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isGeneratingQuiz = false);
      _showMessage('Quiz generation failed. Please try again.');
    }
  }

  Future<void> _submitQuiz() async {
    if (_selectedAnswers.length != _quizQuestions.length) {
      _showMessage(
        'Answer all ${_quizQuestions.length} questions to reveal your score.',
      );
      return;
    }

    var calculatedScore = 0;
    for (var index = 0; index < _quizQuestions.length; index++) {
      if (_selectedAnswers[index] == _quizQuestions[index]['correct_index']) {
        calculatedScore++;
      }
    }

    setState(() {
      _score = calculatedScore;
      _quizSubmitted = true;
    });

    try {
      await http.post(
        Uri.parse(ApiConstants.quizLogEndpoint),
        headers: {
          'Content-Type': 'application/json',
          if (widget.accessToken.isNotEmpty) 'Authorization': '******',
        },
        body: json.encode({
          'topic': 'Study Buddy quiz',
          'score': calculatedScore,
          'total_questions': _quizQuestions.length,
        }),
      );
    } catch (_) {
      // Quiz results stay visible even if history logging is unavailable.
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _completeQuiz() {
    if (!_quizSubmitted || !_hasPassed) return;
    Navigator.of(context).pop();
  }

  void _retryQuiz() {
    if (!_quizSubmitted || _hasPassed) return;
    setState(() {
      _selectedAnswers.clear();
      _quizSubmitted = false;
      _score = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firstQuestionContext = _firstQuestionKey.currentContext;
      if (mounted && firstQuestionContext != null) {
        Scrollable.ensureVisible(
          firstQuestionContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _aiQuizApi.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlassTheme.background(context),
      appBar: AppBar(
        title: const Text('Study Buddy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Learn from your own notes',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload or paste your study notes. Gemini will create a quiz using only that material.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          GlassTheme.glassContainer(
            context: context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: _isLoadingFile || _isGeneratingQuiz
                      ? null
                      : _pickNotes,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _selectedFileName == null
                        ? 'Upload notes (PDF, TXT, DOCX)'
                        : 'Replace uploaded notes',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GlassTheme.cyanAccent,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                if (_selectedFileName != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: GlassTheme.cyanAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedFileName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove uploaded notes',
                        onPressed: _isLoadingFile || _isGeneratingQuiz
                            ? null
                            : () {
                                setState(() {
                                  _selectedFileName = null;
                                  _notesController.clear();
                                  _quizQuestions = [];
                                  _selectedAnswers.clear();
                                  _quizSubmitted = false;
                                  _score = 0;
                                });
                              },
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  minLines: 5,
                  maxLines: 9,
                  maxLength: _maxNotesLength,
                  enabled: !_isLoadingFile && !_isGeneratingQuiz,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Or paste your notes here...',
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Number of questions',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DropdownButton<int>(
                      value: _questionCount,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      underline: Container(
                        height: 1,
                        color: GlassTheme.cyanAccent,
                      ),
                      items: _questionCountOptions
                          .map(
                            (count) => DropdownMenuItem<int>(
                              value: count,
                              child: Text('$count'),
                            ),
                          )
                          .toList(),
                      onChanged: _isLoadingFile || _isGeneratingQuiz
                          ? null
                          : (count) {
                              if (count == null) return;
                              setState(() {
                                _questionCount = count;
                                _quizQuestions = [];
                                _selectedAnswers.clear();
                                _quizSubmitted = false;
                                _score = 0;
                              });
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoadingFile || _isGeneratingQuiz
                        ? null
                        : _generateQuiz,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate quiz from my notes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your notes are sent to Gemini only when you generate a quiz.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoadingFile || _isGeneratingQuiz) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(color: GlassTheme.cyanAccent),
            const SizedBox(height: 8),
            Text(
              _isLoadingFile
                  ? 'Reading your notes...'
                  : 'Building your quiz...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
          if (_quizQuestions.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              _quizSubmitted ? 'Quiz review' : 'Your notes quiz',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(
              _quizQuestions.length,
              (index) => _buildQuestionCard(
                index,
                key: index == 0 ? _firstQuestionKey : null,
              ),
            ),
            if (_quizSubmitted) _buildScoreCard(),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !_quizSubmitted
                    ? _submitQuiz
                    : _hasPassed
                    ? _completeQuiz
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(
                  !_quizSubmitted
                      ? 'Reveal my score'
                      : _hasPassed
                      ? 'Quiz complete'
                      : 'Passing score required',
                ),
              ),
            ),
            if (_quizSubmitted && !_hasPassed) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _retryQuiz,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try quiz again'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int questionIndex, {Key? key}) {
    final question = _quizQuestions[questionIndex];
    final correctIndex = question['correct_index'] as int;
    final selectedIndex = _selectedAnswers[questionIndex];
    final options = question['options'] as List<String>;

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassTheme.glassContainer(
        context: context,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${questionIndex + 1}',
              style: const TextStyle(
                color: GlassTheme.cyanAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              question['question'] as String,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<int>(
              groupValue: selectedIndex,
              onChanged: (value) {
                if (!_quizSubmitted && value != null) {
                  setState(() => _selectedAnswers[questionIndex] = value);
                }
              },
              child: Column(
                children: List.generate(options.length, (optionIndex) {
                  final isCorrect =
                      _quizSubmitted && optionIndex == correctIndex;
                  final isWrongSelection =
                      _quizSubmitted &&
                      optionIndex == selectedIndex &&
                      optionIndex != correctIndex;
                  return RadioListTile<int>(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            options[optionIndex],
                            style: TextStyle(
                              color: isCorrect
                                  ? Colors.lightGreenAccent
                                  : isWrongSelection
                                  ? Colors.redAccent
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isCorrect)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.lightGreenAccent,
                            size: 19,
                          )
                        else if (isWrongSelection)
                          const Icon(
                            Icons.cancel,
                            color: Colors.redAccent,
                            size: 19,
                          ),
                      ],
                    ),
                    value: optionIndex,
                    activeColor: Theme.of(context).colorScheme.primary,
                    selected: selectedIndex == optionIndex,
                    enabled: !_quizSubmitted,
                    contentPadding: EdgeInsets.zero,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard() {
    final percent = (_score * 100 / _quizQuestions.length).round();
    final message = percent == 100
        ? 'Excellent work!'
        : _hasPassed
        ? 'You passed! Complete the quiz to finish.'
        : 'Review your notes and try again. A score of '
              '$_passingScorePercent% is needed to pass.';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassTheme.glassContainer(
        context: context,
        child: Row(
          children: [
            Icon(
              Icons.emoji_events_outlined,
              color: GlassTheme.cyanAccent,
              size: 32,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your score: $_score / ${_quizQuestions.length} ($percent%)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
