import 'package:flutter/material.dart';

import 'data.dart';
import 'reader_screen.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

const _rosarySectionIds = {
  'p_rosary_open',
  'p_rosary_joyful',
  'p_rosary_sorrowful',
  'p_rosary_luminous',
  'p_rosary_glorious',
  'p_hail_holy_queen',
  'p_litany',
};

/// The Marian landing page keeps the Rosary together as one devotion while
/// leaving room for additional Marian prayers supplied in the future.
class MarianPrayerJourney extends StatelessWidget {
  final List<Item> items;
  final bool Function(String itemId) isFavorite;
  final ValueChanged<Item> onOpen;
  final VoidCallback onOpenRosary;

  const MarianPrayerJourney({
    super.key,
    required this.items,
    required this.isFavorite,
    required this.onOpen,
    required this.onOpenRosary,
  });

  @override
  Widget build(BuildContext context) {
    final rosary =
        items.where((item) => _rosarySectionIds.contains(item.id)).toList();
    final additional =
        items.where((item) => !_rosarySectionIds.contains(item.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RosaryEntryCard(sectionCount: rosary.length, onTap: onOpenRosary),
        if (additional.isNotEmpty) ...[
          const SizedBox(height: 22),
          Row(
            children: [
              Icon(Icons.local_florist_outlined,
                  color: context.palette.marianBlue, size: 24),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  additional.length == 1
                      ? 'Other Marian prayer'
                      : 'Other Marian prayers',
                  style: AppTheme.latin(
                    size: 18,
                    w: FontWeight.w700,
                    color: context.palette.ink,
                    style: FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          PrayerGroupPanel(
            title: 'ማርያምር ሺዋን',
            subtitle: 'Marian prayer',
            description:
                'Additional prayer to the Blessed Virgin Mary. More can be added here later.',
            icon: Icons.local_florist_outlined,
            items: additional,
            isFavorite: isFavorite,
            onOpen: onOpen,
          ),
        ],
      ],
    );
  }
}

class _RosaryEntryCard extends StatelessWidget {
  final int sectionCount;
  final VoidCallback onTap;

  const _RosaryEntryCard({required this.sectionCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.marianBlue,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            const Positioned(
              right: -22,
              top: -35,
              child: Icon(Icons.blur_circular_rounded,
                  size: 150, color: Color(0x18FFFFFF)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: const Color(0x66FFFFFF)),
                    ),
                    child: const Icon(Icons.blur_circular_rounded,
                        color: Color(0xFFFFF4DF), size: 31),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROSARY',
                          style: AppTheme.latin(
                            size: 12,
                            w: FontWeight.w700,
                            color: const Color(0xFFE6EDF7),
                            style: FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Opening, mysteries & litany',
                          style: AppTheme.latin(
                            size: 19,
                            w: FontWeight.w700,
                            color: const Color(0xFFFFFFFF),
                            style: FontStyle.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$sectionCount connected prayer sections',
                          style: AppTheme.latin(
                            size: 13.5,
                            color: const Color(0xFFE6EDF7),
                            style: FontStyle.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFFFFFFF), size: 27),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Rosary's internal page. Its concluding Marian litany remains part of
/// this sequence instead of being presented as a competing top-level prayer.
class RosaryCollectionScreen extends StatelessWidget {
  final AppData data;
  final AppStore store;

  const RosaryCollectionScreen(
      {super.key, required this.data, required this.store});

  void _open(BuildContext context, Item item) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderScreen(
        data: data,
        store: store,
        itemId: item.id,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final items = data
        .itemsInGroup('rosary')
        .where((item) => _rosarySectionIds.contains(item.id))
        .toList();
    final opening = items.where((item) => item.id == 'p_rosary_open').toList();
    final mysteries = items
        .where((item) => item.id.startsWith('p_rosary_'))
        .where((item) => item.id != 'p_rosary_open')
        .toList();
    final conclusion = items
        .where(
            (item) => item.id == 'p_hail_holy_queen' || item.id == 'p_litany')
        .toList();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: context.palette.primaryDark,
          foregroundColor: const Color(0xFFFFF4DF),
          title: Text(
            'Rosary',
            style: AppTheme.latin(
              size: 18,
              w: FontWeight.w700,
              color: const Color(0xFFFFF4DF),
              style: FontStyle.normal,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 38),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CollectionHero(
                      eyebrow: 'PRAY THE ROSARY',
                      title: 'ማርያምር ሺዋን',
                      subtitle: 'Rosary',
                      description:
                          'Begin with the opening prayers, choose the mysteries for the day, and finish with Hail Holy Queen and the Marian litany.',
                      icon: Icons.blur_circular_rounded,
                      badge: '${items.length} connected sections',
                    ),
                    const SizedBox(height: 20),
                    PrayerGroupPanel(
                      title: '1. Begin',
                      subtitle: 'Opening prayers',
                      description: 'Opening prayers of the Rosary.',
                      icon: Icons.play_circle_outline_rounded,
                      items: opening,
                      isFavorite: store.isFav,
                      onOpen: (item) => _open(context, item),
                    ),
                    const SizedBox(height: 14),
                    PrayerGroupPanel(
                      title: '2. Mysteries',
                      subtitle: 'Choose one set',
                      description:
                          'Choose the mystery set appointed for the day.',
                      icon: Icons.blur_circular_rounded,
                      items: mysteries,
                      isFavorite: store.isFav,
                      onOpen: (item) => _open(context, item),
                    ),
                    const SizedBox(height: 14),
                    PrayerGroupPanel(
                      title: '3. Conclude',
                      subtitle: 'Final prayers',
                      description:
                          'Finish with Hail Holy Queen and the Marian litany.',
                      icon: Icons.local_florist_outlined,
                      items: conclusion,
                      isFavorite: store.isFav,
                      onOpen: (item) => _open(context, item),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
