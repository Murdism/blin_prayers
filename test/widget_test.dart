import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Shiwan/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('loads shell, search, and the grouped Rosary', (tester) async {
    await _pumpLoadedApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('ልጝን'), findsOneWidget);
    expect(find.text('Quick prayer'), findsOneWidget);
    expect(find.text('Catholic Eparchy of Keren'), findsNothing);

    await tester.tap(find.byIcon(Icons.school_rounded));
    await tester.pumpAndSettle();
    expect(find.text('ክርስቶስር ክኒ ግናቲትድ'), findsOneWidget);
    expect(find.textContaining('First Communion'), findsNothing);
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rosary: opening, mysteries & litany'));
    await tester.pumpAndSettle();
    expect(find.text('ROSARY'), findsOneWidget);
    expect(find.text('Opening, mysteries & litany'), findsOneWidget);
    expect(find.text('Other Marian prayer'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('marian-prayers-icon')),
      findsOneWidget,
    );
    expect(find.text('Opening Prayers of the Rosary'), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('ጠፍሕ · Search'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('ናድካ · All'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ማርያም');
    await tester.pumpAndSettle();

    expect(find.text('ናድካ · All'), findsOneWidget);
    expect(find.text('ሺዋን'), findsWidgets);
    expect(find.text('Catechism'), findsWidgets);
    expect(find.text('መዛሙር'), findsWidgets);

    await tester.tap(find.byTooltip('ጠፍሕ · Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();
    expect(find.text('ክማና ሺዋኑዅ'), findsOneWidget);
    await tester.tap(find.text('ማርያምር ሺዋን').first);
    await tester.pumpAndSettle();

    expect(find.text('ROSARY'), findsOneWidget);
    expect(find.text('Opening, mysteries & litany'), findsOneWidget);
    expect(find.text('Other Marian prayer'), findsOneWidget);
    expect(find.text('ይና ገና ማርያም ጊመት ሰላምሪ'), findsOneWidget);
    expect(find.text('ማርያምር ጅኝጃን'), findsNothing);

    await tester.ensureVisible(find.text('Opening, mysteries & litany'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opening, mysteries & litany'));
    await tester.pumpAndSettle();
    expect(find.text('7 connected sections'), findsOneWidget);
    expect(find.text('Opening prayers · 1 section'), findsOneWidget);
    expect(find.text('Choose one set · 4 sections'), findsOneWidget);
    expect(find.text('Final prayers · 2 sections'), findsOneWidget);
    expect(find.text('ማርያምር ጅኝጃን'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ማርያምር ጅኝጃን'));
    await tester.pumpAndSettle();
    expect(find.text('ዎ ይና አደራ'), findsNWidgets(3));
    expect(find.text('ረሓሚና'), findsNWidgets(3));
    expect(find.text('ዎ ክርስቶስ'), findsNWidgets(2));
    expect(find.text('ዋሲና'), findsOneWidget);
    expect(find.text('ሸኑሪና'), findsOneWidget);
  });
}

Future<void> _pumpLoadedApp(WidgetTester tester) async {
  await tester.pumpWidget(const BlinApp());
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  for (var attempt = 0;
      attempt < 80 && find.byType(NavigationBar).evaluate().isEmpty;
      attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.byType(NavigationBar), findsOneWidget);
}
