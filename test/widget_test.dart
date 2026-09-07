import 'package:flutter_test/flutter_test.dart';
import 'package:aircrypt/main.dart';

void main() {
  testWidgets('Aircrypt application starts', (WidgetTester tester) async {
    await tester.pumpWidget(const AircryptApp());

    expect(find.text('Aircrypt'), findsOneWidget);
    expect(find.text('Send Files'), findsOneWidget);
    expect(find.text('Receive Files'), findsOneWidget);
  });
}