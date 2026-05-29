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
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [
                Color(0x00D9C9A8),
                AppColors.line,
                Color(0x00D9C9A8),
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
              style: const TextStyle(color: AppColors.gold, fontSize: 14)),
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
  const PrayerText(this.text, {super.key, this.scale = 1.0});

  @override
  State<PrayerText> createState() => _PrayerTextState();
}

class _PrayerTextState extends State<PrayerText> {
  final _focusNode = FocusNode();

  static final _roleRe =
      RegExp(r'^(\s*)(መ|ዲ|ከዳ|ዲባ|ፋ|ር|ሁ|ሕ)([፡፣፥:])');
  static final _verseRe = RegExp(r'^(\s*)(\d{1,2})([\.\)])\s');
  static final _scheduleRe = RegExp(r'ድምስተው');
  static final _ordinalRe = RegExp(r'^(ሰልፋ|ሊጘር|ሲዀር|ሰጀር|አⶖኰር) ');
  // Response word at end of a litany invocation line.
  static final _responseRe =
      RegExp(r'(ረሓሚና|ሰኸንቲና|ሺዊልና|ዋሲና|ሸኑሪና|መሓሪና)[።፥፣]?$');

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
              color: AppColors.wineSoft, fontWeight: FontWeight.w700)));
      l = l.substring(rm.end);
    } else {
      final vm = _verseRe.firstMatch(l);
      if (vm != null) {
        if (vm.group(1)!.isNotEmpty) spans.add(TextSpan(text: vm.group(1)));
        spans.add(TextSpan(
            text: '${vm.group(2)}${vm.group(3)} ',
            style: base.copyWith(
                color: AppColors.gold, fontWeight: FontWeight.w700)));
        l = l.substring(vm.end);
      }
    }
    spans.add(TextSpan(text: l));
    return spans;
  }

  List<Widget> _buildWidgets(TextStyle base) {
    final scale = widget.scale;
    final lines = widget.text.split('\n');
    final result = <Widget>[];
    // Buffer for consecutive normal lines → flushed as one RichText block.
    final buf = <InlineSpan>[];

    void flush() {
      if (buf.isNotEmpty) {
        result.add(RichText(
            text: TextSpan(style: base, children: List.of(buf))));
        buf.clear();
      }
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Schedule header (day of week for rosary mysteries)
      if (_scheduleRe.hasMatch(line)) {
        flush();
        result.add(Text(line,
            style: base.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
              fontSize: 16 * scale,
            )));
        continue;
      }

      // Litany response line → Row: invocation left, response right
      final rm2 = _responseRe.firstMatch(line);
      if (rm2 != null) {
        flush();
        final response = line.substring(rm2.start);
        final invocation = line.substring(0, rm2.start).trimRight();
        // Doubled lines (e.g. "ዎ ይና አደራ ረሓሚና ዎ ይና አደራ ረሓሚና") keep inline bold.
        final isDoubled = invocation.contains(rm2.group(1)!);
        if (!isDoubled && invocation.isNotEmpty) {
          result.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(invocation, style: base)),
              const SizedBox(width: 20),
              Text(response,
                  style: base.copyWith(
                      color: AppColors.wineSoft,
                      fontWeight: FontWeight.w700)),
            ],
          ));
        } else {
          result.add(RichText(
              text: TextSpan(style: base, children: [
            TextSpan(text: line.substring(0, rm2.start)),
            TextSpan(
                text: response,
                style: base.copyWith(
                    color: AppColors.wineSoft, fontWeight: FontWeight.w700)),
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
                color: AppColors.wineSoft, fontWeight: FontWeight.w700)));
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
    final base =
        AppTheme.geezSerif(size: 18 * widget.scale).copyWith(height: 1.95);
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
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.line, width: 1.5),
            ),
            child: Row(children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.wine,
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
                                    size: 16.5, w: FontWeight.w700),
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
                                color: AppColors.inkSoft),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                  ],
                ),
              ),
              if (fav)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.star_rounded,
                      color: AppColors.gold, size: 20),
                ),
            ]),
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
  const TileCard({
    super.key,
    required this.kicker,
    required this.title,
    this.desc,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(kicker.toUpperCase(),
                  style: AppTheme.latin(
                      size: 12.5,
                      w: FontWeight.w600,
                      color: AppColors.wineSoft)),
              const SizedBox(height: 4),
              Text(title,
                  style: AppTheme.geezSerif(size: 17, w: FontWeight.w700)),
              if (desc != null) ...[
                const SizedBox(height: 5),
                Text(desc!,
                    style: AppTheme.geezSans(
                        size: 12.5,
                        w: FontWeight.w400,
                        color: AppColors.inkSoft),
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
        color: const Color(0xFFF6EAD2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldSoft, width: 1.2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
          padding: EdgeInsets.only(top: 1, right: 9),
          child: Icon(Icons.translate_rounded,
              size: 17, color: AppColors.wineSoft),
        ),
        Expanded(
          child: Text(note,
              style: AppTheme.latin(
                  size: 15.5, w: FontWeight.w500, color: AppColors.inkSoft)),
        ),
      ]),
    );
  }
}

/// Gospel-song layout: optional refrain block, numbered verses.
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
    final base = AppTheme.geezSerif(size: 17 * s).copyWith(height: 1.9);

    return SelectableRegion(
      focusNode: _focusNode,
      selectionControls: materialTextSelectionControls,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.needsReview) _reviewBadge(s),
          if (item.refrain.isNotEmpty) ...[
            _refrainBlock(item.refrain, base, s),
          ],
          if (item.verses.isNotEmpty)
            for (var i = 0; i < item.verses.length; i++) ...[
              _verseBlock(i + 1, item.verses[i], base, s),
            ]
          else
            Text(item.body, style: base),
        ],
      ),
    );
  }

  Widget _reviewBadge(double s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFCA2C), width: 1),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded,
            size: 14, color: Color(0xFFB07D00)),
        const SizedBox(width: 7),
        Text('Verse splits need review',
            style: AppTheme.latin(
                size: 12.5 * s, color: const Color(0xFF7A5500))),
      ]),
    );
  }

  Widget _refrainBlock(String refrain, TextStyle base, double s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8D0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldSoft, width: 1),
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            width: 5,
            decoration: const BoxDecoration(
              color: AppColors.wine,
              borderRadius: BorderRadius.only(
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
                            color: AppColors.wine)),
                    const SizedBox(width: 6),
                    Text('· Refrain',
                        style: AppTheme.latin(
                            size: 11 * s,
                            w: FontWeight.w600,
                            color: AppColors.wineSoft)),
                  ]),
                  const SizedBox(height: 6),
                  Text(refrain,
                      style: base.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.wine.withValues(alpha: 0.85))),
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
                  size: 13 * s, w: FontWeight.w700, color: AppColors.gold)),
        ),
        Expanded(child: Text(verse, style: base)),
      ]),
    );
  }
}
