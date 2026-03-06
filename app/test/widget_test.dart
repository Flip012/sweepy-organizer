import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sweepy_organizer/app.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SweepyApp()),
    );
    // App should render without errors
    expect(find.text('Sweepy'), findsAny);
  });
}
