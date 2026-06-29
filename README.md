# ክርስቶስር ክኒ ግናቲትድ — Blin Prayer App

A complete offline **Flutter** app of Blin (ብሊን) prayers, hymns, and catechism in
Ge'ez script, for the faithful of the **Catholic Eparchy of Keren**.

- 📖 **7 prayer sections** — daily prayers, the Creed & Acts, Confession & Communion,
  the Rosary & Litany, the Divine Mercy Chaplet, the Way of the Cross, and Grace at meals
- ✝️ **Catechism** — 10 topics, 55 question-and-answer pairs (for First Communion)
- 🎓 **Quiz mode** — shuffle-able flashcards, all topics or one at a time
- 🎵 **42 Blin hymns**
- ⭐ Favorites, full-text search, adjustable text size, all **fully offline**
- 🌐 English **context notes** on every section/topic (toggle on/off in Settings),
  plus empty `translation` fields you can fill in later with verified translations

---

## What's in this folder

```
blin_prayers/
├── pubspec.yaml            # dependencies & asset registration
├── analysis_options.yaml
├── assets/
│   └── data.json           # ALL content (prayers, hymns, catechism, quiz)
└── lib/
    ├── main.dart           # app entry, navigation, home/search/favorites/settings
    ├── data.dart           # data models + JSON loader
    ├── store.dart          # favorites / text-size / notes toggle (persisted)
    ├── theme.dart          # colors + Ge'ez fonts (Noto Serif/Sans Ethiopic)
    ├── widgets.dart        # shared UI (rows, cards, formatted prayer text)
    ├── reader_screen.dart  # reading view
    └── quiz_screen.dart    # catechism quiz
```

## Notes on the source material

The content was extracted from three community files:
- a Blin **hymns** text (42 hymns + opening prayers),
- **ግናቲትድ ኒኰስዲክ** ("አውኒ መሀድዅንና") — the catechism + mass prayer book (38 scanned pages),
- **መስቀል ደርብ** — the Way of the Cross devotional (25 scanned pages).

The hymn book was hand-formatted, so a few hymn boundaries may need minor review;
all text is preserved and searchable. Verify against the originals before publishing.
