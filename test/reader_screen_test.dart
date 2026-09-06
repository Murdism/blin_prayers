import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Shiwan/data.dart';
import 'package:Shiwan/reader_screen.dart';
import 'package:Shiwan/store.dart';
import 'package:Shiwan/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('uses the reviewed collection names and Creed identities',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await store.init();
    late AppData data;
    await tester.runAsync(() async {
      data = await AppData.load();
    });

    expect(data.groupMeta['daily']?.title, 'ዲማ ድምስተው ሺዋን');
    expect(data.groupMeta['way']?.title, 'ፊዅሰን መስቀሉ');
    expect(data.groupMeta['confession']?.title, 'ንስሓዲ ቍርባንዲ');
    expect(data.catechismItems.first.groupTitle, 'ክርስቶስር ክኒ ግናቲትድ');
    expect(data.hymns, hasLength(12));
    expect(data.hymns.first.id, 'h_docx_2026_01');
    expect(data.hymns.first.title, 'ጐና ፈርኖ');
    expect(data.byId('h_1'), isNull);
    expect(data.hymns.first.hymnIntro, contains('ሉቃ 2: 10-12'));
    expect(data.hymns.first.hymnCredits, hasLength(2));
    expect(data.hymns.first.body, isNot(contains('ላሕማ፥')));
    expect(data.hymns.where((hymn) => hymn.refrain.isNotEmpty), hasLength(11));
    expect(data.hymns.first.refrain, startsWith('ጐና ፈርኖ ቤተልሔም ጐና ፈርኖ'));
    expect(data.hymns.first.refrain, isNot(startsWith('ጐና ፈርኖ ቤተልሔም\n')));
    expect(data.hymns.first.verses, hasLength(3));
    expect(
      data.hymns.first.hymnSections.map((section) => section.type),
      ['refrain', 'refrain', 'verse', 'verse', 'verse'],
    );
    expect(
      data.hymns.first.hymnSections[0].text,
      isNot(data.hymns.first.hymnSections[1].text),
    );
    expect(
      data
          .byId('h_docx_2026_03')!
          .hymnSections
          .map((section) => section.type)
          .take(3),
      ['verse', 'refrain', 'verse'],
    );
    final colorGroupedRefrain = data.byId('h_docx_2026_03')!.refrain;
    final refrainParts = colorGroupedRefrain.split('\n\n');
    expect(refrainParts, hasLength(3));
    expect(refrainParts.map((part) => part.split('\n').length), [3, 3, 7]);
    expect(
      data.byId('h_docx_2026_08')!.hymnSections.map((section) => section.type),
      ['verse', 'refrain', 'verse', 'verse', 'refrain', 'verse', 'refrain'],
    );
    expect(data.byId('h_docx_2026_07')!.refrain, isEmpty);
    for (final hymn in data.hymns.where((hymn) => hymn.refrain.isNotEmpty)) {
      expect(hymn.verses, everyElement(isNot(hymn.refrain)));
    }
    expect(data.byId('h_docx_2026_02')!.hymnCredits, hasLength(1));
    expect(
        data.byId('h_docx_2026_02')!.hymnCredits.single, 'ላሕማዲ ሒንዲ\nኤልያስ መስመር');

    final creed = data.byId('p_creed')!;
    expect(creed.sub, 'The Apostles’ Creed & Act of Faith');
    expect('${creed.sub} ${creed.note}'.contains('Nicene'), isFalse);
    final niceneCreed = data.byId('p_nicene_creed')!;
    expect(niceneCreed.title, 'ሺዋን ኣማነቱዅ ኒቅዪዅ');
    expect(niceneCreed.sub, 'The Nicene Creed');
    expect(niceneCreed.body, startsWith('ዲባ፡'));
    expect(niceneCreed.body, endsWith('አሜን።'));
    final faithItems = data.itemsInGroup('faith');
    expect(
      faithItems.map((item) => item.id),
      ['p_creed', 'p_nicene_creed', 'p_acts'],
    );

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme(dark: false),
      home: ReaderScreen(
        data: data,
        store: store,
        itemId: 'p_creed',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('THE APOSTLES’ CREED'), findsOneWidget);
    expect(find.text('ACT OF FAITH'), findsOneWidget);
  });

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

  testWidgets('Way navigation uses the reviewed Back and Next labels',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await store.init();
    late AppData data;
    await tester.runAsync(() async {
      data = await AppData.load();
    });

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme(dark: false),
      home: ReaderScreen(
        data: data,
        store: store,
        itemId: 'p_way_station_01',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('ወንተሪ'), findsOneWidget);
    expect(find.text('ደኵሲ'), findsOneWidget);
  });

  testWidgets('hymn introductions and credits are separate from lyrics',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await store.init();
    late AppData data;
    await tester.runAsync(() async {
      data = await AppData.load();
    });

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme(dark: false),
      home: ReaderScreen(
        data: data,
        store: store,
        itemId: 'h_docx_2026_01',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Scripture introduction'), findsOneWidget);
    expect(find.text('· Refrain'), findsNWidgets(2));
    expect(find.text('Credits'), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);
    expect(find.text('MELODY'), findsOneWidget);
    expect(find.text('ላሕማ፥ እኽር ፍሬእግዚእ በኪት'), findsOneWidget);
    expect(find.text('ሒን፥ ኤልያስ መስመር'), findsOneWidget);
  });

  testWidgets('three source-color refrain parts have visible dividers',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await store.init();
    late AppData data;
    await tester.runAsync(() async {
      data = await AppData.load();
    });

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.theme(dark: false),
      home: ReaderScreen(
        data: data,
        store: store,
        itemId: 'h_docx_2026_03',
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('refrain-part-divider-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('refrain-part-divider-1')),
      findsOneWidget,
    );
    expect(find.text('· Refrain'), findsOneWidget);
  });
}
