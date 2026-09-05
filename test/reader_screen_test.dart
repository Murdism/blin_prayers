import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Shiwan/data.dart';
import 'package:Shiwan/reader_screen.dart';
import 'package:Shiwan/store.dart';
import 'package:Shiwan/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opening a subsection normally starts at the top',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await store.init();
    store.setReadingOffset('p_rosary_joyful', 600);
    late AppData data;
    await tester.runAsync(() async {
      data = await AppData.load();
    });

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme(dark: false),
      home: ReaderScreen(
        data: data,
        store: store,
        itemId: 'p_rosary_joyful',
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final reader = tester.widget<ListView>(find.byType(ListView).first);
    expect(reader.controller?.offset, 0);
  });
}
