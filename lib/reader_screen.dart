import 'package:flutter/material.dart';
import 'data.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';

class ReaderScreen extends StatefulWidget {
  final AppData data;
  final AppStore store;
  final String itemId;
  const ReaderScreen({
    super.key,
    required this.data,
    required this.store,
    required this.itemId,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Item item;

  @override
  void initState() {
    super.initState();
    item = widget.data.byId(widget.itemId)!;
  }

  void _open(Item it) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderScreen(
          data: widget.data, store: widget.store, itemId: it.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final s = widget.store;
        final fav = s.isFav(item.id);
        final scale = s.scale;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.wine,
            foregroundColor: const Color(0xFFF7ECD6),
            elevation: 2,
            title: Text(item.groupEn,
                style: AppTheme.latin(
                    size: 16,
                    w: FontWeight.w600,
                    color: const Color(0xFFF7ECD6))),
            actions: [
              IconButton(
                tooltip: 'Smaller text',
                onPressed: () => s.bumpScale(-0.1),
                icon: const Icon(Icons.text_decrease_rounded),
              ),
              IconButton(
                tooltip: 'Larger text',
                onPressed: () => s.bumpScale(0.1),
                icon: const Icon(Icons.text_increase_rounded),
              ),
              IconButton(
                tooltip: 'Favorite',
                onPressed: () {
                  final on = s.toggleFav(item.id);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.wineDeep,
                      duration: const Duration(milliseconds: 1300),
                      content: Text(on ? 'ናድካ ሓፍዘዅ ★' : 'ናድካ ኡረዅ',
                          style: AppTheme.geezSerif(
                              size: 15, color: const Color(0xFFF7ECD6))),
                    ));
                },
                icon: Icon(
                    fav ? Icons.star_rounded : Icons.star_border_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 60),
            children: [
              _readerCard(scale, s.showNotes),
              if (item.kind != 'catechism') _related(),
            ],
          ),
        );
      },
    );
  }

  Widget _readerCard(double scale, bool showNotes) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x1F3C2614), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title,
              style: AppTheme.geezSerif(
                  size: 25 * scale, w: FontWeight.w700, color: AppColors.wine)),
          if (item.sub.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3, bottom: 4),
              child: Text(item.sub,
                  style: AppTheme.latin(size: 16 * scale)),
            ),
          const SizedBox(height: 10),
          if (showNotes) NotePanel(item.note),
          if (showNotes &&
              item.translation.trim().isNotEmpty) ...[
            _translationBlock(scale),
          ],
          if (item.kind == 'catechism')
            _catechismBody(scale, showNotes)
          else if (item.kind == 'rubric')
            _rubricBody(scale)
          else if (item.kind == 'hymn')
            HymnBody(item, scale: scale)
          else
            PrayerText(item.body, scale: scale),
        ],
      ),
    );
  }

  Widget _translationBlock(double scale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.goldSoft, width: 1),
      ),
      child: Text(item.translation,
          style: AppTheme.latin(
              size: 16 * scale,
              w: FontWeight.w500,
              style: FontStyle.normal,
              color: AppColors.inkSoft)),
    );
  }

  Widget _rubricBody(double scale) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EAD2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.goldSoft, width: 1),
      ),
      child: Text(
        item.body,
        style: AppTheme.geezSerif(size: 17 * scale, color: AppColors.inkSoft)
            .copyWith(height: 1.9),
      ),
    );
  }

  Widget _catechismBody(double scale, bool showNotes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.body.trim().isNotEmpty) ...[
          PrayerText(item.body, scale: scale),
          const SizedBox(height: 12),
        ],
        for (final p in item.qa) _qaPair(p, scale, showNotes),
      ],
    );
  }

  Widget _qaPair(QA p, double scale, bool showNotes) {
    final hasAnswer = p.a.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(left: 14),
      decoration: const BoxDecoration(
        border: Border(
            left: BorderSide(color: AppColors.goldSoft, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.q,
              style: AppTheme.geezSerif(
                  size: 17 * scale,
                  w: FontWeight.w700,
                  color: AppColors.wine)),
          if (showNotes && p.qEn.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(p.qEn, style: AppTheme.latin(size: 14 * scale)),
            ),
          if (hasAnswer) ...[
            const SizedBox(height: 5),
            RichText(
              text: TextSpan(children: [
                TextSpan(
                    text: '✻ ',
                    style: AppTheme.geezSerif(
                        size: 14 * scale, color: AppColors.wineSoft)),
                TextSpan(
                    text: p.a,
                    style: AppTheme.geezSerif(size: 16.5 * scale)
                        .copyWith(height: 1.8)),
              ]),
            ),
            if (showNotes && p.aEn.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(p.aEn,
                    style: AppTheme.latin(
                        size: 14 * scale, style: FontStyle.normal)),
              ),
          ],
        ],
      ),
    );
  }

  /// The item immediately after this one within the same group, if any.
  /// Mystery sections all jump directly to Hail Holy Queen — they are
  /// prayed individually, not sequenced through one after another.
  Item? get _nextInGroup {
    const mysteryIds = {
      'p_rosary_joyful', 'p_rosary_sorrowful',
      'p_rosary_luminous', 'p_rosary_glorious',
    };
    if (mysteryIds.contains(item.id)) {
      return widget.data.byId('p_hail_holy_queen');
    }
    final group = widget.data.items
        .where((x) => x.group == item.group)
        .toList();
    final idx = group.indexWhere((x) => x.id == item.id);
    if (idx == -1 || idx == group.length - 1) return null;
    return group[idx + 1];
  }

  Widget _related() {
    final next = _nextInGroup;
    final others = widget.data.items
        .where((x) => x.group == item.group && x.id != item.id &&
            (next == null || x.id != next.id))
        .take(4)
        .toList();
    if (next == null && others.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Ornament(),
        if (next != null) ...[
          Material(
            color: AppColors.wine,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _open(next),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ቀጽሊ',
                            style: AppTheme.latin(
                                size: 11,
                                w: FontWeight.w600,
                                color: const Color(0xAAF7ECD6))),
                        const SizedBox(height: 2),
                        Text(next.title,
                            style: AppTheme.geezSerif(
                                size: 16,
                                w: FontWeight.w700,
                                color: const Color(0xFFF7ECD6))),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: Color(0xCCF7ECD6)),
                ]),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (others.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text('More in this section',
                style: AppTheme.latin(size: 15)),
          ),
          for (final r in others)
            ItemRow(
              leading: r.num?.toString() ??
                  (r.kind == 'hymn' ? '♪' : r.kind == 'catechism' ? '✝' : '☩'),
              title: r.title,
              sub: r.sub,
              fav: widget.store.isFav(r.id),
              onTap: () => _open(r),
            ),
        ],
      ],
    );
  }
}
