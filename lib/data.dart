import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// A single readable item: a prayer section, catechism topic, or hymn.
class Item {
  final String id;
  final String kind; // 'prayer' | 'catechism' | 'hymn'
  final String group; // group id
  final String groupTitle;
  final String groupEn;
  final String title;
  final String sub;
  final String note; // English context note (what this is)
  final String translation; // optional full English translation (may be empty)
  final String body;
  final List<QA> qa; // for catechism topics
  final int? num;
  // Hymn-specific fields
  final String refrain;
  final List<String> verses;
  final bool needsReview;
  final List<ContentVisual> visuals;

  Item({
    required this.id,
    required this.kind,
    required this.group,
    required this.groupTitle,
    required this.groupEn,
    required this.title,
    required this.sub,
    required this.note,
    required this.translation,
    required this.body,
    this.qa = const [],
    this.num,
    this.refrain = '',
    this.verses = const [],
    this.needsReview = false,
    this.visuals = const [],
  });

  /// Lowercased haystack for searching.
  String get haystack {
    final b = StringBuffer()
      ..write(title)
      ..write(' ')
      ..write(sub)
      ..write(' ')
      ..write(body)
      ..write(' ')
      ..write(note)
      ..write(' ')
      ..write(translation);
    for (final p in qa) {
      b
        ..write(' ')
        ..write(p.q)
        ..write(' ')
        ..write(p.a);
    }
    return b.toString();
  }
}

/// A locally bundled visual attached to a content item.
class ContentVisual {
  final String asset;
  final String role;
  final String alt;
  final String caption;
  final String credit;
  final int? sourcePage;

  const ContentVisual({
    required this.asset,
    this.role = 'inline',
    this.alt = '',
    this.caption = '',
    this.credit = '',
    this.sourcePage,
  });
}

class QA {
  final String q;
  final String a;
  final String qEn;
  final String aEn;
  QA(this.q, this.a, {this.qEn = '', this.aEn = ''});
}

class CatTopic {
  final int index;
  final String title;
  final String note;
  final List<QA> qa;
  CatTopic(this.index, this.title, this.note, this.qa);
}

class QuizPair {
  final String topic;
  final String q;
  final String a;
  QuizPair(this.topic, this.q, this.a);
}

class TabDef {
  final String id;
  final String label;
  final String en;
  const TabDef(this.id, this.label, this.en);
}

class AppData {
  final String title;
  final String subtitle;
  final String language;
  final String source;
  final List<Item> items; // every readable item
  final List<CatTopic> catechism;
  final List<QuizPair> quiz;
  final Map<String, ({String title, String en})> groupMeta;

  AppData({
    required this.title,
    required this.subtitle,
    required this.language,
    required this.source,
    required this.items,
    required this.catechism,
    required this.quiz,
    required this.groupMeta,
  });

  List<Item> itemsInGroup(String gid) =>
      items.where((i) => i.group == gid).toList();
  List<Item> get hymns => items.where((i) => i.kind == 'hymn').toList();
  List<Item> get catechismItems =>
      items.where((i) => i.kind == 'catechism').toList();
  Item? byId(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  static Future<AppData> load() async {
    final raw = await rootBundle.loadString('assets/data.json');
    final d = json.decode(raw) as Map<String, dynamic>;
    final meta = d['meta'] as Map<String, dynamic>;

    final items = <Item>[];
    final groupMeta = <String, ({String title, String en})>{};

    // Page references remain in canonical JSON for provenance and automated
    // source audits, but are editorial metadata rather than reader-facing copy.
    String displayCopy(Object? raw) {
      return (raw ?? '')
          .toString()
          .replaceAll(
            RegExp(
              r'\s*·\s*Source pages?\s+\d+(?:[–-]\d+)?',
              caseSensitive: false,
            ),
            '',
          )
          .replaceAll(
            RegExp(
              r'\s+from source pages?\s+\d+(?:[–-]\d+)?',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
    }

    QA parseQA(Map m) => QA(
          (m['q'] ?? '').toString(),
          (m['a'] ?? '').toString(),
          qEn: (m['q_en'] ?? '').toString(),
          aEn: (m['a_en'] ?? '').toString(),
        );

    ContentVisual parseVisual(Map m) => ContentVisual(
          asset: (m['asset'] ?? '').toString(),
          role: (m['role'] ?? 'inline').toString(),
          alt: (m['alt'] ?? '').toString(),
          caption: (m['caption'] ?? '').toString(),
          credit: (m['credit'] ?? '').toString(),
          sourcePage: m['source_page'] is int ? m['source_page'] as int : null,
        );

    List<ContentVisual> parseVisuals(Map m) {
      final raw = m['visuals'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(parseVisual)
          .where((visual) => visual.asset.isNotEmpty)
          .toList();
    }

    // Prayer groups
    for (final g in (d['groups'] as List)) {
      final gid = g['id'].toString();
      groupMeta[gid] = (title: g['title'].toString(), en: g['en'].toString());
      for (final s in (g['sections'] as List)) {
        items.add(Item(
          id: 'p_${s['id']}',
          kind: (s['kind'] ?? 'prayer').toString(),
          group: gid,
          groupTitle: g['title'].toString(),
          groupEn: g['en'].toString(),
          title: s['title'].toString(),
          sub: displayCopy(s['subtitle']),
          note: displayCopy(s['note']),
          translation: (s['translation'] ?? '').toString(),
          body: (s['body'] ?? '').toString(),
          visuals: parseVisuals(s as Map),
        ));
      }
    }

    // NOTE: The Rosary's opening prayers now live as the 'rosary_open' section
    // inside the Rosary group (see assets/data.json), so no separate hardcoded
    // 'opening' item is created here.

    // Catechism topics
    final catechism = <CatTopic>[];
    final catList = d['catechism'] as List;
    for (var i = 0; i < catList.length; i++) {
      final t = catList[i] as Map<String, dynamic>;
      final qa = (t['qa'] as List).map((e) => parseQA(e as Map)).toList();
      catechism.add(CatTopic(
        i,
        t['title'].toString(),
        (t['note'] ?? '').toString(),
        qa,
      ));
      items.add(Item(
        id: 'c_$i',
        kind: 'catechism',
        group: 'cat',
        groupTitle: 'ምህሮ ክርስቶስ',
        groupEn: 'Catechism',
        title: t['title'].toString(),
        sub: 'Catechism · ${qa.length} Q&A',
        note: (t['note'] ?? '').toString(),
        translation: '',
        body: (t['intro'] ?? '').toString(),
        qa: qa,
        visuals: parseVisuals(t),
      ));
    }

    // Hymns
    for (final h in (d['hymns'] as List)) {
      final n = h['num'] as int;
      final rawVerses = h['verses'];
      final verses = rawVerses is List
          ? rawVerses.map((v) => v.toString()).toList()
          : <String>[];
      items.add(Item(
        id: 'h_$n',
        kind: 'hymn',
        group: 'hymns',
        groupTitle: 'መዛሙር',
        groupEn: 'Hymns',
        title: h['title'].toString(),
        sub: 'መዝሙር $n',
        note: (h['note'] ?? '').toString(),
        translation: (h['translation'] ?? '').toString(),
        body: (h['body'] ?? '').toString(),
        num: n,
        refrain: (h['refrain'] ?? '').toString(),
        verses: verses,
        needsReview: h['needs_review'] == true,
        visuals: parseVisuals(h as Map),
      ));
    }

    // Quiz uses the reviewed catechism as its single source of truth. The
    // legacy root-level `quiz` list is intentionally ignored.
    final quiz = <QuizPair>[
      for (final topic in catechism)
        for (final pair in topic.qa)
          if (pair.q.trim().isNotEmpty && pair.a.trim().isNotEmpty)
            QuizPair(topic.title, pair.q, pair.a),
    ];

    return AppData(
      title: meta['title'].toString(),
      subtitle: meta['subtitle'].toString(),
      language: meta['language'].toString(),
      source: meta['source'].toString(),
      items: items,
      catechism: catechism,
      quiz: quiz,
      groupMeta: groupMeta,
    );
  }
}
