import 'package:flutter_test/flutter_test.dart';
import 'package:tlbb_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TlbbApp());
    expect(find.text('天龙亿旧'), findsWidgets);
  });
}
