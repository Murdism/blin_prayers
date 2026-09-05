# ክርስቶስር ክኒ ግናቲትድ — Blin Prayer App

A complete offline **Flutter** app of Blin (ብሊን) prayers, hymns, and catechism in
Ge'ez script, for the faithful of the **Catholic Eparchy of Keren**.

Current application release: **2.0.0+2** — the first major reader and
navigation redesign.

> Detailed project, architecture, content, development, and improvement
> documentation lives in [`docs/`](docs/README.md).

- 📖 **7 prayer collections** — daily prayers, the Creed & Acts, Confession &
  Communion, Marian Prayers with a grouped Rosary, the Divine Mercy Chaplet,
  the Way of the Cross, and Grace at meals
- ✝️ **Catechism** — 11 topics, 65 question-and-answer pairs (for First Communion)
- 🎓 **Quiz mode** — shuffle-able flashcards, all topics or one at a time
- 🎵 **40 Blin hymns**
- 🖼️ Source-linked devotional artwork with offline viewing and tap-to-zoom
- ✨ Dedicated four-stage Divine Mercy and Way of the Cross journeys, structured
  prayer cards, Rosary mystery steps, and catechism Q&A panels
- ⭐ Favorites, recent prayers, reading-position recovery, filtered full-text
  search, and four text-size presets
- 🌙 System, parchment, and low-light Night Prayer appearances
- 📴 Religious content, images, and Ethiopic/Latin fonts are all bundled for
  **fully offline** reading
- 📜 A nontechnical Sources & Credits page with source-book identity and
  authorization artwork
- 🌐 English **context notes** on every section/topic (toggle on/off in Settings),
  plus empty `translation` fields you can fill in later with verified translations

---

## What's in this folder

```
blin_prayers/
├── pubspec.yaml            # dependencies & asset registration
├── analysis_options.yaml
├── assets/
│   ├── data.json           # ALL text content (prayers, hymns, catechism)
│   ├── fonts/              # Bundled OFL Ethiopic and Latin fonts
│   └── images/             # Devotional and source-provenance visuals
└── lib/
    ├── main.dart           # app entry, navigation, home/search/favorites/settings
    ├── data.dart           # data models + JSON loader
    ├── store.dart          # preferences + local reading continuity
    ├── theme.dart          # semantic parchment/night themes + bundled fonts
    ├── widgets.dart        # shared UI (rows, cards, formatted prayer text)
    ├── divine_mercy_widgets.dart # four-stage Divine Mercy collection/reader
    ├── way_of_cross_widgets.dart # responsive station collection
    ├── reader_screen.dart  # generic and feature-specific reading views
    ├── prayer_collection_screen.dart # focused collection routes
    ├── sources_screen.dart # source identity, credits, authorization
    └── quiz_screen.dart    # catechism quiz
```

## Notes on the source material

The content was extracted from three community files:
- a Blin **hymns** text,
- **አውኒ መሀድዅንና 2026** — the text-native 38-page Catholic Eparchy of
  Keren prayer and catechism book used to reconcile the corresponding app
  sections,
- **ፊዅሰን መስቀሉ 2025** — the authoritative text-native Catholic Eparchy of
  Keren booklet for the complete daily prayer, the Way of the Cross
  (preparation, fourteen stations, conclusion, and fifteen illustrations), and
  the Divine Mercy text;
- **ጊመት ሰላምሪ 2025** — a one-page text-native source for the seven-stanza
  Marian prayer presented editorially as “Mary, Queen of Peace.”

The directly supplied `ኢየሱስ.jpg` is the authoritative runtime Divine Mercy
image. Cover, publication, and introductory pages are kept as provenance; all
new or revised devotional sections from supplied sources are included.

The hymn book was hand-formatted, so a few hymn boundaries may need minor review;
all text is preserved and searchable. The source reconciliations are documented
in [`docs/SOURCE_BOOK_AUDIT_2026.md`](docs/SOURCE_BOOK_AUDIT_2026.md) and
[`docs/WAY_OF_CROSS_AUDIT_2025.md`](docs/WAY_OF_CROSS_AUDIT_2025.md).
The later one-page prayer and its supporting DOCX/image comparison are recorded
in
[`docs/ADDITIONAL_SOURCE_AUDIT_2025.md`](docs/ADDITIONAL_SOURCE_AUDIT_2025.md).
Obtain final Blin-language and ecclesial review before publishing.
