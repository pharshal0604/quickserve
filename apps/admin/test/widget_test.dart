import 'package:quickserve_admin/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Admin portal presents administrator sign-in', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to your administrator account.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
