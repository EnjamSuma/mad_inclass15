
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const ScienceSignalApp());
}

class ScienceQuestion {
  final String text;
  final String correctAnswer;

  ScienceQuestion({
    required this.text,
    required this.correctAnswer,
  });

  factory ScienceQuestion.fromJson(Map<String, dynamic> json) {
    final question = json['question'];
    final correct = json['correct_answer'];
    final incorrect = json['incorrect_answers'];

    if (question is! String ||
        correct is! String ||
        incorrect is! List ||
        incorrect.length != 1 ||
        incorrect.first is! String) {
      throw const FormatException('Invalid question data');
    }

    final decodedQuestion = Uri.decodeComponent(question);
    final decodedCorrect = Uri.decodeComponent(correct);
    final decodedIncorrect =
        Uri.decodeComponent(incorrect.first as String);

    if (decodedQuestion.trim().isEmpty ||
        !['True', 'False'].contains(decodedCorrect) ||
        !['True', 'False'].contains(decodedIncorrect) ||
        decodedCorrect == decodedIncorrect) {
      throw const FormatException('Invalid True/False question');
    }

    return ScienceQuestion(
      text: decodedQuestion,
      correctAnswer: decodedCorrect,
    );
  }
}

class ScienceSignalApp extends StatelessWidget {
  const ScienceSignalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Science Signal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const QuizScreen(),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<ScienceQuestion> questions = [];
  List<String?> selectedAnswers = [];

  int currentIndex = 0;
  int score = 0;

  bool loading = true;
  bool finished = false;
  bool submitting = false;
  bool submitted = false;

  String? error;
  int requestId = 0;

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    final id = ++requestId;

    setState(() {
      loading = true;
      error = null;
      finished = false;
      submitting = false;
      submitted = false;
      questions = [];
      selectedAnswers = [];
      currentIndex = 0;
      score = 0;
    });

    try {
      final uri = Uri.https(
        'opentdb.com',
        '/api.php',
        {
          'amount': '5',
          'category': '17',
          'difficulty': 'medium',
          'type': 'boolean',
          'encode': 'url3986',
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'HTTP request failed: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic> ||
          data['response_code'] != 0 ||
          data['results'] is! List) {
        throw Exception('Trivia API returned an error');
      }

      final results = data['results'] as List;

      if (results.length != 5) {
        throw Exception('Expected exactly five questions');
      }

      final loaded = results.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid result');
        }
        return ScienceQuestion.fromJson(item);
      }).toList();

      if (!mounted || id != requestId) return;

      setState(() {
        questions = loaded;
        selectedAnswers = List<String?>.filled(5, null);
        loading = false;
      });
    } catch (e) {
      if (!mounted || id != requestId) return;

      setState(() {
        loading = false;
        error = 'Could not load questions. $e';
      });
    }
  }

  void selectAnswer(String answer) {
    if (loading ||
        finished ||
        questions.isEmpty ||
        selectedAnswers[currentIndex] != null) {
      return;
    }

    setState(() {
      selectedAnswers[currentIndex] = answer;

      if (answer == questions[currentIndex].correctAnswer) {
        score++;
      }
    });
  }

  void continueQuiz() {
    if (selectedAnswers[currentIndex] == null) return;

    setState(() {
      if (currentIndex < questions.length - 1) {
        currentIndex++;
      } else {
        finished = true;
      }
    });
  }

  Future<void> simulateSubmission() async {
    if (submitting || submitted) return;

    setState(() {
      submitting = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      submitting = false;
      submitted = true;
    });
  }

  Widget buildQuestion() {
    final question = questions[currentIndex];
    final selected = selectedAnswers[currentIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Question ${currentIndex + 1} of 5',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (currentIndex + 1) / 5,
          ),
          const SizedBox(height: 16),
          Text(
            'Score: $score',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 30),
          Text(
            question.text,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 30),
          for (final answer in ['True', 'False'])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: selected == null
                    ? () => selectAnswer(answer)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected == null
                      ? null
                      : answer == question.correctAnswer
                          ? Colors.green.shade100
                          : answer == selected
                              ? Colors.red.shade100
                              : null,
                  disabledBackgroundColor: selected == null
                      ? null
                      : answer == question.correctAnswer
                          ? Colors.green.shade100
                          : answer == selected
                              ? Colors.red.shade100
                              : null,
                  disabledForegroundColor: Colors.black87,
                  padding: const EdgeInsets.all(16),
                ),
                child: Text(answer),
              ),
            ),
          if (selected != null) ...[
            const SizedBox(height: 16),
            Text(
              selected == question.correctAnswer
                  ? 'Correct! Great job.'
                  : 'Incorrect. Correct answer: '
                      '${question.correctAnswer}',
              style: TextStyle(
                fontSize: 18,
                color: selected == question.correctAnswer
                    ? Colors.green.shade800
                    : Colors.red.shade800,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: continueQuiz,
              child: Text(
                currentIndex == 4
                    ? 'View Results'
                    : 'Continue',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildResults() {
    final payload = {
      'score': score,
      'total': 5,
      'category': 'Science & Nature',
    };

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Quiz Completed!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Final Score: $score / 5',
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 24),
        const Text(
          'Answer Review',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        for (int i = 0; i < questions.length; i++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${i + 1}. ${questions[i].text}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your answer: ${selectedAnswers[i]}',
                  ),
                  Text(
                    'Correct answer: '
                    '${questions[i].correctAnswer}',
                  ),
                  Text(
                    selectedAnswers[i] ==
                            questions[i].correctAnswer
                        ? 'Correct'
                        : 'Incorrect',
                    style: TextStyle(
                      color: selectedAnswers[i] ==
                              questions[i].correctAnswer
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Text(
          'Simulated Score Submission',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(
          const JsonEncoder.withIndent('  ').convert(payload),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: submitting || submitted
              ? null
              : simulateSubmission,
          child: Text(
            submitting
                ? 'Simulating submission...'
                : submitted
                    ? 'Simulation Complete'
                    : 'Simulate Score Submission',
          ),
        ),
        if (submitting)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        if (submitted)
          const Text(
            'Simulation complete. No backend request '
            'was sent and no score was saved remotely.',
          ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: submitting ? null : fetchQuestions,
          child: const Text('Play Again'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (loading) {
      content = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading science questions...'),
          ],
        ),
      );
    } else if (error != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchQuestions,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    } else if (finished) {
      content = buildResults();
    } else {
      content = SingleChildScrollView(
        child: buildQuestion(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Science Signal'),
        backgroundColor: Theme.of(context)
            .colorScheme
            .primaryContainer,
      ),
      body: SafeArea(child: content),
    );
  }
}
