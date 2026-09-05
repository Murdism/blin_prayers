import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Shiwan/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('persists appearance and local reading continuity', () async {
    SharedPreferences.setMockInitialValues({});
    final first = AppStore();
    await first.init();

    first.setAppearance('night');
    first.setScale(1.55);
    first.recordOpened('p_mercy');
    first.setReadingOffset('p_mercy', 420.5);
    first.setMercyStage(2);
    first.markCompleted('p_mercy');

    final restored = AppStore();
    await restored.init();

    expect(restored.appearance, 'night');
    expect(restored.scale, 1.55);
    expect(restored.lastItemId, 'p_mercy');
    expect(restored.readingOffset('p_mercy'), 420.5);
    expect(restored.mercyStage, 2);
    expect(restored.isCompleted('p_mercy'), isTrue);

    restored.resetReading('p_mercy');
    expect(restored.readingOffset('p_mercy'), 0);
    expect(restored.mercyStage, 0);
    expect(restored.isCompleted('p_mercy'), isFalse);
  });
}
