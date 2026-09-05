import 'package:flutter/material.dart';
import 'data.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets.dart';
import 'reader_screen.dart';
import 'quiz_screen.dart';
import 'prayer_collection_screen.dart';
import 'sources_screen.dart';
import 'version.dart';

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
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) => MaterialApp(
        title: "ሺዋን",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme(dark: false),
        darkTheme: AppTheme.theme(dark: true),
        themeMode: switch (store.appearance) {
          'parchment' => ThemeMode.light,
          'night' => ThemeMode.dark,
          _ => ThemeMode.system,
        },
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
      ),
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
  final _searchFocus = FocusNode();
  String query = '';
  String searchScope = 'all';
  bool searchOpen = false;

  // bottom tabs
  static const _tabs = [
    (icon: Icons.home_rounded, label: 'ልጝ'),
    (icon: Icons.menu_book_rounded, label: 'ሺዋን'),
    (icon: Icons.school_rounded, label: 'ምህሮ'),
    (icon: Icons.music_note_rounded, label: 'መዛሙር'),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openItem(
    Item it, {
    String? highlightQuery,
    bool resumePosition = false,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ReaderScreen(
        data: widget.data,
        store: widget.store,
        itemId: it.id,
        initialQuery: highlightQuery,
        resumePosition: resumePosition,
      ),
    ));
  }

  void _openQuickPrayer(Item item) {
    if (item.group == 'rosary') {
      _openGroup('rosary');
      return;
    }
    _openItem(item);
  }

  void _openGroup(String groupId) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PrayerCollectionScreen(
        data: widget.data,
        store: widget.store,
        groupId: groupId,
      ),
    ));
  }

  void _openSources() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SourcesScreen(data: widget.data),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      body: SafeArea(
        top: false,
        child: query.trim().isNotEmpty
            ? _searchView()
            : IndexedStack(
                index: tab,
                children: [_home(), _prayersHub(), _catechism(), _hymns()],
              ),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: context.palette.primaryDark,
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
            border:
                Border.all(color: context.palette.goldDecorative, width: 1.4),
          ),
          child: Text('✝',
              style: TextStyle(
                  color: context.palette.goldDecorative, fontSize: 19)),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(widget.data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.geezSerif(
                  size: 18,
                  w: FontWeight.w700,
                  color: const Color(0xFFF7ECD6))),
        ),
        IconButton(
          tooltip: 'ጠፍሕ · Search',
          onPressed: () {
            setState(() => searchOpen = !searchOpen);
            if (searchOpen) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _searchFocus.requestFocus(),
              );
            } else {
              _searchCtrl.clear();
              query = '';
            }
          },
          icon: Icon(searchOpen ? Icons.close_rounded : Icons.search_rounded),
        ),
        IconButton(
          tooltip: 'Settings',
          onPressed: _openSettings,
          icon: const Icon(Icons.tune_rounded),
        ),
      ]),
      bottom: searchOpen
          ? PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Material(
                  color: context.palette.card,
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    onChanged: (v) => setState(() => query = v),
                    style: AppTheme.geezSans(size: 15.5, w: FontWeight.w400),
                    decoration: InputDecoration(
                      hintText: 'ጠፍሕ… ሺዋን፣ ምህሮ፣ መዛሙር',
                      hintStyle: AppTheme.geezSans(
                          size: 14.5,
                          w: FontWeight.w400,
                          color: const Color(0xFFA99A82)),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: context.palette.primarySoft),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.backspace_outlined,
                                  color: Color(0xFFB3A387)),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => query = '');
                                _searchFocus.requestFocus();
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: context.palette.outline, width: 1.5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: context.palette.outline, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: context.palette.goldDecorative, width: 1.8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      filled: true,
                      fillColor: context.palette.card,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _bottomBar() {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: context.palette.card,
        indicatorColor: context.palette.surfaceMuted,
        labelTextStyle: WidgetStatePropertyAll(
            AppTheme.geezSans(size: 11.5, w: FontWeight.w600)),
      ),
      child: NavigationBar(
        height: 64,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() {
          tab = i;
          query = '';
          searchOpen = false;
          searchScope = 'all';
          _searchCtrl.clear();
        }),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
                icon: Icon(t.icon, color: context.palette.inkMuted),
                selectedIcon: Icon(t.icon, color: context.palette.primary),
                label: t.label),
        ],
      ),
    );
  }

  // ---------------- HOME ----------------
  Widget _home() {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) => _homeContent(),
    );
  }

  Widget _homeContent() {
    final last = widget.data.byId(widget.store.lastItemId ?? '');
    final favorites = widget.data.items
        .where((item) => widget.store.isFav(item.id))
        .take(4)
        .toList();
    final recent = widget.store.recentIds
        .map(widget.data.byId)
        .whereType<Item>()
        .where((item) => item.id != last?.id)
        .take(4)
        .toList();
    final quickIds = [
      'p_daily_blin',
      'p_rosary_open',
      'p_mercy',
      'p_wayofcross',
    ];
    final quickItems =
        quickIds.map(widget.data.byId).whereType<Item>().toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 34),
      children: [
        _hero(),
        if (last != null) ...[
          const SizedBox(height: 18),
          _continueCard(last),
        ],
        const SizedBox(height: 22),
        _homeUtilityHeading(
          icon: Icons.bolt_rounded,
          label: 'Quick prayer',
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 2 : 1;
            final systemScale = MediaQuery.textScalerOf(context).scale(16) / 16;
            // Ethiopic fonts have taller line metrics than the Latin fallback.
            // Leave enough room for two title lines and the description at the
            // default scale, then grow the tile for accessibility text sizes.
            final height = (166 + (systemScale - 1) * 76).clamp(166, 260);
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 11,
                crossAxisSpacing: 11,
                mainAxisExtent: height.toDouble(),
              ),
              itemCount: quickItems.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = quickItems[index];
                final isRosary = item.group == 'rosary';
                final rosaryMeta = widget.data.groupMeta['rosary'];
                return TileCard(
                  kicker: isRosary ? rosaryMeta!.en : item.groupEn,
                  title: isRosary ? rosaryMeta!.title : item.title,
                  desc: isRosary
                      ? 'Rosary: opening, mysteries & litany'
                      : item.sub,
                  icon: _quickIcon(item.group),
                  onTap: () => _openQuickPrayer(item),
                );
              },
            );
          },
        ),
        const SizedBox(height: 20),
        _homeUtilityHeading(
          icon: Icons.star_rounded,
          label: 'Favorites',
          onTap: () => _showFavorites(favorites),
        ),
        const SizedBox(height: 8),
        if (favorites.isEmpty)
          _emptyHomePanel(
            Icons.star_border_rounded,
            'No favorites yet.',
            'Use the star while reading to keep prayers here.',
          )
        else
          for (final item in favorites)
            ItemRow(
              leading: '★',
              title: item.title,
              sub: item.groupTitle,
              fav: true,
              onTap: () => _openItem(item),
            ),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 14),
          _homeUtilityHeading(
            icon: Icons.history_rounded,
            label: 'Recently opened',
          ),
          const SizedBox(height: 9),
          for (final item in recent)
            ItemRow(
              leading: '↺',
              title: item.title,
              sub: item.groupTitle,
              onTap: () => _openItem(item),
            ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _openQuiz,
            icon: const Icon(Icons.psychology_alt_rounded),
            label: const Text('ፈተና · Quiz'),
          ),
        ),
      ],
    );
  }

  IconData _quickIcon(String group) => switch (group) {
        'daily' => Icons.wb_sunny_outlined,
        'rosary' => Icons.blur_circular_rounded,
        'mercy' => Icons.favorite_rounded,
        'way' => Icons.add_rounded,
        _ => Icons.auto_stories_rounded,
      };

  Widget _homeUtilityHeading({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    final labelWidget = Text(
      label,
      style: AppTheme.latin(
        size: 14,
        w: FontWeight.w700,
        color: context.palette.inkMuted,
        style: FontStyle.normal,
      ),
    );
    return Row(
      children: [
        Icon(icon, color: context.palette.goldText, size: 24),
        const Spacer(),
        if (onTap == null)
          labelWidget
        else
          TextButton.icon(
            onPressed: onTap,
            label: labelWidget,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.chevron_right_rounded, size: 18),
          ),
      ],
    );
  }

  Widget _continueCard(Item item) {
    final complete = widget.store.isCompleted(item.id);
    return Material(
      color: context.palette.primaryDark,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openItem(item, resumePosition: !complete),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  complete ? Icons.replay_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFFF5DDAA),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complete ? 'ኰዶ ተርሲ · Pray again' : 'ቀጽሊ · Continue',
                      style: AppTheme.geezSans(
                        size: 12.5,
                        w: FontWeight.w700,
                        color: const Color(0xFFE9CB8D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.geezSerif(
                        size: 18,
                        w: FontWeight.w700,
                        color: const Color(0xFFFFF4DF),
                      ),
                    ),
                    Text(
                      item.groupTitle,
                      style: AppTheme.geezSans(
                        size: 12.5,
                        color: const Color(0xDDF7ECD6),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Start again',
                onPressed: () {
                  widget.store.resetReading(item.id);
                  _openItem(item);
                },
                icon: const Icon(Icons.restart_alt_rounded,
                    color: Color(0xFFF7ECD6)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyHomePanel(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: context.palette.goldText, size: 30),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTheme.geezSans(size: 15, w: FontWeight.w700)),
                Text(subtitle, style: AppTheme.geezSans(size: 13.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFavorites(List<Item> favorites) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.background,
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 26),
            children: [
              Text('Favorites',
                  style: AppTheme.latin(
                      size: 23,
                      w: FontWeight.w700,
                      color: context.palette.primary,
                      style: FontStyle.normal)),
              const SizedBox(height: 14),
              if (favorites.isEmpty)
                _emptyHomePanel(Icons.star_border_rounded, 'No favorites yet.',
                    'Use the star while reading to keep prayers here.')
              else
                for (final item in widget.data.items
                    .where((entry) => widget.store.isFav(entry.id)))
                  ItemRow(
                    leading: '★',
                    title: item.title,
                    sub: item.groupTitle,
                    fav: true,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _openItem(item);
                    },
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _openQuiz() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(
          backgroundColor: context.palette.primaryDark,
          foregroundColor: const Color(0xFFF7ECD6),
          title: Text('ፈተና',
              style: AppTheme.geezSerif(
                  size: 18,
                  w: FontWeight.w700,
                  color: const Color(0xFFF7ECD6))),
        ),
        body: QuizScreen(data: widget.data),
      ),
    ));
  }

  Widget _hero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.palette.primaryDark, const Color(0xFF321015)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.goldDecorative, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Color(0x387A1F2B), blurRadius: 26, offset: Offset(0, 10)),
        ],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.data.title,
              style: AppTheme.geezSerif(
                  size: 30,
                  w: FontWeight.w700,
                  color: const Color(0xFFF7ECD6))),
        ]),
      ]),
    );
  }

  // ---------------- PRAYERS HUB ----------------
  Widget _prayersHub() {
    const order = [
      'daily',
      'rosary',
      'mercy',
      'way',
      'confession',
      'faith',
      'meals',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        CollectionHero(
          eyebrow: 'Prayer library',
          title: 'ሺዋን',
          subtitle: 'Prayers & Devotions',
          description:
              'Choose a prayer for the day, the sacraments, Marian devotion, mercy, or the table.',
          icon: Icons.auto_stories_rounded,
          badge:
              '${widget.data.items.where((item) => item.group != 'cat' && item.group != 'hymns').length} sections',
        ),
        const SizedBox(height: 22),
        _sectionHeading('ሺዋን ክፍሊታት', 'Prayer collections'),
        const SizedBox(height: 11),
        for (final groupId in order) ...[
          _collectionEntry(groupId),
          const SizedBox(height: 11),
        ],
      ],
    );
  }

  Widget _collectionEntry(String groupId) {
    final meta = widget.data.groupMeta[groupId]!;
    final presentation = prayerGroupPresentation(groupId);
    final count = widget.data.itemsInGroup(groupId).length;
    final countLabel = groupId == 'rosary'
        ? '2 prayer areas'
        : '$count ${count == 1 ? 'section' : 'sections'}';
    final accent = switch (groupId) {
      'rosary' => const Color(0xFF315F8D),
      'mercy' => const Color(0xFF9F2638),
      'way' => const Color(0xFF57151D),
      _ => context.palette.primaryDark,
    };
    return Material(
      color: context.palette.card,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openGroup(groupId),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.palette.outline, width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(presentation.icon,
                    color: const Color(0xFFF7E5B9), size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meta.title,
                        style:
                            AppTheme.geezSerif(size: 18, w: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      '${meta.en} · $countLabel',
                      style: AppTheme.geezSans(
                          size: 13.5,
                          w: FontWeight.w500,
                          color: context.palette.inkMuted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: context.palette.primarySoft),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- CATECHISM ----------------
  Widget _catechism() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      children: [
        CollectionHero(
          eyebrow: 'Learn the faith',
          title: 'ምህሮ ክርስቶስ',
          subtitle: 'Catechism',
          description:
              'Question-and-answer instruction for children preparing for their First Communion.',
          icon: Icons.school_rounded,
          badge: '${widget.data.quiz.length} questions',
        ),
        const SizedBox(height: 20),
        _sectionHeading('${widget.data.catechismItems.length} learning topics',
            'Choose a topic to read'),
        const SizedBox(height: 10),
        for (var index = 0; index < widget.data.catechismItems.length; index++)
          ItemRow(
            leading: '${index + 1}',
            title: widget.data.catechismItems[index].title,
            sub: widget.data.catechismItems[index].note.isNotEmpty
                ? widget.data.catechismItems[index].note
                : widget.data.catechismItems[index].sub,
            fav: widget.store.isFav(widget.data.catechismItems[index].id),
            onTap: () => _openItem(widget.data.catechismItems[index]),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _openGroup('confession'),
          icon: const Icon(Icons.church_outlined),
          label: const Text('ንስሒዅ · Confession & Communion prayers'),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
                backgroundColor: context.palette.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {
              _openQuiz();
            },
            icon: const Icon(Icons.school_rounded, color: Color(0xFFF7ECD6)),
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
        CollectionHero(
          eyebrow: 'Sing and pray',
          title: 'መዛሙር ብሊነው',
          subtitle: 'Blin Hymns',
          description:
              'A numbered collection of hymns for worship, prayer, and community life.',
          icon: Icons.music_note_rounded,
          badge: '${widget.data.hymns.length} hymns',
        ),
        const SizedBox(height: 20),
        _sectionHeading('Hymn book', 'Select a hymn to begin'),
        const SizedBox(height: 10),
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

  // ---------------- SEARCH ----------------
  Widget _searchView() {
    final q = query.trim();
    final ql = q.toLowerCase();
    final results = <(Item, String)>[];
    for (final it in widget.data.items) {
      final inScope = switch (searchScope) {
        'prayers' => it.kind == 'prayer' || it.kind == 'rubric',
        'catechism' => it.kind == 'catechism',
        'hymns' => it.kind == 'hymn',
        _ => true,
      };
      if (!inScope) continue;
      final hay = it.haystack;
      final inTitle = it.title.contains(q);
      final hit = hay.contains(q) || hay.toLowerCase().contains(ql) || inTitle;
      if (!hit) continue;
      String snip = '';
      final pos = it.body.indexOf(q);
      if (pos >= 0) {
        final s = (pos - 30).clamp(0, it.body.length);
        snip = it.body
            .substring(s, (pos + q.length + 50).clamp(0, it.body.length));
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final filter in const [
                (id: 'all', label: 'ናድካ · All'),
                (id: 'prayers', label: 'ሺዋን'),
                (id: 'catechism', label: 'ምህሮ'),
                (id: 'hymns', label: 'መዛሙር'),
              ]) ...[
                ChoiceChip(
                  label: Text(filter.label),
                  selected: searchScope == filter.id,
                  onSelected: (_) => setState(() => searchScope = filter.id),
                ),
                const SizedBox(width: 7),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(results.length == 1 ? '1 result' : '${results.length} results',
            style: AppTheme.latin(size: 15)),
        const SizedBox(height: 10),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(children: [
              Icon(Icons.search_off_rounded,
                  size: 48, color: context.palette.outline),
              const SizedBox(height: 10),
              Text('ናድካ እስኒን ኣኽከ', style: AppTheme.geezSerif(size: 17)),
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
                setState(() {
                  query = '';
                  searchOpen = false;
                });
                _openItem(it, highlightQuery: q);
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

  Widget _sectionHeading(String title, String subtitle) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTheme.latin(
                size: 18,
                w: FontWeight.w700,
                color: context.palette.primary,
                style: FontStyle.normal,
              ),
            ),
          ),
          Text(
            subtitle,
            style: AppTheme.latin(size: 13.5, style: FontStyle.normal),
          ),
        ],
      );

  // ---------------- SETTINGS ----------------
  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: context.palette.outline,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('ቅንብር · Settings',
                    style: AppTheme.geezSerif(
                        size: 20,
                        w: FontWeight.w700,
                        color: context.palette.primary)),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  thumbColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? context.palette.primary
                        : null,
                  ),
                  value: widget.store.showNotes,
                  onChanged: (v) => widget.store.setShowNotes(v),
                  title: Text('English notes',
                      style: AppTheme.geezSans(size: 16, w: FontWeight.w600)),
                  subtitle: Text('Show English context notes & translations',
                      style: AppTheme.latin(size: 14)),
                ),
                const SizedBox(height: 4),
                Text('ፊደል ግዝፈት · Text size',
                    style: AppTheme.geezSans(size: 16, w: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final preset in const [
                      (value: 0.9, label: 'Small'),
                      (value: 1.0, label: 'Standard'),
                      (value: 1.25, label: 'Large'),
                      (value: 1.55, label: 'Extra large'),
                    ])
                      ChoiceChip(
                        label: Text(preset.label),
                        selected:
                            (widget.store.scale - preset.value).abs() < .05,
                        onSelected: (_) => widget.store.setScale(preset.value),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.palette.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.palette.outline),
                  ),
                  child: Text(
                    'ዎ ይና አደራ ረሓሚና።',
                    style: AppTheme.geezSerif(size: 18 * widget.store.scale),
                  ),
                ),
                const SizedBox(height: 18),
                Text('ኣርኣያ · Appearance',
                    style: AppTheme.geezSans(size: 16, w: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final option in const [
                      (
                        id: 'system',
                        label: 'System',
                        icon: Icons.brightness_auto
                      ),
                      (
                        id: 'parchment',
                        label: 'Parchment',
                        icon: Icons.light_mode
                      ),
                      (
                        id: 'night',
                        label: 'Night Prayer',
                        icon: Icons.dark_mode
                      ),
                    ])
                      ChoiceChip(
                        avatar: Icon(option.icon, size: 18),
                        label: Text(option.label),
                        selected: widget.store.appearance == option.id,
                        onSelected: (_) =>
                            widget.store.setAppearance(option.id),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Ornament(),
                Text(widget.data.title,
                    style: AppTheme.geezSerif(
                        size: 17,
                        w: FontWeight.w700,
                        color: context.palette.primary)),
                Text(
                  'Version $appVersion ($buildNumber)',
                  style: AppTheme.latin(
                    size: 13.5,
                    color: context.palette.inkMuted,
                    style: FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                    'Blin (ብሊን) prayers, hymns and catechism in Ge\u2019ez script, '
                    'Works fully offline.',
                    style: AppTheme.latin(size: 15, style: FontStyle.normal)),
                const SizedBox(height: 8),
                Builder(builder: (context) {
                  final prayerCount =
                      widget.data.items.where((i) => i.kind == 'prayer').length;
                  return Text(
                      '☩ $prayerCount prayer sections   '
                      '✝ ${widget.data.catechism.length} catechism topics   '
                      '♪ ${widget.data.hymns.length} hymns',
                      style: AppTheme.geezSans(
                          size: 13,
                          w: FontWeight.w400,
                          color: context.palette.inkMuted));
                }),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('ምንጪታት · Sources & Credits'),
                  subtitle:
                      const Text('Books, images, authorization and fonts'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openSources();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
