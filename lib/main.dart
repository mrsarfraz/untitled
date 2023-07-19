import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CreateQuizScreen(),
    );
  }
}

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  _CreateQuizScreenState createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  late String quizId;
  late String quizPassword;
  late String quizName;
  late int questionCount;
  late int duration;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _createQuiz() async {
    // Generate a unique ID for the quiz
    quizId = _generateQuizId();

    // Create a new quiz document in Firebase Firestore
    final DocumentReference quizRef = _firestore.collection('quizzes').doc(quizId);
    await quizRef.set({
      'password': quizPassword,
      'name': quizName,
      'questionCount': questionCount,
      'duration': duration,
    });

    // Navigate to the next screen to add questions and options
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddQuestionsScreen(quizId: quizId, questionCount: questionCount)),
    );
  }

  String _generateQuizId() {
    // Generate a random 6-character ID
    final Random random = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Quiz'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Quiz Name'),
              onChanged: (value) => quizName = value,
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(labelText: 'Number of Questions'),
              keyboardType: TextInputType.number,
              onChanged: (value) => questionCount = int.parse(value),
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(labelText: 'Duration (in minutes)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => duration = int.parse(value),
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(labelText: 'Quiz Password'),
              onChanged: (value) => quizPassword = value,
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: _createQuiz,
              child: Text('Create Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}

class Quiz {
  final String id;
  final String password;
  final String name;
  final int questionCount;
  final int duration;
  final List<Question> questions;

  Quiz({
    required this.id,
    required this.password,
    required this.name,
    required this.questionCount,
    required this.duration,
    required this.questions,
  });
}

class Question {
  final String question;
  final List<String> options;
  final int correctAnswerIndex;

  Question({required this.question, required this.options, required this.correctAnswerIndex});
}


class AddQuestionsScreen extends StatefulWidget {
  final String quizId;
  final int questionCount;

  AddQuestionsScreen({required this.quizId, required this.questionCount});

  @override
  _AddQuestionsScreenState createState() => _AddQuestionsScreenState();
}

class _AddQuestionsScreenState extends State<AddQuestionsScreen> {
  List<Question> questions = [];
  String currentQuestion = '';
  List<String> currentOptions = List.filled(4, '');
  List<bool> isOptionSelected = List.filled(4, false);
  int? correctAnswerIndex;

  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = List.generate(4, (_) => TextEditingController());

  void _addQuestion() {
    setState(() {
      final question = Question(
        question: currentQuestion,
        options: currentOptions,
        correctAnswerIndex: correctAnswerIndex!,
      );
      questions.add(question);

      // Clear the current question and options
      currentQuestion = '';
      currentOptions = List.filled(4, '');
      optionControllers.forEach((controller) => controller.clear());
      isOptionSelected = List.filled(4, false);
      correctAnswerIndex = null;
    });

    if (questions.length == widget.questionCount) {
      // Enable the "Finish" button when the desired number of questions is reached
      setState(() {
        isFinishEnabled = true;
      });
    }
  }

  bool isFinishEnabled = false;

  void _finishQuiz() {
    // Update the quiz document in Firestore with the list of questions
    final DocumentReference quizRef = FirebaseFirestore.instance.collection('quizzes').doc(widget.quizId);
    quizRef.update({
      'questions': questions.map((question) => {
        'question': question.question,
        'options': question.options,
        'correctAnswerIndex': question.correctAnswerIndex,
      }).toList(),
    });

    // Show the quiz summary screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QuizSummaryScreen(quizId: widget.quizId)),
    );
  }

  @override
  void dispose() {
    questionController.dispose();
    optionControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Questions'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Question'),
              controller: questionController,
              onChanged: (value) => currentQuestion = value,
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Option 1',
                suffixIcon: IconButton(
                  icon: Icon(
                    isOptionSelected[0] ? Icons.check : Icons.circle,
                  ),
                  onPressed: () {
                    setState(() {
                      isOptionSelected = List.filled(4, false);
                      isOptionSelected[0] = true;
                      correctAnswerIndex = 0;
                    });
                  },
                ),
              ),
              controller: optionControllers[0],
              onChanged: (value) => currentOptions[0] = value,
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Option 2',
                suffixIcon: IconButton(
                  icon: Icon(
                    isOptionSelected[1] ? Icons.check : Icons.circle,
                  ),
                  onPressed: () {
                    setState(() {
                      isOptionSelected = List.filled(4, false);
                      isOptionSelected[1] = true;
                      correctAnswerIndex = 1;
                    });
                  },
                ),
              ),
              controller: optionControllers[1],
              onChanged: (value) => currentOptions[1] = value,
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Option 3',
                suffixIcon: IconButton(
                  icon: Icon(
                    isOptionSelected[2] ? Icons.check : Icons.circle,
                  ),
                  onPressed: () {
                    setState(() {
                      isOptionSelected = List.filled(4, false);
                      isOptionSelected[2] = true;
                      correctAnswerIndex = 2;
                    });
                  },
                ),
              ),
              controller: optionControllers[2],
              onChanged: (value) => currentOptions[2] = value,
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Option 4',
                suffixIcon: IconButton(
                  icon: Icon(
                    isOptionSelected[3] ? Icons.check : Icons.circle,
                  ),
                  onPressed: () {
                    setState(() {
                      isOptionSelected = List.filled(4, false);
                      isOptionSelected[3] = true;
                      correctAnswerIndex = 3;
                    });
                  },
                ),
              ),
              controller: optionControllers[3],
              onChanged: (value) => currentOptions[3] = value,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _addQuestion,
              child: Text('Add Question'),
            ),
            SizedBox(height: 32.0),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  return ListTile(
                    title: Text(question.question),
                    subtitle: Text('Options: ${question.options.join(', ')} ${question.correctAnswerIndex}'),
                  );
                },
              ),
            ),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: isFinishEnabled ? _finishQuiz : null,
              child: Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }
}



class QuizSummaryScreen extends StatelessWidget {
  final String quizId;

  QuizSummaryScreen({super.key, required this.quizId});

  @override
  Widget build(BuildContext context) {
    final shareableLink = 'https://example.com/quiz/$quizId';

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz Summary'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quiz ID: $quizId'),
            SizedBox(height: 16.0),
            Text('Shareable Link: $shareableLink'),
            SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () {
                // Reset the app state and navigate back to the create quiz screen
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              child: Text('Create Another Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
