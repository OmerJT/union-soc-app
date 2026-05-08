import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:unisoc_app/main.dart';
import 'package:unisoc_app/screens/register_screen.dart';
import 'package:unisoc_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UniSoc login screen loads with core actions', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthService(),
        child: const UniSocApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('UniSoc'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });

  testWidgets('Register screen includes admin option and UP number logic', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthService(),
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );
    expect(find.text('Register as society admin'), findsOneWidget);
    expect(find.textContaining('UP Number'), findsOneWidget);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('UP Number'), findsNothing);
  });
}
