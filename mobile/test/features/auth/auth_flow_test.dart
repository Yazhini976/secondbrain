import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/app.dart';
import 'package:second_brain/core/auth/auth_service.dart';
import 'package:second_brain/features/auth/login_screen.dart';
import 'package:second_brain/features/auth/signup_screen.dart';

void main() {
  setUp(() {
    AuthService.instance.logout();
  });

  testWidgets('AuthGate shows LoginScreen initially when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SecondBrainApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome to Second Brain'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('Switching between LoginScreen and SignUpScreen works seamlessly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SecondBrainApp());
    await tester.pumpAndSettle();

    // Initially LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SignUpScreen), findsNothing);

    // Tap Sign Up
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Now SignUpScreen is displayed
    expect(find.byType(SignUpScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
    expect(find.text('Create Your Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Monthly Income (₹)'), findsOneWidget);

    // Tap Sign In to go back
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Back to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(SignUpScreen), findsNothing);
  });

  testWidgets('SignUpScreen validates required fields on submit',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignUpScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Create Account with empty fields
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your phone number'), findsOneWidget);
  });
}
