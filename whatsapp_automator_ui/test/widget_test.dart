// ignore_for_file: unused_import
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:whatsapp_automator_ui/app.dart';
import 'package:whatsapp_automator_ui/providers/bot_provider.dart';

void main() {
  testWidgets('App launches and shows WhatsApp Automator title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => BotProvider()),
        ],
        child: const WhatsAppAutomatorApp(),
      ),
    );
    await tester.pump();
    expect(find.text('WhatsApp Automator'), findsOneWidget);
  });
}
