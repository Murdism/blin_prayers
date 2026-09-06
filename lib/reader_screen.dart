import 'dart:async';

import 'package:flutter/material.dart';
import 'data.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';
import 'divine_mercy_widgets.dart';
import 'way_of_cross_widgets.dart';

class ReaderScreen extends StatefulWidget {
  final AppData data;
  final AppStore store;
  final String itemId;
  final int? initialMercyStage;
  final String? initialQuery;
  final bool resumePosition;
  const ReaderScreen({
    super.key,
    required this.data,
    required this.store,
    required this.itemId,
    this.initialMercyStage,
    this.initialQuery,
    this.resumePosition = false,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Item item;
  late int _mercyStage;
  late final ScrollController _scrollController;
  Timer? _saveTimer;
  late String _highlightQuery;

  @override
  void initState() {
    super.initState();
    item = widget.data.byId(widget.itemId)!;
    _mercyStage = (widget.initialMercyStage ??
            (widget.resumePosition ? widget.store.mercyStage : 0))
        .clamp(0, divineMercyStages.length - 1)
        .toInt();
    _highlightQuery = widget.initialQuery?.trim() ?? '';
    final initialOffset =
        widget.resumePosition ? widget.store.readingOffset(item.id) : 0.0;
    _scrollController = ScrollController(
      initialScrollOffset: initialOffset,
    )..addListener(_schedulePositionSave);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.store.recordOpened(item.id);
    });
    if (_highlightQuery.isNotEmpty && initialOffset == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSearchHit());
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (_scrollController.hasClients) {
      widget.store.setReadingOffset(item.id, _scrollController.offset);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _schedulePositionSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 450), () {
      if (_scrollController.hasClients) {
        widget.store.setReadingOffset(item.id, _scrollController.offset);
      }
    });
  }

  void _scrollToSearchHit() {
    if (!_scrollController.hasClients || _highlightQuery.isEmpty) return;
    final query = _highlightQuery.toLowerCase();
    final position = item.body.toLowerCase().indexOf(query);
    var ratio = 0.0;
    if (position >= 0 && item.body.isNotEmpty) {
      ratio = position / item.body.length;
    } else if (item.qa.isNotEmpty) {
      final qaIndex = item.qa.indexWhere(
        (pair) => '${pair.q} ${pair.a}'.toLowerCase().contains(query),
      );
      if (qaIndex < 0) return;
      ratio = qaIndex / item.qa.length;
    } else {
      return;
    }
    final target = (_scrollController.position.maxScrollExtent * ratio)
        .clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _open(Item it) {
    if (item.group == it.group) {
      if (_scrollController.hasClients) {
        widget.store.setReadingOffset(item.id, _scrollController.offset);
      }
      setState(() {
        item = it;
        _highlightQuery = '';
      });
      widget.store.recordOpened(it.id);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      });
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) =>
          ReaderScreen(data: widget.data, store: widget.store, itemId: it.id),
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
            backgroundColor: context.palette.primaryDark,
            foregroundColor: const Color(0xFFF7ECD6),
            elevation: 2,
            title: Text(item.groupEn,
                style: AppTheme.latin(
                    size: 16,
                    w: FontWeight.w600,
                    color: const Color(0xFFF7ECD6))),
            actions: [
              PopupMenuButton<String>(
                tooltip: 'Reading options',
                icon: const Icon(Icons.tune_rounded),
                onSelected: (value) {
                  final sizes = {
                    'small': .9,
                    'standard': 1.0,
                    'large': 1.25,
                    'extra': 1.55,
                  };
                  if (sizes.containsKey(value)) {
                    s.setScale(sizes[value]!);
                  } else if (value == 'restart') {
                    s.resetReading(item.id);
                    if (item.group == 'mercy') _setMercyStage(0);
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      );
                    }
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'small',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.text_decrease_rounded),
                      title: Text('Small text'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'standard',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.text_fields_rounded),
                      title: Text('Standard text'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'large',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.text_increase_rounded),
                      title: Text('Large text'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'extra',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.format_size_rounded),
                      title: Text('Extra-large text'),
                    ),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'restart',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.restart_alt_rounded),
                      title: Text('Start this prayer again'),
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Favorite',
                onPressed: () {
                  final on = s.toggleFav(item.id);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: context.palette.primaryDark,
                      duration: const Duration(milliseconds: 1300),
                      content: Text(on ? 'ናድካ ሓፍዘዅ ★' : 'ናድካ ኡረዅ',
                          style: AppTheme.geezSerif(
                              size: 15, color: const Color(0xFFF7ECD6))),
                    ));
                },
                icon:
                    Icon(fav ? Icons.star_rounded : Icons.star_border_rounded),
              ),
            ],
          ),
          body: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 60),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: item.group == 'way'
                      ? _wayReader(scale, s.showNotes)
                      : item.group == 'mercy'
                          ? DivineMercyReader(
                              item: item,
                              stageIndex: _mercyStage,
                              scale: scale,
                              showNotes: s.showNotes,
                              onStageChanged: _setMercyStage,
                              onCompleted: _markCurrentComplete,
                              onImageTap: _openVisual,
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _readerCard(scale, s.showNotes),
                                if (item.kind != 'catechism') _related(),
                              ],
                            ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _setMercyStage(int stage) {
    setState(() => _mercyStage = stage);
    widget.store.setMercyStage(stage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _markCurrentComplete() {
    widget.store.markCompleted(item.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('ተመሙዅ · Prayer completed'),
        ),
      );
  }

  List<Item> get _wayItems => widget.data.itemsInGroup('way');

  Widget _wayReader(double scale, bool showNotes) {
    final station = wayStationNumber(item);
    final sequenceIndex =
        _wayItems.indexWhere((candidate) => candidate.id == item.id);
    final visual = item.visuals.firstOrNull;
    final sections = _waySections(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _wayProgressCard(station, sequenceIndex),
        const SizedBox(height: 14),
        if (visual != null) ...[
          _wayHeroImage(visual, station),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: context.palette.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.palette.outline, width: 1.25),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (station != null)
                Text(
                  'STATION $station OF 14',
                  style: AppTheme.latin(
                    size: 12.5,
                    w: FontWeight.w700,
                    color: context.palette.goldText,
                    style: FontStyle.normal,
                  ),
                ),
              Text(
                item.title,
                style: AppTheme.geezSerif(
                  size: 27 * scale,
                  w: FontWeight.w700,
                  color: context.palette.primary,
                ).copyWith(height: 1.35),
              ),
              if (item.sub.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  item.sub,
                  style: AppTheme.latin(
                    size: 17 * scale,
                    w: FontWeight.w600,
                    style: FontStyle.normal,
                  ),
                ),
              ],
              if (showNotes && item.note.trim().isNotEmpty) ...[
                const SizedBox(height: 13),
                NotePanel(item.note),
              ],
              if (showNotes && item.translation.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _translationBlock(scale),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var index = 0; index < sections.length; index++) ...[
          _wayPrayerCard(sections[index], scale, index),
          if (index != sections.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 20),
        _wayNavigation(),
      ],
    );
  }

  Widget _wayProgressCard(int? station, int sequenceIndex) {
    final progress =
        sequenceIndex < 0 ? 0.0 : (sequenceIndex + 1) / _wayItems.length;
    final label = station != null
        ? 'Station $station of 14'
        : item.id == 'p_way_conclusion'
            ? 'Conclusion'
            : 'Preparation';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.goldDecorative),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.primaryDark,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  station?.toString() ??
                      (item.id == 'p_way_conclusion' ? '✓' : '✝'),
                  style: AppTheme.latin(
                    size: 16,
                    w: FontWeight.w700,
                    color: const Color(0xFFF9EFD9),
                    style: FontStyle.normal,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTheme.latin(
                        size: 15.5,
                        w: FontWeight.w700,
                        color: context.palette.primary,
                        style: FontStyle.normal,
                      ),
                    ),
                    Text(
                      'Way of the Cross · ${sequenceIndex + 1} of ${_wayItems.length} sections',
                      style:
                          AppTheme.latin(size: 12.5, style: FontStyle.normal),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: context.palette.outline,
              color: context.palette.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _wayHeroImage(ContentVisual visual, int? station) {
    final label = visual.alt.trim().isNotEmpty ? visual.alt : item.title;

    return Semantics(
      button: true,
      image: true,
      label: '$label. Open full-screen image.',
      child: Material(
        color: const Color(0xFF2B1B18),
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openVisual(visual, label),
          child: Stack(
            alignment: Alignment.bottomLeft,
            children: [
              ConstrainedBox(
                constraints:
                    const BoxConstraints(minHeight: 300, maxHeight: 560),
                child: SizedBox(
                  width: double.infinity,
                  child: Image.asset(
                    visual.asset,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    errorBuilder: (_, __, ___) => const SizedBox(
                      height: 300,
                      child: Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: Color(0xFFE7CA8B), size: 34),
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xB0000000)],
                        stops: [0.62, 1],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Row(
                  children: [
                    if (station != null)
                      Container(
                        width: 44,
                        height: 44,
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
                            size: 20,
                            w: FontWeight.w700,
                            color: Colors.white,
                            style: FontStyle.normal,
                          ),
                        ),
                      ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xB0000000),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.zoom_out_map_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            'View image',
                            style: AppTheme.latin(
                              size: 12.5,
                              w: FontWeight.w700,
                              color: Colors.white,
                              style: FontStyle.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _wayPrayerCard(_WaySection section, double scale, int index) {
    final isScripture = section.kind == _WaySectionKind.scripture;
    final color = isScripture
        ? context.palette.surfaceMuted
        : index.isEven
            ? context.palette.card
            : context.palette.surface;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isScripture
              ? context.palette.goldDecorative
              : context.palette.outline,
          width: isScripture ? 1.5 : 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x123C2614),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(section.icon,
                    size: 19, color: context.palette.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.label.toUpperCase(),
                  style: AppTheme.latin(
                    size: 12,
                    w: FontWeight.w700,
                    color: isScripture
                        ? context.palette.primary
                        : context.palette.goldText,
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
          PrayerText(
            section.text,
            scale: scale,
            highlightQuery: _highlightQuery,
          ),
        ],
      ),
    );
  }

  Widget _wayNavigation() {
    final current =
        _wayItems.indexWhere((candidate) => candidate.id == item.id);
    final previous = current > 0 ? _wayItems[current - 1] : null;
    final next = current >= 0 && current < _wayItems.length - 1
        ? _wayItems[current + 1]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Ornament(glyph: '✝'),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: previous == null ? null : () => _open(previous),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.palette.primary,
                  side: BorderSide(color: context.palette.primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 19),
                label: const Text('ወንተሪ'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Choose a station',
              onPressed: _showWayStationPicker,
              icon: const Icon(Icons.apps_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed:
                    next == null ? _markCurrentComplete : () => _open(next),
                style: FilledButton.styleFrom(
                  backgroundColor: context.palette.primaryDark,
                  foregroundColor: const Color(0xFFF9EFD9),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                label: Text(next == null ? 'ተመሙዅ' : 'ደኵሲ'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showWayStationPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.82,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: context.palette.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ፊዅሰን መስቀሉ',
                            style: AppTheme.geezSerif(
                              size: 23,
                              w: FontWeight.w700,
                              color: context.palette.primary,
                            ),
                          ),
                          Text(
                            'Choose a section',
                            style: AppTheme.latin(
                                size: 14.5, style: FontStyle.normal),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.palette.outline),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  itemCount: _wayItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 7),
                  itemBuilder: (context, index) {
                    final candidate = _wayItems[index];
                    final station = wayStationNumber(candidate);
                    final selected = candidate.id == item.id;
                    return Material(
                      color: selected
                          ? context.palette.surfaceMuted
                          : context.palette.card,
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: selected
                                ? context.palette.goldText
                                : context.palette.outline,
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: selected
                              ? context.palette.primaryDark
                              : context.palette.surfaceMuted,
                          foregroundColor: selected
                              ? const Color(0xFFF9EFD9)
                              : context.palette.ink,
                          child: Text(
                            station?.toString() ??
                                (candidate.id == 'p_way_conclusion'
                                    ? '✓'
                                    : '✝'),
                          ),
                        ),
                        title: Text(
                          candidate.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.geezSerif(
                            size: 16,
                            w: FontWeight.w700,
                            color: context.palette.primary,
                          ),
                        ),
                        subtitle: Text(
                          candidate.sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.latin(
                              size: 13.5, style: FontStyle.normal),
                        ),
                        trailing: selected
                            ? Icon(Icons.check_circle_rounded,
                                color: context.palette.primary)
                            : const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _open(candidate);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_WaySection> _waySections(Item source) {
    final body = source.body.trim();
    final station = wayStationNumber(source);

    if (station != null) {
      var prayerBody = body;
      String? scripture;
      final scriptureMatch = _scriptureHeading.firstMatch(prayerBody);
      if (scriptureMatch != null) {
        scripture = prayerBody.substring(scriptureMatch.start).trim();
        prayerBody = prayerBody.substring(0, scriptureMatch.start).trim();
      }

      String? introduction;
      final prayerHeading =
          RegExp(r'\n\s*\nሺዋን(?:\s*\n)').firstMatch(prayerBody);
      if (prayerHeading != null) {
        introduction = prayerBody.substring(0, prayerHeading.start).trim();
        prayerBody = prayerBody.substring(prayerHeading.end).trim();
      }

      String? sharedPrayers;
      final sharedStart = prayerBody.indexOf('\nይና እኽር ሰሚል');
      if (sharedStart >= 0) {
        sharedPrayers = prayerBody.substring(sharedStart + 1).trim();
        prayerBody = prayerBody.substring(0, sharedStart).trim();
      }

      String? response;
      if (sharedPrayers != null) {
        final responseStart = sharedPrayers.indexOf('\nለመስቀልከ');
        if (responseStart >= 0) {
          response = sharedPrayers.substring(responseStart + 1).trim();
          sharedPrayers = sharedPrayers.substring(0, responseStart).trim();
        }
      }

      return [
        if (introduction?.isNotEmpty == true)
          _WaySection(
            'At the station',
            introduction!,
            Icons.place_outlined,
            _WaySectionKind.prayer,
          ),
        if (prayerBody.isNotEmpty)
          _WaySection(
            'Station prayer',
            prayerBody,
            Icons.self_improvement_rounded,
            _WaySectionKind.prayer,
          ),
        if (sharedPrayers?.isNotEmpty == true)
          _WaySection(
            'Shared prayers',
            sharedPrayers!,
            Icons.groups_rounded,
            _WaySectionKind.prayer,
          ),
        if (response?.isNotEmpty == true)
          _WaySection(
            'Response and invocation',
            response!,
            Icons.add_rounded,
            _WaySectionKind.prayer,
          ),
        if (scripture?.isNotEmpty == true)
          _WaySection(
            'Scripture reading',
            scripture!,
            Icons.menu_book_rounded,
            _WaySectionKind.scripture,
          ),
      ];
    }

    if (source.id == 'p_way_conclusion') {
      final scriptureMatch = _scriptureHeading.firstMatch(body);
      if (scriptureMatch != null) {
        final opening = body.substring(0, scriptureMatch.start).trim();
        var remainder = body.substring(scriptureMatch.start).trim();
        String? conclusion;
        final conclusionStart = remainder.indexOf('\nሺዋን\n');
        if (conclusionStart >= 0) {
          conclusion = remainder.substring(conclusionStart + 1).trim();
          remainder = remainder.substring(0, conclusionStart).trim();
        }
        return [
          if (opening.isNotEmpty)
            _WaySection('Opening prayer', opening,
                Icons.self_improvement_rounded, _WaySectionKind.prayer),
          if (remainder.isNotEmpty)
            _WaySection('Scripture reading', remainder, Icons.menu_book_rounded,
                _WaySectionKind.scripture),
          if (conclusion?.isNotEmpty == true)
            _WaySection('Concluding prayer', conclusion!,
                Icons.wb_sunny_outlined, _WaySectionKind.prayer),
        ];
      }
    }

    final scriptureMatch = _scriptureHeading.firstMatch(body);
    if (scriptureMatch != null) {
      return [
        _WaySection(
          source.id == 'p_wayofcross' ? 'Preparation prayers' : 'Prayer',
          body.substring(0, scriptureMatch.start).trim(),
          Icons.self_improvement_rounded,
          _WaySectionKind.prayer,
        ),
        _WaySection(
          'Scripture reading',
          body.substring(scriptureMatch.start).trim(),
          Icons.menu_book_rounded,
          _WaySectionKind.scripture,
        ),
      ];
    }

    return [
      _WaySection('Prayer', body, Icons.self_improvement_rounded,
          _WaySectionKind.prayer),
    ];
  }

  static final _scriptureHeading = RegExp(
    r'^(?:ሉቃስር|ጳውሎስር|ማቴዎስር|ማርቆስር|ዮሓንስር).+$',
    multiLine: true,
  );

  Widget _readerCard(double scale, bool showNotes) {
    final prayerParts =
        item.kind == 'prayer' ? _prayerParts(item) : const <_ReaderPart>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _readerHeader(scale),
        for (final visual in item.visuals) ...[
          const SizedBox(height: 14),
          _contentVisual(visual, scale),
        ],
        if (showNotes && item.note.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          NotePanel(item.note),
        ],
        if (showNotes && item.translation.trim().isNotEmpty)
          _translationBlock(scale),
        const SizedBox(height: 4),
        if (item.kind == 'catechism')
          _catechismBody(scale, showNotes)
        else if (item.kind == 'rubric')
          _contentCard(
            label: 'Guidance',
            icon: Icons.info_outline_rounded,
            child: _rubricBody(scale),
          )
        else if (item.kind == 'hymn')
          _contentCard(
            label: 'Hymn ${item.num ?? ''}',
            icon: Icons.music_note_rounded,
            child: HymnBody(item, scale: scale),
          )
        else
          for (var index = 0; index < prayerParts.length; index++) ...[
            _contentCard(
              label: prayerParts[index].label,
              icon: prayerParts[index].icon,
              emphasized: prayerParts[index].emphasized,
              child: PrayerText(
                prayerParts[index].text,
                scale: scale,
                highlightQuery: _highlightQuery,
              ),
            ),
            if (index != prayerParts.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _readerHeader(double scale) {
    final icon = _groupIcon(item);
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.palette.primaryDark, const Color(0xFF321015)],
        ),
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
            padding: const EdgeInsets.fromLTRB(20, 19, 20, 21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0x20FFFFFF),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: const Color(0x66CDA85A)),
                      ),
                      child:
                          Icon(icon, size: 21, color: const Color(0xFFF1D494)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.groupEn.toUpperCase(),
                        style: AppTheme.latin(
                          size: 12,
                          w: FontWeight.w700,
                          color: const Color(0xFFE9CB8D),
                          style: FontStyle.normal,
                        ),
                      ),
                    ),
                    if (item.kind == 'catechism')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0x1FFFFFFF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${item.qa.length} Q&A',
                          style: AppTheme.latin(
                            size: 11.5,
                            w: FontWeight.w700,
                            color: const Color(0xFFF8EEDB),
                            style: FontStyle.normal,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  item.title,
                  softWrap: true,
                  style: AppTheme.geezSerif(
                    size: 24 * scale,
                    w: FontWeight.w700,
                    color: const Color(0xFFF9F0DE),
                  ).copyWith(height: 1.35),
                ),
                if (item.sub.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.sub,
                    style: AppTheme.latin(
                      size: 17 * scale,
                      w: FontWeight.w600,
                      color: const Color(0xFFE9D9BA),
                      style: FontStyle.normal,
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

  IconData _groupIcon(Item source) {
    if (source.kind == 'hymn') return Icons.music_note_rounded;
    if (source.kind == 'catechism') return Icons.school_rounded;
    return switch (source.group) {
      'daily' => Icons.wb_sunny_outlined,
      'faith' => Icons.shield_outlined,
      'confession' => Icons.church_outlined,
      'rosary' => Icons.blur_circular_rounded,
      'mercy' => Icons.favorite_border_rounded,
      'meals' => Icons.restaurant_rounded,
      _ => Icons.auto_stories_outlined,
    };
  }

  Widget _contentCard({
    required String label,
    required IconData icon,
    required Widget child,
    bool emphasized = false,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        color: emphasized ? context.palette.surfaceMuted : context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: emphasized
              ? context.palette.goldDecorative
              : context.palette.outline,
          width: emphasized ? 1.5 : 1.1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x123C2614),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.palette.surfaceMuted,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 19, color: context.palette.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTheme.latin(
                    size: 12,
                    w: FontWeight.w700,
                    color: emphasized
                        ? context.palette.primary
                        : context.palette.goldText,
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

  List<_ReaderPart> _prayerParts(Item source) {
    final body = source.body.trim();

    if (source.id == 'p_daily_blin') {
      const markers = [
        '\n\nሥላሴ ሻትክትድ',
        '\n\nይና እኽር ሰሚል',
        '\nሰላም ሻትክ ገብርኤል',
        '\nዎ ማርያም ኣዳምር',
      ];
      const labels = [
        'Sign of the Cross',
        'Opening devotion',
        'Our Father',
        'Hail Mary',
        'Marian prayer',
      ];
      const icons = [
        Icons.add_rounded,
        Icons.self_improvement_rounded,
        Icons.church_outlined,
        Icons.local_florist_outlined,
        Icons.auto_awesome_outlined,
      ];
      final boundaries = <int>[0];
      var valid = true;
      for (final marker in markers) {
        final boundary = body.indexOf(marker);
        if (boundary < 0) {
          valid = false;
          break;
        }
        boundaries.add(boundary);
      }
      if (valid) {
        return [
          for (var index = 0; index < boundaries.length; index++)
            _ReaderPart(
              labels[index],
              body
                  .substring(
                    boundaries[index],
                    index + 1 < boundaries.length
                        ? boundaries[index + 1]
                        : body.length,
                  )
                  .trim(),
              icons[index],
              emphasized: index == 0,
            ),
        ];
      }
    }

    if (source.id == 'p_acts') {
      return _splitAtHeadings(
        body,
        RegExp(r'^ሺዋን\s', multiLine: true),
        const ['Act of hope', 'Act of charity', 'Act of contrition'],
        Icons.volunteer_activism_outlined,
      );
    }

    if (source.id == 'p_creed') {
      const actHeading = '\nሺዋን ኣማነቱዅ\n';
      final actStart = body.indexOf(actHeading);
      if (actStart > 0) {
        return [
          _ReaderPart(
            'The Apostles’ Creed',
            body.substring(0, actStart).trim(),
            Icons.shield_outlined,
            emphasized: true,
          ),
          _ReaderPart(
            'Act of Faith',
            body.substring(actStart + 1).trim(),
            Icons.volunteer_activism_outlined,
          ),
        ];
      }
    }

    const rosaryMysteries = {
      'p_rosary_joyful',
      'p_rosary_sorrowful',
      'p_rosary_luminous',
      'p_rosary_glorious',
    };
    if (rosaryMysteries.contains(source.id)) {
      final result = <_ReaderPart>[];
      final mysteryHeading = RegExp(
        r'^(?:ሰልፋ|ሊጘር|ሲዀር|ሰጀር|አⶖኰር)\s',
        multiLine: true,
      );
      final matches = mysteryHeading.allMatches(body).toList();
      if (matches.isNotEmpty && matches.first.start > 0) {
        result.add(_ReaderPart(
          'Prayer schedule',
          body.substring(0, matches.first.start).trim(),
          Icons.calendar_today_outlined,
        ));
      }
      for (var index = 0; index < matches.length; index++) {
        final end =
            index + 1 < matches.length ? matches[index + 1].start : body.length;
        result.add(_ReaderPart(
          'Mystery ${index + 1}',
          body.substring(matches[index].start, end).trim(),
          Icons.radio_button_checked_rounded,
          emphasized: index == 0,
        ));
      }
      if (result.isNotEmpty) return result;
    }

    if (source.id == 'p_queen_of_peace') {
      final stanzas = body
          .split(RegExp(r'\n\s*\n'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      return [
        for (var index = 0; index < stanzas.length; index++)
          _ReaderPart(
            'Prayer stanza ${index + 1} of ${stanzas.length}',
            stanzas[index],
            index.isEven
                ? Icons.local_florist_outlined
                : Icons.wb_sunny_outlined,
            emphasized: index == 0,
          ),
      ];
    }

    final paragraphs = body
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (paragraphs.length > 1) {
      return [
        for (var index = 0; index < paragraphs.length; index++)
          _ReaderPart(
            'Prayer part ${index + 1}',
            paragraphs[index],
            index == 0
                ? Icons.self_improvement_rounded
                : Icons.auto_awesome_outlined,
            emphasized: index == 0,
          ),
      ];
    }

    final label = switch (source.group) {
      'daily' => 'Daily prayer',
      'faith' => 'Prayer of faith',
      'confession' => 'Prayer and instruction',
      'rosary' => source.id == 'p_litany' ? 'Marian litany' : 'Rosary prayer',
      'mercy' => 'Divine Mercy prayer',
      'meals' => 'Table prayer',
      _ => 'Prayer',
    };
    return [
      _ReaderPart(label, body, _groupIcon(source), emphasized: true),
    ];
  }

  List<_ReaderPart> _splitAtHeadings(
    String body,
    RegExp heading,
    List<String> labels,
    IconData icon,
  ) {
    final matches = heading.allMatches(body).toList();
    if (matches.isEmpty) return [_ReaderPart('Prayer', body, icon)];
    return [
      for (var index = 0; index < matches.length; index++)
        _ReaderPart(
          index < labels.length ? labels[index] : 'Prayer part ${index + 1}',
          body
              .substring(
                matches[index].start,
                index + 1 < matches.length
                    ? matches[index + 1].start
                    : body.length,
              )
              .trim(),
          icon,
          emphasized: index == 0,
        ),
    ];
  }

  Widget _contentVisual(ContentVisual visual, double scale) {
    final label = visual.alt.trim().isNotEmpty ? visual.alt : item.title;
    final details = [
      if (visual.caption.trim().isNotEmpty) visual.caption.trim(),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            image: true,
            label: '$label. Open full-screen image.',
            child: Material(
              color: context.palette.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openVisual(visual, label),
                child: Image.asset(
                  visual.asset,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  errorBuilder: (context, error, stackTrace) => SizedBox(
                    height: 180,
                    child: Center(
                      child: Text('Image unavailable',
                          style: AppTheme.latin(size: 15 * scale)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (details.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 7, 4, 0),
              child: Text(
                details,
                textAlign: TextAlign.center,
                style: AppTheme.latin(size: 12.5 * scale),
              ),
            ),
        ],
      ),
    );
  }

  void _openVisual(ContentVisual visual, String label) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: Image.asset(
                  visual.asset,
                  fit: BoxFit.contain,
                  semanticLabel: label,
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: IconButton.filled(
                tooltip: 'Close image',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _translationBlock(double scale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.palette.goldDecorative, width: 1),
      ),
      child: Text(item.translation,
          style: AppTheme.latin(
              size: 16 * scale,
              w: FontWeight.w500,
              style: FontStyle.normal,
              color: context.palette.inkMuted)),
    );
  }

  Widget _rubricBody(double scale) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.palette.goldDecorative, width: 1),
      ),
      child: Text(
        item.body,
        style: AppTheme.geezSerif(
                size: 17 * scale, color: context.palette.inkMuted)
            .copyWith(height: 1.9),
      ),
    );
  }

  Widget _catechismBody(double scale, bool showNotes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.body.trim().isNotEmpty) ...[
          _contentCard(
            label: 'Introduction',
            icon: Icons.menu_book_outlined,
            emphasized: true,
            child: PrayerText(
              item.body,
              scale: scale,
              highlightQuery: _highlightQuery,
            ),
          ),
          const SizedBox(height: 12),
        ],
        for (var index = 0; index < item.qa.length; index++)
          _qaPair(item.qa[index], index + 1, scale, showNotes),
      ],
    );
  }

  Widget _qaPair(QA p, int number, double scale, bool showNotes) {
    final hasAnswer = p.a.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.palette.outline, width: 1.15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x103C2614),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.palette.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$number',
                  style: AppTheme.latin(
                    size: 14,
                    w: FontWeight.w700,
                    color: const Color(0xFFF9EFD9),
                    style: FontStyle.normal,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SelectableText(
                  p.q,
                  style: AppTheme.geezSerif(
                    size: 17 * scale,
                    w: FontWeight.w700,
                    color: context.palette.primary,
                  ).copyWith(height: 1.65),
                ),
              ),
            ],
          ),
          if (showNotes && p.qEn.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5, left: 46),
              child: Text(p.qEn, style: AppTheme.latin(size: 14 * scale)),
            ),
          if (hasAnswer) ...[
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(13, 11, 13, 12),
              decoration: BoxDecoration(
                color: context.palette.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.palette.goldDecorative),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A',
                    style: AppTheme.latin(
                      size: 13 * scale,
                      w: FontWeight.w700,
                      color: context.palette.primarySoft,
                      style: FontStyle.normal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SelectableText(
                      p.a,
                      style: AppTheme.geezSerif(size: 16.5 * scale)
                          .copyWith(height: 1.8),
                    ),
                  ),
                ],
              ),
            ),
            if (showNotes && p.aEn.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 32),
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
  /// prayed individually, not sequenced through one after another. Queen of
  /// Peace remains available in the Marian collection but is not inserted
  /// into the established Rosary-to-litany Next sequence.
  Item? get _nextInGroup {
    const mysteryIds = {
      'p_rosary_joyful',
      'p_rosary_sorrowful',
      'p_rosary_luminous',
      'p_rosary_glorious',
    };
    if (mysteryIds.contains(item.id)) {
      return widget.data.byId('p_hail_holy_queen');
    }
    if (item.id == 'p_hail_holy_queen') {
      return widget.data.byId('p_litany');
    }
    final group =
        widget.data.items.where((x) => x.group == item.group).toList();
    final idx = group.indexWhere((x) => x.id == item.id);
    if (idx == -1 || idx == group.length - 1) return null;
    return group[idx + 1];
  }

  Widget _related() {
    final next = _nextInGroup;
    final others = widget.data.items
        .where((x) =>
            x.group == item.group &&
            x.id != item.id &&
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
            color: context.palette.primary,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _open(next),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ደኵሲ',
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
            child:
                Text('More in this section', style: AppTheme.latin(size: 15)),
          ),
          for (final r in others)
            ItemRow(
              leading: r.num?.toString() ??
                  (r.kind == 'hymn'
                      ? '♪'
                      : r.kind == 'catechism'
                          ? '✝'
                          : '☩'),
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

enum _WaySectionKind { prayer, scripture }

class _WaySection {
  final String label;
  final String text;
  final IconData icon;
  final _WaySectionKind kind;

  const _WaySection(this.label, this.text, this.icon, this.kind);
}

class _ReaderPart {
  final String label;
  final String text;
  final IconData icon;
  final bool emphasized;

  const _ReaderPart(
    this.label,
    this.text,
    this.icon, {
    this.emphasized = false,
  });
}
