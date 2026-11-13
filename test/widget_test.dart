
import 'package:flutter_test/flutter_test.dart';
import 'package:mad_inclass15/main.dart';

void main() {
  testWidgets('Science Signal app launches', (tester) async {
    await tester.pumpWidget(const ScienceSignalApp());

    expect(find.text('Science Signal'), findsOneWidget);
    expect(find.text('Loading science questions...'), findsOneWidget);
  });
}
