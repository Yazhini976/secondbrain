import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/features/financial_goals/ai_financial_chat_screen.dart';

void main() {
  testWidgets('AIFinancialChatScreen renders header and initial greeting', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AIFinancialChatScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Financial Intelligence AI'), findsOneWidget);
    expect(find.textContaining('Second Brain Financial Intelligence Assistant'), findsOneWidget);
    expect(find.text('Why are my goals conflicting?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
