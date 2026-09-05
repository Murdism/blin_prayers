import 'package:flutter/material.dart';

import 'data.dart';
import 'theme.dart';

/// Returns the canonical station number encoded in a Way of the Cross item id.
int? wayStationNumber(Item item) {
  final match = RegExp(r'^p_way_station_(\d{2})$').firstMatch(item.id);
  return match == null ? null : int.tryParse(match.group(1)!);
}

/// Purpose-built collection view for the preparation, fourteen stations, and
/// conclusion. Source order remains authoritative; this changes presentation.
class WayOfCrossJourney extends StatelessWidget {
  final List<Item> items;
  final bool Function(String itemId) isFavorite;
  final ValueChanged<Item> onOpen;

  const WayOfCrossJourney({
    super.key,
    required this.items,
    required this.isFavorite,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final stations =
        items.where((item) => wayStationNumber(item) != null).toList();
    final preparation =
        items.where((item) => item.id == 'p_wayofcross').firstOrNull;
    final conclusion =
        items.where((item) => item.id == 'p_way_conclusion').firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _JourneyHero(
          stationCount: stations.length,
          onBegin: preparation == null ? null : () => onOpen(preparation),
          visual: stations.firstOrNull?.visuals.firstOrNull,
        ),
        if (preparation != null) ...[
          const SizedBox(height: 14),
          _BookendCard(
            item: preparation,
            icon: Icons.self_improvement_rounded,
            eyebrow: 'BEFORE THE FIRST STATION',
            actionLabel: 'Open preparation',
            onTap: () => onOpen(preparation),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'The fourteen stations',
                style: AppTheme.latin(
                  size: 19,
                  w: FontWeight.w700,
                  color: context.palette.primary,
                  style: FontStyle.normal,
                ),
              ),
            ),
            Text(
              '${stations.length} stops',
              style: AppTheme.latin(
                size: 14,
                w: FontWeight.w600,
                color: context.palette.inkMuted,
                style: FontStyle.normal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Choose a station, or begin with the preparation and move through them in order.',
          style: AppTheme.latin(size: 15.5, style: FontStyle.normal),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 2 : 1;
            final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
            final cardHeight = (164 + (textScale - 1) * 76).clamp(164, 238);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stations.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: cardHeight.toDouble(),
              ),
              itemBuilder: (context, index) {
                final item = stations[index];
                return _StationCard(
                  item: item,
                  station: wayStationNumber(item)!,
                  favorite: isFavorite(item.id),
                  onTap: () => onOpen(item),
                );
              },
            );
          },
        ),
        if (conclusion != null) ...[
          const SizedBox(height: 18),
          _BookendCard(
            item: conclusion,
            icon: Icons.wb_sunny_rounded,
            eyebrow: 'AFTER THE FOURTEENTH STATION',
            actionLabel: 'Open conclusion',
            onTap: () => onOpen(conclusion),
            visual: conclusion.visuals.firstOrNull,
          ),
        ],
      ],
    );
  }
}

class _JourneyHero extends StatelessWidget {
  final int stationCount;
  final VoidCallback? onBegin;
  final ContentVisual? visual;

  const _JourneyHero({
    required this.stationCount,
    required this.onBegin,
    required this.visual,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.palette.primaryDark, const Color(0xFF321015)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x337A1F2B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (visual != null)
            Positioned.fill(
              child: Image.asset(
                visual!.asset,
                alignment: Alignment.centerRight,
                fit: BoxFit.cover,
                cacheWidth:
                    (850 * MediaQuery.devicePixelRatioOf(context)).round(),
                excludeFromSemantics: true,
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    context.palette.primaryDark,
                    context.palette.primaryDark.withValues(alpha: 0.82),
                    const Color(0xB8321015),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            right: -18,
            top: -42,
            child: Text(
              '✝',
              style: TextStyle(fontSize: 150, color: Color(0x12FFFFFF)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0x55CDA85A)),
                  ),
                  child: Text(
                    'DEVOTIONAL JOURNEY · $stationCount STATIONS',
                    style: AppTheme.latin(
                      size: 11.5,
                      w: FontWeight.w700,
                      color: const Color(0xFFE9CB8D),
                      style: FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'ፊዅሰን መስቀሉ',
                  style: AppTheme.geezSerif(
                    size: 28,
                    w: FontWeight.w700,
                    color: const Color(0xFFF9F0DE),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'The Way of the Cross',
                  style: AppTheme.latin(
                    size: 19,
                    w: FontWeight.w600,
                    color: const Color(0xFFE9D9BA),
                    style: FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 13),
                Text(
                  'Follow the complete source sequence with its prayers, responses, Scripture, and sacred images.',
                  style: AppTheme.latin(
                    size: 15.5,
                    color: const Color(0xFFE9D9BA),
                    style: FontStyle.normal,
                  ).copyWith(height: 1.35),
                ),
                if (onBegin != null) ...[
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onBegin,
                    style: FilledButton.styleFrom(
                      foregroundColor: context.palette.primaryDark,
                      backgroundColor: const Color(0xFFF4DDAA),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      'Begin with preparation',
                      style: AppTheme.latin(
                        size: 15,
                        w: FontWeight.w700,
                        color: context.palette.primaryDark,
                        style: FontStyle.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final Item item;
  final int station;
  final bool favorite;
  final VoidCallback onTap;

  const _StationCard({
    required this.item,
    required this.station,
    required this.favorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = item.visuals.firstOrNull;
    final thumbnailWidth =
        (116 * MediaQuery.devicePixelRatioOf(context)).round();
    return Semantics(
      button: true,
      label: 'Station $station. ${item.title}. ${item.sub}',
      child: Material(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: context.palette.outline, width: 1.25),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 116,
                  height: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (visual != null)
                        Image.asset(
                          visual.asset,
                          fit: BoxFit.cover,
                          cacheWidth: thumbnailWidth,
                          excludeFromSemantics: true,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: context.palette.surfaceMuted,
                            child: Icon(Icons.image_not_supported_outlined,
                                color: context.palette.goldText),
                          ),
                        )
                      else
                        ColoredBox(color: context.palette.surfaceMuted),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0x8A000000)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.palette.primaryDark,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFE7CA8B), width: 1.5),
                          ),
                          child: Text(
                            '$station',
                            style: AppTheme.latin(
                              size: 18,
                              w: FontWeight.w700,
                              color: Colors.white,
                              style: FontStyle.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 13, 11, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'STATION $station',
                                style: AppTheme.latin(
                                  size: 11.5,
                                  w: FontWeight.w700,
                                  color: context.palette.goldText,
                                  style: FontStyle.normal,
                                ),
                              ),
                            ),
                            if (favorite)
                              Icon(Icons.star_rounded,
                                  size: 18, color: context.palette.goldText),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.geezSerif(
                            size: 17,
                            w: FontWeight.w700,
                            color: context.palette.primary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.sub
                              .replaceFirst(RegExp(r'^Station \d+ ·\s*'), ''),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.latin(
                                  size: 14.5, style: FontStyle.normal)
                              .copyWith(height: 1.2),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              'Open station',
                              style: AppTheme.latin(
                                size: 13,
                                w: FontWeight.w700,
                                color: context.palette.primarySoft,
                                style: FontStyle.normal,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded,
                                size: 17, color: context.palette.primarySoft),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookendCard extends StatelessWidget {
  final Item item;
  final IconData icon;
  final String eyebrow;
  final String actionLabel;
  final VoidCallback onTap;
  final ContentVisual? visual;

  const _BookendCard({
    required this.item,
    required this.icon,
    required this.eyebrow,
    required this.actionLabel,
    required this.onTap,
    this.visual,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailWidth =
        (104 * MediaQuery.devicePixelRatioOf(context)).round();
    return Material(
      color: context.palette.surfaceMuted,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border:
                Border.all(color: context.palette.goldDecorative, width: 1.2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              if (visual != null)
                SizedBox(
                  width: 104,
                  height: 138,
                  child: Image.asset(
                    visual!.asset,
                    fit: BoxFit.cover,
                    cacheWidth: thumbnailWidth,
                    excludeFromSemantics: true,
                  ),
                )
              else
                Container(
                  width: 74,
                  height: 138,
                  alignment: Alignment.center,
                  color: context.palette.surfaceMuted,
                  child: Icon(icon, size: 30, color: context.palette.primary),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: AppTheme.latin(
                          size: 11,
                          w: FontWeight.w700,
                          color: context.palette.goldText,
                          style: FontStyle.normal,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.geezSerif(
                          size: 18,
                          w: FontWeight.w700,
                          color: context.palette.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.sub,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTheme.latin(size: 14, style: FontStyle.normal),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        actionLabel,
                        style: AppTheme.latin(
                          size: 13,
                          w: FontWeight.w700,
                          color: context.palette.primarySoft,
                          style: FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right_rounded,
                    color: context.palette.primarySoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
