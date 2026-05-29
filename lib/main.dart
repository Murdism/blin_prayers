import 'package:flutter/material.dart';
import 'data.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';
import 'reader_screen.dart';
import 'quiz_screen.dart';

void main() {
  runApp(const BlinApp());
}

class BlinApp extends StatefulWidget {
  const BlinApp({super.key});
  @override
  State<BlinApp> createState() => _BlinAppState();
}

class _BlinAppState extends State<BlinApp> {
  final store = AppStore();
  AppData? data;
  Object? error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await store.init();
      final d = await AppData.load();
      setState(() => data = d);
    } catch (e) {
      setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "ሺዋን", 
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme(),
      home: error != null
          ? Scaffold(
              body: Center(
                  child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Failed to load data:\n$error',
                    textAlign: TextAlign.center),
              )))
          : data == null
              ? const Scaffold(
                  backgroundColor: AppColors.wine,
                  body: Center(
                      child: Text('☩',
                          style: TextStyle(
                              fontSize: 64, color: Color(0xFFCDA85A)))),
                )
              : HomeShell(data: data!, store: store),
    );
  }
}

/// Bottom-tab shell.
class HomeShell extends StatefulWidget {
  final AppData data;
  final AppStore store;
  const HomeShell({super.key, required this.data, required this.store});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  final _searchCtrl = TextEditingController();
  String query = '';

  // bottom tabs
  static const _tabs = [
    (icon: Icons.home_rounded, label: 'ልጝ'),
    (icon: Icons.menu_book_rounded, label: 'ሺዋን'),
    (icon: Icons.school_rounded, label: 'ምህሮ'),
    (icon: Icons.music_note_rounded, label: 'መዛሙር'),
    (icon: Icons.star_rounded, label: 'Favorites'),
  ];

  void _openItem(Item it) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderScreen(
          data: widget.data, store: widget.store, itemId: it.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        top: false,
        child: query.trim().isNotEmpty ? _searchView() : _bodyForTab(),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: AppColors.wine,
      foregroundColor: const Color(0xFFF7ECD6),
      elevation: 2,
      titleSpacing: 14,
      title: Row(children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x22000000),
            border: Border.all(color: AppColors.goldSoft, width: 1.4),
          ),
          child: const Text('✝',
              style: TextStyle(color: AppColors.goldSoft, fontSize: 19)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.geezSerif(
                      size: 18,
                      w: FontWeight.w700,
                      color: const Color(0xFFF7ECD6))),
              Text(widget.data.source,
                  style: AppTheme.latin(
                      size: 12.5, color: const Color(0xCCF7ECD6))),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: _openSettings,
          icon: const Icon(Icons.tune_rounded),
        ),
      ]),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(58),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => query = v),
              style: AppTheme.geezSans(size: 15.5, w: FontWeight.w400),
              decoration: InputDecoration(
                hintText: 'ጠፍሕ… search prayers, hymns, catechism',
                hintStyle: AppTheme.geezSans(
                    size: 14.5,
                    w: FontWeight.w400,
                    color: const Color(0xFFA99A82)),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.wineSoft),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFFB3A387)),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.line, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.line, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.goldSoft, width: 1.8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                filled: true,
                fillColor: AppColors.card,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.parch2,
        labelTextStyle: WidgetStatePropertyAll(
            AppTheme.geezSans(size: 11.5, w: FontWeight.w600)),
      ),
      child: NavigationBar(
        height: 64,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() {
          tab = i;
          query = '';
          _searchCtrl.clear();
        }),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
                icon: Icon(t.icon, color: AppColors.inkSoft),
                selectedIcon: Icon(t.icon, color: AppColors.wine),
                label: t.label),
        ],
      ),
    );
  }

  Widget _bodyForTab() {
    switch (tab) {
      case 0:
        return _home();
      case 1:
        return _prayersHub();
      case 2:
        return _catechism();
      case 3:
        return _hymns();
      case 4:
        return _favorites();
      default:
        return _home();
    }
  }

  // ---------------- HOME ----------------
  Widget _home() {
    final cards = [
      (tab: 1, k: 'Prayers', t: 'ሺዋን', d: 'Daily prayers, Creed, Rosary, Divine Mercy, Way of the Cross & more'),
      (tab: 2, k: 'Catechism', t: 'ምህሮ ክርስቶስ', d: '${widget.data.quiz.length} questions across ${widget.data.catechism.length} topics — for First Communion'),
      (tab: 3, k: 'Hymns', t: 'መዛሙር ብሊነው', d: '${widget.data.hymns.length} Blin hymns & songs'),
      (tab: -1, k: 'Quiz', t: 'ፈተና', d: 'Flashcard quiz mode for children'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      children: [
        _hero(),
        const Ornament(),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.18,
          children: [
            for (final c in cards)
              TileCard(
                kicker: c.k,
                title: c.t,
                desc: c.d,
                onTap: () {
                  if (c.tab == -1) {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => Scaffold(
                              appBar: AppBar(
                                backgroundColor: AppColors.wine,
                                foregroundColor: const Color(0xFFF7ECD6),
                                title: Text('ፈተና',
                                    style: AppTheme.geezSerif(
                                        size: 18,
                                        w: FontWeight.w700,
                                        color: const Color(0xFFF7ECD6))),
                              ),
                              body: QuizScreen(data: widget.data),
                            )));
                  } else {
                    setState(() => tab = c.tab);
                  }
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wine, AppColors.wineDeep],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldSoft, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x387A1F2B), blurRadius: 26, offset: Offset(0, 10)),
        ],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.data.source.toUpperCase(),
              style: AppTheme.latin(
                  size: 13,
                  w: FontWeight.w600,
                  color: const Color(0xBFF7ECD6))),
          const SizedBox(height: 6),
          Text(widget.data.title,
              style: AppTheme.geezSerif(
                  size: 30,
                  w: FontWeight.w700,
                  color: const Color(0xFFF7ECD6))),
          const SizedBox(height: 2),
          Text(widget.data.subtitle,
              style: AppTheme.latin(
                  size: 17, color: const Color(0xD9F7ECD6))),
          const SizedBox(height: 12),
          Text(widget.data.language,
              style: AppTheme.geezSans(
                  size: 12.5,
                  w: FontWeight.w400,
                  color: const Color(0xB3F7ECD6))),
        ]),
      ]),
    );
  }

  // ---------------- PRAYERS HUB ----------------
  Widget _prayersHub() {
    final groups = widget.data.groupMeta.entries
        .where((e) => e.key != 'cat' && e.key != 'hymns')
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        _viewTitle('ሺዋን', 'Prayers & Devotions'),
        const Ornament(),
        for (final g in groups) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 6, bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(g.value.title,
                  style: AppTheme.geezSerif(
                      size: 18, w: FontWeight.w700, color: AppColors.wine)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(g.value.en, style: AppTheme.latin(size: 14)),
              ),
            ]),
          ),
          for (final it in widget.data.itemsInGroup(g.key))
            ItemRow(
              leading: '☩',
              title: it.title,
              sub: it.note.isNotEmpty ? it.note : it.sub,
              fav: widget.store.isFav(it.id),
              onTap: () => _openItem(it),
            ),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  // ---------------- CATECHISM ----------------
  Widget _catechism() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        _viewTitle('ምህሮ ክርስቶስ', 'Catechism'),
        const Ornament(glyph: '✝'),
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 14),
          child: Text(
              'Question-and-answer instruction for children preparing '
              'for their First Communion.',
              style: AppTheme.latin(size: 15.5)),
        ),
        for (final it in widget.data.catechismItems)
          ItemRow(
            leading: '✝',
            title: it.title,
            sub: it.note.isNotEmpty ? it.note : it.sub,
            fav: widget.store.isFav(it.id),
            onTap: () => _openItem(it),
          ),
        const Ornament(glyph: '✝'),
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text('ሥቱራን · Sacraments',
              style: AppTheme.geezSerif(
                  size: 16, w: FontWeight.w700, color: AppColors.wine)),
        ),
        for (final it in widget.data.items
            .where((x) => x.group == 'confession'))
          ItemRow(
            leading: '✝',
            title: it.title,
            sub: it.note.isNotEmpty ? it.note : it.sub,
            fav: widget.store.isFav(it.id),
            onTap: () => _openItem(it),
          ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.wine,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                        appBar: AppBar(
                          backgroundColor: AppColors.wine,
                          foregroundColor: const Color(0xFFF7ECD6),
                          title: Text('ፈተና',
                              style: AppTheme.geezSerif(
                                  size: 18,
                                  w: FontWeight.w700,
                                  color: const Color(0xFFF7ECD6))),
                        ),
                        body: QuizScreen(data: widget.data),
                      )));
            },
            icon: const Icon(Icons.school_rounded,
                color: Color(0xFFF7ECD6)),
            label: Text('ፈተና ተርሲ · Start Quiz',
                style: AppTheme.geezSerif(
                    size: 16,
                    w: FontWeight.w700,
                    color: const Color(0xFFF7ECD6))),
          ),
        ),
      ],
    );
  }

  // ---------------- HYMNS ----------------
  Widget _hymns() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        _viewTitle('መዛሙር ብሊነው', 'Blin Hymns'),
        const Ornament(glyph: '♪'),
        for (final it in widget.data.hymns)
          ItemRow(
            leading: it.num!.toString(),
            title: it.title,
            sub: it.sub,
            fav: widget.store.isFav(it.id),
            onTap: () => _openItem(it),
          ),
      ],
    );
  }

  // ---------------- FAVORITES ----------------
  Widget _favorites() {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) {
        final favs = widget.data.items
            .where((i) => widget.store.isFav(i.id))
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
          children: [
            _viewTitle('Favorites ★', 'Favorites'),
            const Ornament(glyph: '★'),
            if (favs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Column(children: [
                  const Icon(Icons.star_border_rounded,
                      size: 54, color: AppColors.line),
                  const SizedBox(height: 12),
                  Text('No favorites yet.',
                      style: AppTheme.latin(size: 18)),
                  const SizedBox(height: 6),
                  Text(
                      'Tap the star ☆ while reading to save a prayer or hymn here.',
                      textAlign: TextAlign.center,
                      style: AppTheme.latin(size: 15)),
                ]),
              )
            else
              for (final it in favs)
                ItemRow(
                  leading: it.num?.toString() ??
                      (it.kind == 'hymn'
                          ? '♪'
                          : it.kind == 'catechism'
                              ? '✝'
                              : '☩'),
                  title: it.title,
                  sub: it.sub,
                  fav: true,
                  onTap: () => _openItem(it),
                ),
          ],
        );
      },
    );
  }

  // ---------------- SEARCH ----------------
  Widget _searchView() {
    final q = query.trim();
    final ql = q.toLowerCase();
    final results = <(Item, String)>[];
    for (final it in widget.data.items) {
      final hay = it.haystack;
      final inTitle = it.title.contains(q);
      final hit = hay.contains(q) || hay.toLowerCase().contains(ql) || inTitle;
      if (!hit) continue;
      String snip = '';
      final pos = it.body.indexOf(q);
      if (pos >= 0) {
        final s = (pos - 30).clamp(0, it.body.length);
        snip = it.body.substring(s, (pos + q.length + 50).clamp(0, it.body.length));
      } else if (it.qa.isNotEmpty) {
        for (final p in it.qa) {
          final combo = '${p.q} — ${p.a}';
          final k = combo.indexOf(q);
          if (k >= 0) {
            snip = combo.substring((k - 20).clamp(0, combo.length),
                (k + 60).clamp(0, combo.length));
            break;
          }
        }
      }
      results.add((it, snip.replaceAll('\n', ' ')));
    }
    // title matches first
    results.sort((a, b) {
      final at = a.$1.title.contains(q) ? 0 : 1;
      final bt = b.$1.title.contains(q) ? 0 : 1;
      return at - bt;
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      children: [
        Text(
            results.length == 1
                ? '1 result'
                : '${results.length} results',
            style: AppTheme.latin(size: 15)),
        const SizedBox(height: 10),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(children: [
              const Icon(Icons.search_off_rounded,
                  size: 48, color: AppColors.line),
              const SizedBox(height: 10),
              Text('ናድካ እስኒን ኣኽከ',
                  style: AppTheme.geezSerif(size: 17)),
            ]),
          )
        else
          for (final (it, snip) in results.take(80))
            ItemRow(
              leading: it.kind == 'hymn'
                  ? '♪'
                  : it.kind == 'catechism'
                      ? '✝'
                      : '☩',
              titleSpans: _highlight(it.title, q),
              title: it.title,
              sub: snip.isNotEmpty
                  ? '${it.groupTitle} · …$snip…'
                  : it.groupTitle,
              onTap: () {
                _searchCtrl.clear();
                setState(() => query = '');
                _openItem(it);
              },
            ),
      ],
    );
  }

  List<InlineSpan> _highlight(String text, String q) {
    if (q.isEmpty) return [TextSpan(text: text)];
    final spans = <InlineSpan>[];
    var start = 0;
    final lower = text.toLowerCase();
    final ql = q.toLowerCase();
    while (true) {
      final i = lower.indexOf(ql, start);
      if (i < 0) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (i > start) spans.add(TextSpan(text: text.substring(start, i)));
      spans.add(TextSpan(
        text: text.substring(i, i + q.length),
        style: const TextStyle(
            backgroundColor: Color(0x47B58A3A), fontWeight: FontWeight.w700),
      ));
      start = i + q.length;
    }
    return spans;
  }

  // ---------------- SETTINGS ----------------
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.line,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('ቅንብር · Settings',
                  style: AppTheme.geezSerif(
                      size: 20, w: FontWeight.w700, color: AppColors.wine)),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.wine,
                value: widget.store.showNotes,
                onChanged: (v) => widget.store.setShowNotes(v),
                title: Text('English notes',
                    style: AppTheme.geezSans(size: 16, w: FontWeight.w600)),
                subtitle: Text('Show English context notes & translations',
                    style: AppTheme.latin(size: 14)),
              ),
              const SizedBox(height: 4),
              Text('Text size',
                  style: AppTheme.geezSans(size: 16, w: FontWeight.w600)),
              Row(children: [
                _scaleBtn(Icons.text_decrease_rounded, -0.1),
                const SizedBox(width: 12),
                Text('${(widget.store.scale * 100).round()}%',
                    style: AppTheme.geezSerif(size: 16)),
                const SizedBox(width: 12),
                _scaleBtn(Icons.text_increase_rounded, 0.1),
              ]),
              const SizedBox(height: 18),
              const Ornament(),
              Text(widget.data.title,
                  style: AppTheme.geezSerif(
                      size: 17, w: FontWeight.w700, color: AppColors.wine)),
              const SizedBox(height: 4),
              Text(
                  'Blin (ብሊን) prayers, hymns and catechism in Ge\u2019ez script, '
                  'for the faithful of the ${widget.data.source}. '
                  'Works fully offline.',
                  style: AppTheme.latin(size: 15, style: FontStyle.normal)),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final prayerCount = widget.data.items
                    .where((i) => i.kind == 'prayer')
                    .length;
                return Text(
                    '☩ $prayerCount prayer sections   '
                    '✝ ${widget.data.catechism.length} catechism topics   '
                    '♪ ${widget.data.hymns.length} hymns',
                    style: AppTheme.geezSans(
                        size: 13,
                        w: FontWeight.w400,
                        color: AppColors.inkSoft));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scaleBtn(IconData icon, double delta) => Material(
        color: AppColors.parch2,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.store.bumpScale(delta),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: AppColors.wine),
          ),
        ),
      );

  Widget _viewTitle(String t, String en) => Padding(
        padding: const EdgeInsets.only(top: 8, left: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Flexible(
            child: Text(t,
                style: AppTheme.geezSerif(
                    size: 22, w: FontWeight.w700, color: AppColors.wine)),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(en, style: AppTheme.latin(size: 15)),
          ),
        ]),
      );
}
