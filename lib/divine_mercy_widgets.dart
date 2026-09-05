import 'package:flutter/material.dart';

import 'data.dart';
import 'theme.dart';
import 'widgets.dart';

class DivineMercyStageDefinition {
  final String eyebrow;
  final String title;
  final String description;
  final IconData icon;

  const DivineMercyStageDefinition({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.icon,
  });
}

const divineMercyStages = <DivineMercyStageDefinition>[
  DivineMercyStageDefinition(
    eyebrow: 'CHAPLET',
    title: 'How to pray',
    description: 'Ten prayer steps with every prayer shown in full.',
    icon: Icons.blur_circular_rounded,
  ),
  DivineMercyStageDefinition(
    eyebrow: "THREE O'CLOCK",
    title: 'Prayer of trust',
    description: 'The prayer appointed for the hour of mercy.',
    icon: Icons.schedule_rounded,
  ),
  DivineMercyStageDefinition(
    eyebrow: 'LITANY',
    title: 'Divine Mercy',
    description: 'Every invocation and response in a readable sequence.',
    icon: Icons.favorite_rounded,
  ),
  DivineMercyStageDefinition(
    eyebrow: 'CONCLUSION',
    title: 'Closing prayers',
    description: 'Final invocation, Saint Faustina, reflection, and praise.',
    icon: Icons.auto_awesome_rounded,
  ),
];

/// Source-aware collection presentation for the single Divine Mercy item.
/// The stored item remains one devotion so its stable ID and favorites survive;
/// the four stages are presentation-level waypoints within that devotion.
class DivineMercyJourney extends StatelessWidget {
  final Item item;
  final bool favorite;
  final void Function(Item item, int stage) onOpen;

  const DivineMercyJourney({
    super.key,
    required this.item,
    required this.favorite,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final visual = item.visuals.firstOrNull;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD3B87B), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x247A1F2B),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MercyJourneyHero(
            item: item,
            visual: visual,
            favorite: favorite,
            onBegin: () => onOpen(item, 0),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pray in four stages',
                  style: AppTheme.latin(
                    size: 19,
                    w: FontWeight.w700,
                    color: context.palette.primary,
                    style: FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start from the beginning or return directly to a part of the devotion.',
                  style: AppTheme.latin(size: 15, style: FontStyle.normal),
                ),
                const SizedBox(height: 13),
                for (var index = 0;
                    index < divineMercyStages.length;
                    index++) ...[
                  _MercyStageCard(
                    index: index,
                    stage: divineMercyStages[index],
                    onTap: () => onOpen(item, index),
                  ),
                  if (index != divineMercyStages.length - 1)
                    const SizedBox(height: 9),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MercyJourneyHero extends StatelessWidget {
  final Item item;
  final ContentVisual? visual;
  final bool favorite;
  final VoidCallback onBegin;

  const _MercyJourneyHero({
    required this.item,
    required this.visual,
    required this.favorite,
    required this.onBegin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 315),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF39191C), Color(0xFF171D2B)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 640;
          final image = visual == null
              ? const SizedBox.shrink()
              : Image.asset(
                  visual!.asset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  cacheWidth:
                      (700 * MediaQuery.devicePixelRatioOf(context)).round(),
                  excludeFromSemantics: true,
                );
          final copy = _MercyHeroCopy(
            item: item,
            favorite: favorite,
            onBegin: onBegin,
          );
          if (wide) {
            return SizedBox(
              height: 390,
              child: Row(
                children: [
                  Expanded(flex: 5, child: copy),
                  Expanded(
                    flex: 4,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image,
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xCC39191C), Color(0x0039191C)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return Stack(
            children: [
              Positioned.fill(child: image),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x2639191C), Color(0xFA23171B)],
                      stops: [0.2, 0.82],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 245),
                child: copy,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MercyHeroCopy extends StatelessWidget {
  final Item item;
  final bool favorite;
  final VoidCallback onBegin;

  const _MercyHeroCopy({
    required this.item,
    required this.favorite,
    required this.onBegin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _HeroPill(label: 'COMPLETE DEVOTION'),
              if (favorite) ...[
                const SizedBox(width: 7),
                const Icon(Icons.star_rounded,
                    size: 19, color: Color(0xFFF1D494)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: AppTheme.geezSerif(
              size: 27,
              w: FontWeight.w700,
              color: const Color(0xFFFFF4DF),
            ).copyWith(height: 1.35),
          ),
          const SizedBox(height: 2),
          Text(
            item.sub,
            style: AppTheme.latin(
              size: 19,
              w: FontWeight.w600,
              color: const Color(0xFFEFDCC5),
              style: FontStyle.normal,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            'Follow the chaplet, the prayer at three o’clock, the complete litany, and its conclusion.',
            style: AppTheme.latin(
              size: 15.5,
              color: const Color(0xFFEAD8CB),
              style: FontStyle.normal,
            ).copyWith(height: 1.35),
          ),
          const SizedBox(height: 17),
          FilledButton.icon(
            onPressed: onBegin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF5DDAA),
              foregroundColor: const Color(0xFF4F1820),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Begin the chaplet'),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  const _HeroPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x33000000),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0x66F1D494)),
      ),
      child: Text(
        label,
        style: AppTheme.latin(
          size: 11,
          w: FontWeight.w700,
          color: const Color(0xFFF1D494),
          style: FontStyle.normal,
        ),
      ),
    );
  }
}

class _MercyStageCard extends StatelessWidget {
  final int index;
  final DivineMercyStageDefinition stage;
  final VoidCallback onTap;

  const _MercyStageCard({
    required this.index,
    required this.stage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent =
        index.isEven ? context.palette.mercyRed : context.palette.marianBlue;
    return Material(
      color: index.isEven ? context.palette.card : context.palette.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 12, 11, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stage.icon, size: 21, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. ${stage.title}',
                      style: AppTheme.latin(
                        size: 16.5,
                        w: FontWeight.w700,
                        color: context.palette.ink,
                        style: FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stage.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppTheme.latin(size: 13.5, style: FontStyle.normal),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class DivineMercyContent {
  final String heading;
  final List<String> steps;
  final String threeOClock;
  final String litany;
  final String closingInvocation;
  final String reflection;
  final String finalAcclamation;

  const DivineMercyContent({
    required this.heading,
    required this.steps,
    required this.threeOClock,
    required this.litany,
    required this.closingInvocation,
    required this.reflection,
    required this.finalAcclamation,
  });

  factory DivineMercyContent.parse(String source) {
    final body = source.trim();
    const litanyHeading = 'ራሕመት መለኮቱዅሊ ሱኵራዅ ጅኝጃን';
    final litanyStart = body.indexOf('\n\n$litanyHeading');
    final preLitany = litanyStart < 0 ? body : body.substring(0, litanyStart);
    final litanyAndClosing =
        litanyStart < 0 ? '' : body.substring(litanyStart + 2).trim();

    final threeStart = preLitany.indexOf('\n(ግርግ');
    final instructionText =
        threeStart < 0 ? preLitany : preLitany.substring(0, threeStart);
    final threeOClock =
        threeStart < 0 ? '' : preLitany.substring(threeStart + 1).trim();

    final stepExpression = RegExp(r'^(\d{1,2})\.\s*', multiLine: true);
    final matches = stepExpression.allMatches(instructionText).toList();
    final steps = <String>[];
    for (var index = 0; index < matches.length; index++) {
      final end = index + 1 < matches.length
          ? matches[index + 1].start
          : instructionText.length;
      steps.add(instructionText.substring(matches[index].end, end).trim());
    }
    final heading = matches.isEmpty
        ? instructionText.trim()
        : instructionText.substring(0, matches.first.start).trim();

    final closingStart = litanyAndClosing.lastIndexOf('\n\nዎ ዕል ራሕመቱዅ');
    final litany = closingStart < 0
        ? litanyAndClosing
        : litanyAndClosing.substring(0, closingStart).trim();
    final closing = closingStart < 0
        ? ''
        : litanyAndClosing.substring(closingStart + 2).trim();
    final quoteStart = closing.indexOf('\n\n“');
    final reflectionAndAcclamation =
        quoteStart < 0 ? '' : closing.substring(quoteStart + 2).trim();
    const acclamationMarker = '\n\nጃር ኒትክዲሲ ሓመድሳዅ';
    final acclamationStart =
        reflectionAndAcclamation.indexOf(acclamationMarker);

    return DivineMercyContent(
      heading: heading,
      steps: steps,
      threeOClock: threeOClock,
      litany: litany,
      closingInvocation:
          quoteStart < 0 ? closing : closing.substring(0, quoteStart).trim(),
      reflection: acclamationStart < 0
          ? reflectionAndAcclamation
          : reflectionAndAcclamation.substring(0, acclamationStart).trim(),
      finalAcclamation: acclamationStart < 0
          ? ''
          : reflectionAndAcclamation.substring(acclamationStart + 2).trim(),
    );
  }
}

/// Dedicated reader for the supplied image and pages 42–47 of the 2025 book.
class DivineMercyReader extends StatelessWidget {
  final Item item;
  final int stageIndex;
  final double scale;
  final bool showNotes;
  final ValueChanged<int> onStageChanged;
  final VoidCallback onCompleted;
  final void Function(ContentVisual visual, String label) onImageTap;

  const DivineMercyReader({
    super.key,
    required this.item,
    required this.stageIndex,
    required this.scale,
    required this.showNotes,
    required this.onStageChanged,
    required this.onCompleted,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = DivineMercyContent.parse(item.body);
    final safeStage = stageIndex.clamp(0, divineMercyStages.length - 1).toInt();
    final visual = item.visuals.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (visual != null) ...[
          _MercyReaderHero(
            item: item,
            visual: visual,
            stage: divineMercyStages[safeStage],
            stageIndex: safeStage,
            scale: scale,
            onTap: () => onImageTap(
              visual,
              visual.alt.isNotEmpty ? visual.alt : item.title,
            ),
          ),
          const SizedBox(height: 14),
        ],
        _MercyStageSelector(
          selected: safeStage,
          onSelected: onStageChanged,
        ),
        if (showNotes && item.note.trim().isNotEmpty) ...[
          const SizedBox(height: 13),
          NotePanel(item.note),
        ],
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(safeStage),
            child: switch (safeStage) {
              0 => _ChapletSteps(
                  content: content,
                  scale: scale,
                ),
              1 => _ThreeOClockPrayer(
                  text: content.threeOClock,
                  scale: scale,
                ),
              2 => _MercyLitany(text: content.litany, scale: scale),
              _ => _MercyConclusion(
                  invocation: content.closingInvocation,
                  reflection: content.reflection,
                  finalAcclamation: content.finalAcclamation,
                  scale: scale,
                ),
            },
          ),
        ),
        const SizedBox(height: 18),
        _MercyNavigation(
          stageIndex: safeStage,
          onSelected: onStageChanged,
          onCompleted: onCompleted,
        ),
      ],
    );
  }
}

class _MercyReaderHero extends StatelessWidget {
  final Item item;
  final ContentVisual visual;
  final DivineMercyStageDefinition stage;
  final int stageIndex;
  final double scale;
  final VoidCallback onTap;

  const _MercyReaderHero({
    required this.item,
    required this.visual,
    required this.stage,
    required this.stageIndex,
    required this.scale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B191E), Color(0xFF14233A)],
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x307A1F2B), blurRadius: 24, offset: Offset(0, 9)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageHeight = constraints.maxWidth < 520 ? 430.0 : 520.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                image: true,
                button: true,
                label: '${visual.alt}. Open full-screen image.',
                child: InkWell(
                  onTap: onTap,
                  child: SizedBox(
                    height: imageHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          visual.asset,
                          fit: BoxFit.contain,
                          excludeFromSemantics: true,
                        ),
                        const Positioned(
                          top: 12,
                          right: 12,
                          child: _ImageZoomBadge(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(19, 16, 19, 18),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: stageIndex.isEven
                          ? context.palette.mercyRed
                          : context.palette.marianBlue,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${stage.eyebrow} · ${stageIndex + 1} OF 4',
                      style: AppTheme.latin(
                        size: 11.5,
                        w: FontWeight.w700,
                        color: const Color(0xFFF1D494),
                        style: FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      item.title,
                      style: AppTheme.geezSerif(
                        size: 24 * scale,
                        w: FontWeight.w700,
                        color: const Color(0xFFFFF4DF),
                      ).copyWith(height: 1.35),
                    ),
                    Text(
                      stage.title,
                      style: AppTheme.latin(
                        size: 18 * scale,
                        w: FontWeight.w600,
                        color: const Color(0xFFEAD8CB),
                        style: FontStyle.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImageZoomBadge extends StatelessWidget {
  const _ImageZoomBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xB3000000),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.zoom_in_rounded, size: 20, color: Colors.white),
      ),
    );
  }
}

class _MercyStageSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;

  const _MercyStageSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.outline),
      ),
      child: Row(
        children: [
          for (var index = 0; index < divineMercyStages.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: index == divineMercyStages.length - 1 ? 0 : 5),
                child: Semantics(
                  selected: selected == index,
                  label: '${index + 1}. ${divineMercyStages[index].title}',
                  child: Material(
                    color: selected == index
                        ? (index.isEven
                            ? context.palette.mercyRed
                            : context.palette.marianBlue)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onSelected(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          children: [
                            Icon(
                              divineMercyStages[index].icon,
                              size: 20,
                              color: selected == index
                                  ? Colors.white
                                  : context.palette.inkMuted,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${index + 1}',
                              style: AppTheme.latin(
                                size: 12,
                                w: FontWeight.w700,
                                color: selected == index
                                    ? Colors.white
                                    : context.palette.inkMuted,
                                style: FontStyle.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChapletSteps extends StatelessWidget {
  final DivineMercyContent content;
  final double scale;

  const _ChapletSteps({
    required this.content,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageHeading(
          icon: Icons.blur_circular_rounded,
          eyebrow: 'BEGIN THE DEVOTION',
          title: content.heading,
          description:
              'Follow all ten steps in order. The complete opening prayers are included directly.',
          accent: context.palette.mercyRed,
          scale: scale,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < content.steps.length; index++) ...[
          _InstructionCard(
            number: index + 1,
            text: content.steps[index],
            scale: scale,
          ),
          if (index != content.steps.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _InstructionCard extends StatelessWidget {
  final int number;
  final String text;
  final double scale;

  const _InstructionCard({
    required this.number,
    required this.text,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 15, 15, 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: number.isEven
                        ? context.palette.marianBlue
                        : context.palette.mercyRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: AppTheme.latin(
                      size: 17,
                      w: FontWeight.w700,
                      color: Colors.white,
                      style: FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(child: PrayerText(text, scale: scale)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreeOClockPrayer extends StatelessWidget {
  final String text;
  final double scale;

  const _ThreeOClockPrayer({required this.text, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageHeading(
          icon: Icons.schedule_rounded,
          eyebrow: "THE HOUR OF MERCY · 3 O'CLOCK",
          title: 'ሺዋን ራሕመቱዅድ',
          description:
              'Pray this after the chaplet instructions and before the litany.',
          accent: context.palette.marianBlue,
          scale: scale,
        ),
        const SizedBox(height: 12),
        _PrayerPanel(
          accent: context.palette.marianBlue,
          icon: Icons.water_drop_outlined,
          label: 'PRAYER OF TRUST',
          child: PrayerText(text, scale: scale),
        ),
      ],
    );
  }
}

class _MercyLitany extends StatelessWidget {
  final String text;
  final double scale;

  const _MercyLitany({required this.text, required this.scale});

  @override
  Widget build(BuildContext context) {
    final parsed = _parseLitany(text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageHeading(
          icon: Icons.favorite_rounded,
          eyebrow: 'CALL AND RESPONSE',
          title: parsed.heading,
          description: 'Pray each invocation with its response.',
          accent: context.palette.mercyRed,
          scale: scale,
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.palette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.outline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var index = 0; index < parsed.rows.length; index++) ...[
                if (index > 0)
                  Divider(height: 1, color: context.palette.outline),
                _LitanyRowCard(row: parsed.rows[index], scale: scale),
              ],
            ],
          ),
        ),
        if (parsed.finalPrayer.isNotEmpty) ...[
          const SizedBox(height: 14),
          _PrayerPanel(
            accent: context.palette.marianBlue,
            icon: Icons.self_improvement_rounded,
            label: 'ሺውኒን · CLOSING PRAYER',
            child: PrayerText(parsed.finalPrayer, scale: scale),
          ),
        ],
      ],
    );
  }
}

class _MercyConclusion extends StatelessWidget {
  final String invocation;
  final String reflection;
  final String finalAcclamation;
  final double scale;

  const _MercyConclusion({
    required this.invocation,
    required this.reflection,
    required this.finalAcclamation,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StageHeading(
          icon: Icons.auto_awesome_rounded,
          eyebrow: 'COMPLETE THE DEVOTION',
          title: 'Saint Faustina and final invocation',
          description: 'The complete concluding prayers and invocations.',
          accent: context.palette.marianBlue,
          scale: scale,
        ),
        const SizedBox(height: 12),
        _PrayerPanel(
          accent: context.palette.marianBlue,
          icon: Icons.self_improvement_rounded,
          label: 'FINAL INVOCATIONS',
          child: PrayerText(invocation, scale: scale),
        ),
        if (reflection.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(19, 18, 19, 19),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [context.palette.card, context.palette.surfaceMuted],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.palette.outline),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.format_quote_rounded,
                    size: 30, color: context.palette.mercyRed),
                const SizedBox(height: 7),
                PrayerText(reflection, scale: scale),
                const SizedBox(height: 10),
                Text(
                  'REFLECTION · SAINT FAUSTINA',
                  style: AppTheme.latin(
                    size: 11.5,
                    w: FontWeight.w700,
                    color: context.palette.marianBlue,
                    style: FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (finalAcclamation.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 21),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.palette.mercyRed, context.palette.marianBlue],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x229F2638),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(Icons.wb_sunny_rounded,
                    color: Colors.white, size: 27),
                const SizedBox(height: 9),
                SelectableText(
                  finalAcclamation,
                  textAlign: TextAlign.center,
                  style: AppTheme.geezSerif(
                    size: 19 * scale,
                    color: Colors.white,
                    w: FontWeight.w700,
                  ).copyWith(height: 1.75),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StageHeading extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String description;
  final Color accent;
  final double scale;

  const _StageHeading({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.accent,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 21, color: Colors.white),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  eyebrow,
                  style: AppTheme.latin(
                    size: 11.5,
                    w: FontWeight.w700,
                    color: accent,
                    style: FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Text(
            title,
            style: AppTheme.geezSerif(
              size: 23 * scale,
              w: FontWeight.w700,
              color: context.palette.primary,
            ).copyWith(height: 1.4),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: AppTheme.latin(size: 15, style: FontStyle.normal)
                .copyWith(height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _PrayerPanel extends StatelessWidget {
  final Color accent;
  final IconData icon;
  final String label;
  final Widget child;

  const _PrayerPanel({
    required this.accent,
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: AppTheme.latin(
                    size: 11.5,
                    w: FontWeight.w700,
                    color: accent,
                    style: FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1, color: context.palette.outline),
          ),
          child,
        ],
      ),
    );
  }
}

class _LitanyRow {
  final String invocation;
  final String response;
  const _LitanyRow(this.invocation, this.response);
}

class _ParsedLitany {
  final String heading;
  final List<_LitanyRow> rows;
  final String finalPrayer;
  const _ParsedLitany(this.heading, this.rows, this.finalPrayer);
}

final _mercyResponse = RegExp(
  r'(ረሓሚና|ራሓሚና|ሰኸንቲና|ሺዊልና|ዋሲና|ሸኑሪና|መሓሪና|ኵል እምነኵን|ብሕል ዪና)[።፥፣]?$',
);

_ParsedLitany _parseLitany(String source) {
  final prayerSplit = source.indexOf('\nሺውኒን\n');
  final invocations =
      prayerSplit < 0 ? source.trim() : source.substring(0, prayerSplit).trim();
  final finalPrayer = prayerSplit < 0
      ? ''
      : source.substring(prayerSplit + '\nሺውኒን\n'.length).trim();
  final lines = invocations.split('\n');
  final heading = lines.isEmpty ? '' : lines.first.trim();
  final rows = <_LitanyRow>[];
  var buffer = '';

  void emit(String line) {
    final clean = line.replaceAll(RegExp(r'\s*\.{2,}\s*'), ' ').trim();
    final responseMatch = _mercyResponse.firstMatch(clean);
    if (responseMatch == null) {
      if (clean.isNotEmpty) rows.add(_LitanyRow(clean, ''));
      return;
    }
    var invocation = clean.substring(0, responseMatch.start).trimRight();
    invocation = invocation.replaceFirst(RegExp(r'[፣፡,]\s*$'), '').trimRight();
    rows.add(_LitanyRow(invocation, clean.substring(responseMatch.start)));
  }

  for (final rawLine in lines.skip(1)) {
    final line = rawLine.trim();
    if (line.isEmpty) continue;
    buffer = buffer.isEmpty ? line : '$buffer $line';
    if (_mercyResponse.hasMatch(buffer)) {
      emit(buffer);
      buffer = '';
    }
  }
  if (buffer.isNotEmpty) emit(buffer);
  return _ParsedLitany(heading, rows, finalPrayer);
}

class _LitanyRowCard extends StatelessWidget {
  final _LitanyRow row;
  final double scale;

  const _LitanyRowCard({
    required this.row,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              row.invocation,
              style: AppTheme.geezSerif(
                size: 17.5 * scale,
                color: context.palette.ink,
              ).copyWith(height: 1.75),
            ),
          ),
          if (row.response.isNotEmpty) ...[
            const SizedBox(width: 18),
            Flexible(
              flex: 2,
              child: Text(
                row.response,
                textAlign: TextAlign.end,
                style: AppTheme.geezSerif(
                  size: 16 * scale,
                  w: FontWeight.w700,
                  color: context.palette.primarySoft,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MercyNavigation extends StatelessWidget {
  final int stageIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onCompleted;

  const _MercyNavigation({
    required this.stageIndex,
    required this.onSelected,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (stageIndex > 0)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => onSelected(stageIndex - 1),
              icon: const Icon(Icons.arrow_back_rounded),
              label: Text(divineMercyStages[stageIndex - 1].title),
            ),
          )
        else
          const Spacer(),
        if (stageIndex > 0 && stageIndex < divineMercyStages.length - 1)
          const SizedBox(width: 10),
        if (stageIndex < divineMercyStages.length - 1)
          Expanded(
            child: FilledButton.icon(
              onPressed: () => onSelected(stageIndex + 1),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(divineMercyStages[stageIndex + 1].title),
            ),
          )
        else
          Expanded(
            child: FilledButton.icon(
              onPressed: onCompleted,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: const Text('ተመሙዅ · Complete'),
            ),
          ),
      ],
    );
  }
}
