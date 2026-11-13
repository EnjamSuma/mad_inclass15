# Science Signal — In-Class Activity 15 (C2)

**Name:** Suma Enjam  
**Course:** Mobile App Development  
**Activity:** REST API Integration in Flutter

## Project Overview

For this activity, I built a Flutter True/False quiz using the Open Trivia Database REST API. The app fetches five medium-difficulty Science & Nature questions and displays them one at a time.

## Features

- Fetches live questions using an HTTP GET request.
- Validates API responses and decodes JSON data.
- Displays loading indicators and handles network errors with a retry option.
- Provides True/False answers with green and red feedback.
- Prevents users from answering the same question multiple times.
- Tracks the score and displays all five answers at the end.
- Allows users to replay the quiz with new questions.
- Simulates score submission without sending data to a backend.

## Testing

I tested the app on Android and verified question loading, correct and incorrect answers, score calculation, results review, replay, and error handling. All the tested features worked as expected.

I also ran `flutter analyze` and `flutter test`, and both completed without errors.

## GET vs. POST

The app uses a GET request to retrieve questions from the API. A real score submission would typically use POST to send results to a backend.

Since no submission endpoint was provided, I simulated the submission and displayed the score payload. No data was saved remotely.

## Technologies Used

- Flutter and Dart
- HTTP package
- Open Trivia Database REST API
- JSON parsing

## Screenshots

Screenshots of the quiz, answer feedback, results review, and simulated score submission are available in the `screenshots` folder.