#!/usr/bin/env python3
"""Apply prayer text reconciled from the user-supplied authoritative booklets.

This is intentionally narrow: it completes the daily prayer from page 6,
replaces the abbreviated Divine Mercy opening with the complete text printed on
pages 42–43 of ``ፊዅሰን መስቀሉ.pdf``, and applies final exact-source details
from ``አውኒ መሀድዅንና 2026.pdf``. The litanies remain digitally expanded
instead of reproducing the booklets' ditto marks and vertical response text.
"""

from __future__ import annotations

import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "assets" / "data.json"

DIVINE_MERCY_OPENING = """ራሕመት መለኮቱዅሊ ድምስታዅ ሺዋን
1. ሱⶖ እኽርዱዅድ፡ ኡዅሪዅድ፡ መንፈስ ሻትኩዅድ፡
ላዅ ጃር፤ አሜን።
2. ይና እኽር ሰሚል መንደርትራኽር፡ ኵሱⶖ ሸተክኒ፣ ኵምልክኻ
እንትኒ፣ ኵኪን ሰሚል ኣኻዅሰና ብሪልኽር ኣኽኒ። ይና ነብራ
ግርጉዅሲ ንኪ ናኽና፣ ይን ይነት ዓገበውሲ ብሕል ይናዅሰና፡ ይና
ዓገብሲ ብሕል ዪና፣ ሸርልድ እርግሲና፣ ምቝሊልድኻ ደአንዲና፣
ውረድ ምልክዲ፡ ሒልዲ፡ ሳቡርዲ፡ ዲማ ዳይምድ ኩዅ ግን።
አሜን።
3. ሰላም ሻትክ ገብርኤል ንሽቂዅ፡ ዎ ይና ተደራ ማርያም ሕላንዲ
ሥኻዲሲ ድንግሊ፡ ጃር ሒለቱዅድ ገና፡ ሰላም ኵድ ኣኽኒ። እንቲ
ኡሰውልድክ ገውርስራኽር ግን፣ እን ኵከርስ ፍራኽር ገውርሳዅ
ግን።
ዎ ማርያም ገድድ እንታኽራኽር ፋርሒ ፈርሒ፡ ጃር ኵዲ ግን።
ናንዲ ይና ክሪ ወክትዲትል ይና ሓራምሲ ብሕል ይሮነር መታን፡ እን
እጝከልሳዅ ኩኡዅራ ኢየሱስ ክርስቶስትል ሺዊኽር ተዓየቢኽር፤
አሜን።
4. ሺዋን ኣማነቱዅ ኢየሱስር ታለይቱት ድሪስናዅ

ኒትክ ገረሳዅ ሰማዲ ብራዲት መሀዳዅ እኽር ጃርሊ እምነኵን፣ ላዅ
ኒኡዅራ ኢየሱስ ክርስቶስትልኽር እምነኵን፣ ኒኻ መንፈስ ሻትክ ሒልድ
ሓነንሱዅ፣ ማርያም ድንግሊትልድ እዃርሱዅ፣ ጲላጦስ ጶንጥዮስር
ሢመር ዓጝቐይሊ ጃደይሱዅ፣ ከርከርሱዅ፣ ክሩዅ፣ ደብቲዅ፣
ሲኦሊ ገሙዅ፣ ሲዀር ኳሪል ክሪልድ ጒዅ፣ ሰሚል ዓረጉዅ፣ እን
ኒትክ ገረሳዅ እኽር ጃር ላውሊኽር ከፍ ዩዅ፣ ደምብንኻ፡ ህምበውዲ፡
ክረውዲት ፈረድሮ እንትሮ ግን። መንፈስ ሻትክዲ፡ ቤክስታኒ
ሻትኪ ካቶሊክሪዲ፡ ሻትካንዲ በኑዅ ኣክናዲ፣ ሓራም ባርስትናዲ፡
ክሪልድ ጕናዲ፡ ዲመር መናብረትዲትልኽር እምነኵን፣ አሜን።"""

DAILY_COMPLETION = """ይና እኽር ሰሚል መንደርትራኽር፡ ኵሱⶖ ሸተክኒ፣ ኵምልክኻ
እንትኒ፣ ኵኪን ሰሚል ኣኻዅሰና ብሪልኽር ኣኽኒ። ይና ነብራ
ግርጉዅሲ ንኪ ናኽና፣ ይን ይነት ዓገበውሲ ብሕል ይናዅሰና፡ ይና
ዓገብሲ ብሕል ዪና፣ ሸርልድ እርግሲና፣ ምቝሊልድኻ ደአንዲና፣
ውረድ ምልክዲ፡ ሒልዲ፡ሳቡርዲ፡ ዲማ ዳይምድ ኩዅ ግን። አሜን።
ሰላም ሻትክ ገብርኤል ንሽቂዅ፡ ዎ ይና ተደራ ማርያም ሕላንዲ
ሥኻዲሲ ድንግሊ፡ ጃር ሒለቱዅድ ገና፡ ሰላም ኵድ ኣኽኒ። እንቲ
ኡሰውልድክ ገውርስራኽር ግን፣ እን ኵከርስ ፍራኽር ገውርሳዅ
ግን። ዎ ማርያም ገድድ እንታኽረሪ ፋርሒ ፈርሒ፡ ጃር ኵዲ
ግን። ናንዲ ይና ክራ ሁመትዲትል ይና ሓራምሲ ብሕል ይሮነር
መታን፡ እን እጝከልሳዅ ኵኡዅራ ኢየሱስ ክርስቶስትል ሺዊኽር
ተዓየቢኽር፤ አሜን።
ዎ ማርያም ኣዳምር ሓራም እጝገት ሓነንስራኽር ኵል ተዓየብናኽርድ
ሺዊልና፥ ሳቡር እኽርድ ሳቡር ኡዅረድ ሳቡር መንፈስ ሻትክድ
ኣኽኒ፣ ናንዲ፡ ዲማዲ፡ ዲማ ዳይምዲሲ፥ አሜን።"""


def section_by_id(data: dict, section_id: str) -> dict:
    matches = [
        section
        for group in data["groups"]
        for section in group["sections"]
        if section.get("id") == section_id
    ]
    if len(matches) != 1:
        raise SystemExit(
            f"Expected exactly one {section_id!r} section, found {len(matches)}"
        )
    return matches[0]


def group_by_id(data: dict, group_id: str) -> dict:
    matches = [group for group in data["groups"] if group.get("id") == group_id]
    if len(matches) != 1:
        raise SystemExit(f"Expected exactly one {group_id!r} group, found {len(matches)}")
    return matches[0]


def replace_once(body: str, old: str, new: str, label: str) -> str:
    """Replace one source variant while allowing a repeated reconciliation."""
    count = body.count(old)
    if count == 1:
        return body.replace(old, new, 1)
    if count == 0 and new in body:
        return body
    raise SystemExit(f"Expected exactly one unreconciled {label}; found {count}")


def complete_daily_prayer(section: dict) -> None:
    body = section["body"].strip()
    body = body.replace("መስቀል\nእሻረትድ", "መስቀል እሻረትድ")
    if "ይና እኽር ሰሚል መንደርትራኽር" not in body:
        body = f"{body}\n\n{DAILY_COMPLETION}"
    section["body"] = body
    section["note"] = (
        "The complete daily prayer sequence from source page 6: the Sign of "
        "the Cross, devotional act, Our Father, Hail Mary, and Marian prayer."
    )


def reconcile_divine_mercy(section: dict) -> None:
    body = section["body"].strip()
    fifth_step = body.find("5. ")
    if fifth_step < 0:
        raise SystemExit("Could not find Divine Mercy step 5")

    body = f"{DIVINE_MERCY_OPENING}\n{body[fifth_step:]}"
    body = body.replace("ሥኻዲ፡ ብርዲ፡", "ሥኻዲ ብርዲ፡", 1)
    body = body.replace("መጨጭዳዅድ …”", "መጨጭዳዅድ…”", 1)
    body = body.replace("ዎ ሕላን ኣዳምሩዅዲ", "ዎ ፈሀም ኣዳምሩዅዲ", 1)
    body = body.replace("ዎ ይጝ ናውክ ኒል", "ዎ ይን ናውክ ኒል", 1)

    final_with_colon = "\n\nዎ ዕል ራሕመቱዅ ኣኾ፡"
    final_without_colon = "\n\nዎ ዕል ራሕመቱዅ ኣኾ "
    if final_with_colon in body:
        body = body.replace(final_with_colon, final_without_colon, 1)
    elif final_without_colon not in body:
        raise SystemExit("Could not find final Divine Mercy invocation")

    acclamation = "ጃር ኒትክዲሲ ሓመድሳዅ ኣኽኒ፥ አሜን!"
    if acclamation not in body:
        body = f"{body}\n\n{acclamation}"

    section["body"] = body
    section["note"] = (
        "The complete Chaplet of Divine Mercy and litany from source pages "
        "42–47, with the booklet's repeated responses written out for reading."
    )
    visual = section.get("visuals", [])[0]
    visual["credit"] = "Catholic Eparchy of Keren · supplied source image"


def reconcile_2026_source_details(data: dict) -> None:
    creed = section_by_id(data, "creed")
    creed["body"] = replace_once(
        creed["body"],
        "ኒትክ ገረሳዅ ሰማዲ፡ ብራዲት",
        "ኒትክ ገረሳዅ ሰማዲ ብራዲት",
        "Creed punctuation",
    )
    creed["body"] = replace_once(
        creed["body"], "ክሪልድ ጔዅ", "ክሪልድ ጒዅ", "Creed character"
    )

    litany = section_by_id(data, "litany")
    litany["body"] = replace_once(
        litany["body"],
        "ኢየሱስ፡ ማርያም፡ ዮሴፍ፡ ይክሪ ሁመትሊ",
        "ኢየሱስ ማርያም ዮሴፍ፡ ይክሪ ሁመትሊ",
        "second Jesus–Mary–Joseph invocation",
    )
    litany["body"] = replace_once(
        litany["body"],
        "ኢየሱስ፡ ማርያም፡ ዮሴፍ፡ ይፊዅት ዳሕነድ",
        "ኢየሱስ ማርያም ዮሴፍ፡ ይፊዅት ዳሕነድ",
        "third Jesus–Mary–Joseph invocation",
    )

    # This is the printed heading for the complete four-prayer collection, not
    # an additional prayer. Preserve it as the collection title.
    group_by_id(data, "meals")["title"] = "ሺዋን መአዲሪዅ"


def main() -> None:
    data = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    complete_daily_prayer(section_by_id(data, "daily_blin"))
    reconcile_divine_mercy(section_by_id(data, "mercy"))
    reconcile_2026_source_details(data)
    DATA_PATH.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(
        "Reconciled the daily prayer, Divine Mercy, and final exact-source "
        "details from the supplied booklets."
    )


if __name__ == "__main__":
    main()
