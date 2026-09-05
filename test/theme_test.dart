import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Shiwan/theme.dart';
import 'package:Shiwan/widgets.dart';

void main() {
  testWidgets('prayer text uses the readable night palette', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme(dark: true),
      home: const Scaffold(
        body: PrayerText('ዎ ይና አደራ ረሓሚና።'),
      ),
    ));

    final prayerText = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere((widget) =>
            widget.text.style?.fontFamily == AppTheme.geezSerifFamily);

    expect(prayerText.text.style?.color, AppPalette.night.ink);
    expect(
      Theme.of(tester.element(find.byType(PrayerText))).scaffoldBackgroundColor,
      AppPalette.night.background,
    );
  });
}
