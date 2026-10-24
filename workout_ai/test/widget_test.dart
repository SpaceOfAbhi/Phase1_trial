import 'package:flutter_test/flutter_test.dart';
import 'package:workout_ai/main.dart';

void main() {
  testWidgets('WorkoutAI app launches without error', (WidgetTester tester) async {
    await tester.pumpWidget(const WorkoutAIApp());
    expect(find.byType(WorkoutAIApp), findsOneWidget);
  });
}
