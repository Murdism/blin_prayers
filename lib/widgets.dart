import 'package:flutter/material.dart';
import 'data.dart';
import 'theme.dart';

/// Ornamental horizontal rule with a centered glyph.
class Ornament extends StatelessWidget {
  final String glyph;
  const Ornament({super.key, this.glyph = '❧'});
  @override
  Widget build(BuildContext context) {
    Widget rule() => Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0x00D9C9A8),
                context.palette.outline,
                const Color(0x00D9C9A8),
              ]),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        rule(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(glyph,
              style: TextStyle(color: context.palette.goldText, fontSize: 14)),
        ),
        rule(),
      ]),
    );
  }
}

/// Renders prayer / hymn body text with styled liturgical role markers
/// (መ፡ ዲ፡ ከዳ፡ ዲባ፡ …), verse numbers, rosary mystery ordinals, and
/// litany call-and-response lines (response word right-aligned in a Row).
class PrayerText extends StatefulWidget {
  final String text;
  final double scale;
  final String highlightQuery;
  const PrayerText(
    this.text, {
    super.key,
    this.scale = 1.0,
    this.highlightQuery = '',
  });

  @override
  State<PrayerText> createState() => _PrayerTextState();
}

class _PrayerTextState extends State<PrayerText> {
  final _focusNode = FocusNode();

  static final _roleRe = RegExp(r'^(\s*)(መ|ዲ|ከዳ|ዲባ|ፋ|ር|ሁ|ሕ)([፡፣፥:])');
  static final _verseRe = RegExp(r'^(\s*)(\d{1,2})([\.\)])\s');
  static final _scheduleRe = RegExp(r'ድምስተው');
  static final _sectionHeadingRe = RegExp(r'^(?:ሺዋን|ሥቱር|ራሕመት)(?:\s.+)?$');
  static final _ordinalRe = RegExp(r'^(ሰልፋ|ሊጘር|ሲዀር|ሰጀር|አⶖኰር) ');
  // Response word at end of a litany invocation line.
  static final _responseRe =
      RegExp(r'(ረሓሚና|ራሓሚና|ሰኸንቲና|ሺዊልና|ዋሲና|ሸኑሪና|መሓሪና)[።፥፣]?$');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Build inline spans for a single normal text line (role/verse markers).
  List<InlineSpan> _lineSpans(String line, TextStyle base) {
    final spans = <InlineSpan>[];
    var l = line;
    final rm = _roleRe.firstMatch(l);
    if (rm != null) {
      if (rm.group(1)!.isNotEmpty) spans.add(TextSpan(text: rm.group(1)));
      spans.add(TextSpan(
          text: '${rm.group(2)}${rm.group(3)}',
          style: base.copyWith(
              color: context.palette.primarySoft,
              fontWeight: FontWeight.w700)));
      l = l.substring(rm.end);
    } else {
      final vm = _verseRe.firstMatch(l);
      if (vm != null) {
        if (vm.group(1)!.isNotEmpty) spans.add(TextSpan(text: vm.group(1)));
        spans.add(TextSpan(
            text: '${vm.group(2)}${vm.group(3)} ',
            style: base.copyWith(
                color: context.palette.goldText, fontWeight: FontWeight.w700)));
        l = l.substring(vm.end);
      }
    }
    _appendHighlighted(spans, l, base);
    return spans;
  }

  void _appendHighlighted(List<InlineSpan> spans, String text, TextStyle base) {
    final query = widget.highlightQuery.trim();
    if (query.isEmpty) {
      spans.add(TextSpan(text: text));
      return;
    }
    final lower = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    var start = 0;
    while (start < text.length) {
      final match = lower.indexOf(lowerQuery, start);
      if (match < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (match > start) {
        spans.add(TextSpan(text: text.substring(start, match)));
      }
      spans.add(TextSpan(
        text: text.substring(match, match + query.length),
        style: base.copyWith(
          backgroundColor: const Color(0x66E3C47F),
          fontWeight: FontWeight.w700,
        ),
      ));
      start = match + query.length;
    }
    if (text.isEmpty) spans.add(const TextSpan(text: ''));
  }

  List<Widget> _buildWidgets(TextStyle base) {
    final scale = widget.scale;
    final lines = widget.text.split('\n');
    final result = <Widget>[];
    // Buffer for consecutive normal lines → flushed as one RichText block.
    final buf = <InlineSpan>[];

    void flush() {
      if (buf.isNotEmpty) {
        result
            .add(RichText(text: TextSpan(style: base, children: List.of(buf))));
        buf.clear();
      }
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Short source headings become visible waypoints inside longer prayers.
      if (line.length <= 80 && _sectionHeadingRe.hasMatch(line.trim())) {
        flush();
        if (result.isNotEmpty) result.add(const SizedBox(height: 14));
        result.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: base.copyWith(
              color: context.palette.primary,
              fontWeight: FontWeight.w700,
              fontSize: 17 * scale,
              height: 1.55,
            ),
          ),
        ));
        continue;
      }

      // Schedule header (day of week for rosary mysteries)
      if (_scheduleRe.hasMatch(line)) {
        flush();
        result.add(Text(line,
            style: base.copyWith(
              color: context.palette.goldText,
              fontWeight: FontWeight.w700,
              fontSize: 16 * scale,
            )));
        continue;
      }

      // Litany response line → Row: invocation left, response right
      // A line with an explicit liturgical role marker must keep its printed
      // line shape. It is not a litany row whose response should be pushed to
      // the far edge (for example: "ዲባ፡ ረሓሚና።"). The normal path below
      // also gives the role marker its wine-red emphasis.
      final hasRoleMarker = _roleRe.hasMatch(line);
      final rm2 = hasRoleMarker ? null : _responseRe.firstMatch(line);
      if (rm2 != null) {
        flush();
        final responseWord = rm2.group(1)!;
        final firstResponseEnd =
            line.indexOf(responseWord) + responseWord.length;
        final firstPhrase = line.substring(0, firstResponseEnd).trim();
        final repeatedPhrase = line.substring(firstResponseEnd).trim();
        final isDoubled = repeatedPhrase == firstPhrase;
        final invocation = isDoubled
            ? firstPhrase
                .substring(0, firstPhrase.length - responseWord.length)
                .trimRight()
            : line.substring(0, rm2.start).trimRight();
        final response = isDoubled ? responseWord : line.substring(rm2.start);
        if (invocation.isNotEmpty) {
          result.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: Text(invocation, style: base)),
              const SizedBox(width: 20),
              Flexible(
                flex: 2,
                child: Text(
                  response,
                  textAlign: TextAlign.end,
                  style: base.copyWith(
                    color: context.palette.primarySoft,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ));
        } else {
          result.add(RichText(
              text: TextSpan(style: base, children: [
            TextSpan(text: line.substring(0, rm2.start)),
            TextSpan(
                text: response,
                style: base.copyWith(
                    color: context.palette.primarySoft,
                    fontWeight: FontWeight.w700)),
          ])));
        }
        continue;
      }

      // Mystery ordinal (ሰልፋ / ሊጘር / …) — flush buffer, add spacer, start new block
      final om = _ordinalRe.firstMatch(line);
      if (om != null) {
        flush();
        if (i > 0) result.add(const SizedBox(height: 14));
        buf.add(TextSpan(
            text: '${om.group(1)} ',
            style: base.copyWith(
                color: context.palette.primarySoft,
                fontWeight: FontWeight.w700)));
        buf.addAll(_lineSpans(line.substring(om.end), base));
        continue;
      }

      // Normal line — append to buffer (preserving multi-line flow)
      if (buf.isNotEmpty) buf.add(const TextSpan(text: '\n'));
      buf.addAll(_lineSpans(line, base));
    }

    flush();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final base = AppTheme.geezSerif(
      size: 18 * widget.scale,
      color: context.palette.ink,
    ).copyWith(height: 1.95);
    return SelectableRegion(
      focusNode: _focusNode,
      selectionControls: materialTextSelectionControls,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildWidgets(base),
      ),
    );
  }
}

/// A tappable list row used throughout the app.
class ItemRow extends StatelessWidget {
  final String leading; // number or glyph
  final String title;
  final String? sub;
  final bool fav;
  final VoidCallback onTap;
  final List<InlineSpan>? titleSpans; // for search highlight
  const ItemRow({
    super.key,
    required this.leading,
    required this.title,
    this.sub,
    this.fav = false,
    required this.onTap,
    this.titleSpans,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.palette.outline, width: 1.5),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.primaryDark,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(leading,
                    style: AppTheme.geezSerif(
                        size: 15,
                        w: FontWeight.w700,
                        color: const Color(0xFFF7ECD6))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSpans != null
                        ? RichText(
                            text: TextSpan(
                                style: AppTheme.geezSerif(
                                    size: 16.5,
                                    w: FontWeight.w700,
                                    color: context.palette.ink),
                                children: titleSpans),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(title,
                            style: AppTheme.geezSerif(
                                size: 16.5, w: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                    if (sub != null && sub!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(sub!,
                            style: AppTheme.geezSans(
                                size: 12.5,
                                w: FontWeight.w400,
                                color: context.palette.inkMuted),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              if (fav)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.star_rounded,
                      color: context.palette.goldText, size: 20),
                ),
              const SizedBox(width: 3),
              Icon(Icons.chevron_right_rounded,
                  color: context.palette.primarySoft, size: 21),
            ]),
          ),
        ),
      ),
    );
  }
}

/// A compact feature banner used at the top of the main library collections.
class CollectionHero extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final String? badge;

  const CollectionHero({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.palette.primaryDark, const Color(0xFF321015)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x287A1F2B),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -22,
            top: -30,
            child: Icon(icon, size: 150, color: const Color(0x10FFFFFF)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(21, 20, 21, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0x1FFFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x66CDA85A)),
                      ),
                      child:
                          Icon(icon, size: 23, color: const Color(0xFFF1D494)),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        eyebrow.toUpperCase(),
                        style: AppTheme.latin(
                          size: 12,
                          w: FontWeight.w700,
                          color: const Color(0xFFE9CB8D),
                          style: FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: AppTheme.geezSerif(
                    size: 26,
                    w: FontWeight.w700,
                    color: const Color(0xFFF9F0DE),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTheme.latin(
                    size: 18,
                    w: FontWeight.w600,
                    color: const Color(0xFFE9D9BA),
                    style: FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  description,
                  style: AppTheme.latin(
                    size: 15,
                    color: const Color(0xFFE9D9BA),
                    style: FontStyle.normal,
                  ).copyWith(height: 1.35),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 13),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: const Color(0x33CDA85A)),
                    ),
                    child: Text(
                      badge!,
                      style: AppTheme.latin(
                        size: 11.5,
                        w: FontWeight.w700,
                        color: const Color(0xFFF8EEDB),
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

/// A visually grouped prayer collection with a distinct identity and compact
/// rows. Used for the ordinary prayer groups in the Prayers tab.
class PrayerGroupPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Item> items;
  final bool Function(String itemId) isFavorite;
  final ValueChanged<Item> onOpen;

  const PrayerGroupPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.items,
    required this.isFavorite,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.outline, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x123C2614),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [context.palette.surfaceMuted, context.palette.card],
              ),
              border:
                  Border(bottom: BorderSide(color: context.palette.outline)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.palette.primaryDark,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, size: 23, color: const Color(0xFFF5DFAC)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.geezSerif(
                          size: 19,
                          w: FontWeight.w700,
                          color: context.palette.primary,
                        ),
                      ),
                      Text(
                        '$subtitle · ${items.length} ${items.length == 1 ? 'section' : 'sections'}',
                        style: AppTheme.latin(
                          size: 13.5,
                          w: FontWeight.w600,
                          style: FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                description,
                style: AppTheme.latin(size: 14.5, style: FontStyle.normal),
              ),
            ),
          ),
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.only(left: 68),
                child: Divider(height: 1, color: context.palette.outline),
              ),
            _PrayerPanelRow(
              item: items[index],
              icon: icon,
              favorite: isFavorite(items[index].id),
              onTap: () => onOpen(items[index]),
            ),
          ],
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}

class _PrayerPanelRow extends StatelessWidget {
  final Item item;
  final IconData icon;
  final bool favorite;
  final VoidCallback onTap;

  const _PrayerPanelRow({
    required this.item,
    required this.icon,
    required this.favorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${item.title}. ${item.note.isNotEmpty ? item.note : item.sub}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: context.palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child:
                      Icon(icon, size: 19, color: context.palette.primarySoft),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            AppTheme.geezSerif(size: 16.5, w: FontWeight.w700),
                      ),
                      if (item.sub.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            item.sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.latin(
                                size: 13.5, style: FontStyle.normal),
                          ),
                        ),
                    ],
                  ),
                ),
                if (favorite)
                  Icon(Icons.star_rounded,
                      color: context.palette.goldText, size: 19),
                const SizedBox(width: 3),
                Icon(Icons.chevron_right_rounded,
                    color: context.palette.primarySoft),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Square-ish home / quiz card.
class TileCard extends StatelessWidget {
  final String kicker;
  final String title;
  final String? desc;
  final VoidCallback onTap;
  final IconData? icon;
  const TileCard({
    super.key,
    required this.kicker,
    required this.title,
    this.desc,
    required this.onTap,
    this.icon,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.palette.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.palette.outline, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(kicker.toUpperCase(),
                        style: AppTheme.latin(
                            size: 12.5,
                            w: FontWeight.w700,
                            color: context.palette.primarySoft,
                            style: FontStyle.normal)),
                  ),
                  if (icon != null)
                    Container(
                      width: 33,
                      height: 33,
                      decoration: BoxDecoration(
                        color: context.palette.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(icon, size: 18, color: context.palette.primary),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(title,
                  style: AppTheme.geezSerif(size: 17, w: FontWeight.w700)),
              if (desc != null) ...[
                const SizedBox(height: 5),
                Text(desc!,
                    style: AppTheme.geezSans(
                        size: 12.5,
                        w: FontWeight.w400,
                        color: context.palette.inkMuted),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// English context note panel shown in the reader.
class NotePanel extends StatelessWidget {
  final String note;
  const NotePanel(this.note, {super.key});
  @override
  Widget build(BuildContext context) {
    if (note.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.goldDecorative, width: 1.2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 1, right: 9),
          child: Icon(Icons.translate_rounded,
              size: 17, color: context.palette.primarySoft),
        ),
        Expanded(
          child: Text(note,
              style: AppTheme.latin(
                  size: 15.5,
                  w: FontWeight.w500,
                  color: context.palette.inkMuted)),
        ),
      ]),
    );
  }
}

/// Gospel-song layout preserving the source order of refrains and verses.
class HymnBody extends StatefulWidget {
  final Item item;
  final double scale;
  const HymnBody(this.item, {super.key, this.scale = 1.0});

  @override
  State<HymnBody> createState() => _HymnBodyState();
}

class _HymnBodyState extends State<HymnBody> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final s = widget.scale;
    final base = AppTheme.geezSerif(
      size: 17 * s,
      color: context.palette.ink,
    ).copyWith(height: 1.9);
    final sectionWidgets = <Widget>[];
    var verseNumber = 0;
    for (final section in item.hymnSections) {
      if (section.isRefrain) {
        sectionWidgets.add(_refrainBlock(section.text, base, s));
      } else {
        verseNumber += 1;
        sectionWidgets.add(_verseBlock(verseNumber, section.text, base, s));
      }
    }

    return SelectableRegion(
      focusNode: _focusNode,
      selectionControls: materialTextSelectionControls,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.hymnIntro.isNotEmpty) _introBlock(item.hymnIntro, base, s),
          if (sectionWidgets.isNotEmpty)
            ...sectionWidgets
          else if (item.verses.isNotEmpty) ...[
            if (item.refrain.isNotEmpty) _refrainBlock(item.refrain, base, s),
            for (var i = 0; i < item.verses.length; i++) ...[
              _verseBlock(i + 1, item.verses[i], base, s),
            ]
          ] else
            Text(item.body, style: base),
          if (item.hymnCredits.isNotEmpty)
            _creditsBlock(item.hymnCredits, base, s),
        ],
      ),
    );
  }

  Widget _introBlock(String intro, TextStyle base, double s) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 17, color: context.palette.primary),
              const SizedBox(width: 7),
              Text(
                'Scripture introduction',
                style: AppTheme.latin(
                  size: 11.5 * s,
                  w: FontWeight.w700,
                  color: context.palette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            intro,
            style: base.copyWith(
              fontStyle: FontStyle.italic,
              color: context.palette.inkMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _creditsBlock(List<String> credits, TextStyle base, double s) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attribution_outlined,
                  size: 17, color: context.palette.primary),
              const SizedBox(width: 7),
              Text(
                'Credits',
                style: AppTheme.latin(
                  size: 11.5 * s,
                  w: FontWeight.w700,
                  color: context.palette.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          for (final credit in credits)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_creditRole(credit) case final role?) ...[
                    Text(
                      role.toUpperCase(),
                      style: AppTheme.latin(
                        size: 10.5 * s,
                        w: FontWeight.w700,
                        color: context.palette.primarySoft,
                      ),
                    ),
                    const SizedBox(height: 1),
                  ],
                  Text(
                    credit,
                    style: base.copyWith(
                      fontSize: 15 * s,
                      color: context.palette.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String? _creditRole(String credit) {
    final value = credit.trimLeft();
    if (value.startsWith('ላሕማዲ ሒንዲ') || value.startsWith('ላሕማ ዲ ሒንዲ')) {
      return 'Lyrics & melody';
    }
    if (value.startsWith('ላሕማ')) return 'Lyrics';
    if (value.startsWith('ሒን')) return 'Melody';
    return null;
  }

  Widget _refrainBlock(String refrain, TextStyle base, double s) {
    final parts = refrain
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.goldDecorative, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 5,
            decoration: BoxDecoration(
              color: context.palette.primaryDark,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('ድም',
                        style: AppTheme.geezSerif(
                            size: 12 * s,
                            w: FontWeight.w700,
                            color: context.palette.primary)),
                    const SizedBox(width: 6),
                    Text('· Refrain',
                        style: AppTheme.latin(
                            size: 11 * s,
                            w: FontWeight.w600,
                            color: context.palette.primarySoft)),
                  ]),
                  const SizedBox(height: 6),
                  for (var index = 0; index < parts.length; index++) ...[
                    if (index > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: Divider(
                          key: ValueKey('refrain-part-divider-${index - 1}'),
                          height: 1,
                          thickness: 1,
                          color: context.palette.goldDecorative
                              .withValues(alpha: 0.55),
                        ),
                      ),
                    Text(
                      parts[index],
                      style: base.copyWith(
                        fontStyle: FontStyle.italic,
                        color: context.palette.primary.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _verseBlock(int num, String verse, TextStyle base, double s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 30,
          child: Text('$num.',
              style: AppTheme.latin(
                  size: 13 * s,
                  w: FontWeight.w700,
                  color: context.palette.goldText)),
        ),
        Expanded(child: Text(verse, style: base)),
      ]),
    );
  }
}
