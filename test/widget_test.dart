import 'package:flutter_test/flutter_test.dart';
import 'package:familyvault/main.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const FamilyVaultApp());
    await tester.pumpAndSettle();

    expect(find.text('FamilyVault'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
