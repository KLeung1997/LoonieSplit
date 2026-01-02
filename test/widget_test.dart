// Basic Flutter widget test for Loonie Split app

import 'package:flutter_test/flutter_test.dart';
import 'package:loonie_split/main.dart';
import 'package:loonie_split/services/tax_data_service.dart';

void main() {
  testWidgets('App loads and displays title', (WidgetTester tester) async {
    // Create a mock tax data service for testing
    final taxDataService = TaxDataService();

    // Build our app and trigger a frame.
    await tester.pumpWidget(OneBillApp(taxDataService: taxDataService));

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the app title is displayed
    expect(find.text('Loonie Split'), findsOneWidget);
    expect(find.text('The Bill Splitter in Canada'), findsOneWidget);
  });
}
