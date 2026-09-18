import 'package:quickserve_admin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Admin portal presents administrator sign-in', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.text('QuickServe Admin'), findsOneWidget);
    expect(find.text('Sign in with an administrator account.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
