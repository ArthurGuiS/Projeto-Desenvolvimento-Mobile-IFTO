import 'package:flutter_test/flutter_test.dart';
import 'package:pontoapp/main.dart';
import 'package:pontoapp/views/login_page.dart';

void main() {
  testWidgets('MyApp carrega a LoginPage inicialmente', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
