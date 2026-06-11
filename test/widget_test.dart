import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wanu/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('login screen renders email and password fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: LoginScreen())),
    );

    expect(find.text('WANU STUDIO'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
