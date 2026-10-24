import 'package:flutter_test/flutter_test.dart';
import 'package:workout_ai/main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });
  testWidgets('Liftly app launches without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(const WorkoutAIApp());
    expect(find.byType(WorkoutAIApp), findsOneWidget);
    expect(find.text('Liftly'), findsOneWidget);
  });
}
