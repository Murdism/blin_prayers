import 'package:flutter/material.dart';

import 'data.dart';
import 'divine_mercy_widgets.dart';
import 'reader_screen.dart';
import 'rosary_screen.dart';
import 'store.dart';
import 'theme.dart';
import 'way_of_cross_widgets.dart';
import 'widgets.dart';

class PrayerCollectionScreen extends StatelessWidget {
  final AppData data;
  final AppStore store;
  final String groupId;

  const PrayerCollectionScreen({
    super.key,
    required this.data,
    required this.store,
    required this.groupId,
  });

  void _open(BuildContext context, Item item, {int? mercyStage}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          data: data,
          store: store,
          itemId: item.id,
          initialMercyStage: mercyStage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = data.groupMeta[groupId]!;
    final items = data.itemsInGroup(groupId);
    final presentation = prayerGroupPresentation(groupId);
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          backgroundColor: context.palette.primaryDark,
          foregroundColor: const Color(0xFFFFF4DF),
          title: Text(
            meta.title,
            style: AppTheme.geezSerif(
              size: 18,
              w: FontWeight.w700,
              color: const Color(0xFFFFF4DF),
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
                      eyebrow: presentation.eyebrow,
                      title: meta.title,
                      subtitle: meta.en,
                      description: presentation.description,
                      icon: presentation.icon,
                      badge: groupId == 'rosary'
                          ? '2 prayer areas'
                          : '${items.length} ${items.length == 1 ? 'section' : 'sections'}',
                    ),
                    const SizedBox(height: 20),
                    if (groupId == 'rosary')
                      MarianPrayerJourney(
                        items: items,
                        isFavorite: store.isFav,
                        onOpen: (item) => _open(context, item),
                        onOpenRosary: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RosaryCollectionScreen(
                              data: data,
                              store: store,
                            ),
                          ),
                        ),
                      )
                    else if (groupId == 'way')
                      WayOfCrossJourney(
                        items: items,
                        isFavorite: store.isFav,
                        onOpen: (item) => _open(context, item),
                      )
                    else if (groupId == 'mercy')
                      DivineMercyJourney(
                        item: items.first,
                        favorite: store.isFav(items.first.id),
                        onOpen: (item, stage) =>
                            _open(context, item, mercyStage: stage),
                      )
                    else
                      PrayerGroupPanel(
                        title: meta.title,
                        subtitle: meta.en,
                        description: presentation.description,
                        icon: presentation.icon,
                        items: items,
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

({IconData icon, String eyebrow, String description}) prayerGroupPresentation(
    String group) {
  return switch (group) {
    'daily' => (
        icon: Icons.wb_sunny_outlined,
        eyebrow: 'EVERY DAY',
        description: 'Foundational prayers for the rhythm of every day.'
      ),
    'rosary' => (
        icon: Icons.blur_circular_rounded,
        eyebrow: 'WITH MARY',
        description:
            'The complete Rosary and a place for additional Marian prayers.'
      ),
    'mercy' => (
        icon: Icons.favorite_border_rounded,
        eyebrow: 'TRUST IN JESUS',
        description: 'The complete Chaplet of Divine Mercy and its litany.'
      ),
    'way' => (
        icon: Icons.add_rounded,
        eyebrow: 'FOLLOW THE CROSS',
        description:
            'Preparation, fourteen stations, Scripture, and conclusion.'
      ),
    'confession' => (
        icon: Icons.church_outlined,
        eyebrow: 'THE SACRAMENTS',
        description: 'Preparation and prayer for Confession and Communion.'
      ),
    'faith' => (
        icon: Icons.shield_outlined,
        eyebrow: 'PROFESS THE FAITH',
        description: 'The Creed and acts of hope, charity, and contrition.'
      ),
    'meals' => (
        icon: Icons.restaurant_rounded,
        eyebrow: 'AT THE FAMILY TABLE',
        description: 'Blessings before and after meals.'
      ),
    _ => (
        icon: Icons.auto_stories_outlined,
        eyebrow: 'PRAYER COLLECTION',
        description: 'Prayers and devotional reading.'
      ),
  };
}
