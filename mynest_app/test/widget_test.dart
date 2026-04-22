import 'package:flutter_test/flutter_test.dart';
import 'package:mynest_app/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const MyNestApp());
    expect(find.text('MyNest'), findsWidgets);
  });
}
