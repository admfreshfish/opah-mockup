import 'package:flutter_test/flutter_test.dart';

import 'package:opah/main.dart';

void main() {
  testWidgets('Home screen shows Opah title and event sections', (WidgetTester tester) async {
    await tester.pumpWidget(const OpahApp());

    expect(find.text('Opah'), findsOneWidget);
    expect(find.text('My events'), findsOneWidget);
    expect(find.text('Invited to'), findsOneWidget);
    expect(find.text('New event'), findsOneWidget);
  });
}
