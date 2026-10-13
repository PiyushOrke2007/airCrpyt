import 'package:flutter_test/flutter_test.dart';
import 'package:aircrypt/main.dart';

void main() {
  testWidgets('Aircrypt application starts', (WidgetTester tester) async {
    await tester.pumpWidget(const AircryptApp());

    expect(find.text('AIRCRYPT'), findsOneWidget);
    expect(find.text('SEND FILES'), findsOneWidget);
    expect(find.text('RECEIVE FILES'), findsOneWidget);
    expect(find.text('RECEIVED FILES'), findsOneWidget);
    expect(find.text('TRANSFER HISTORY'), findsOneWidget);
    expect(find.text('TRASH'), findsOneWidget);
  });
}
