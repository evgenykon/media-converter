import 'package:flutter_test/flutter_test.dart';

import 'package:media_converter/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MediaConverterApp());
    expect(find.text('Media Converter'), findsOneWidget);
  });
}
