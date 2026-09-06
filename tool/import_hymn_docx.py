#!/usr/bin/env python3
"""Preview or import the reviewed DOCX hymn collection.

The DOCX files are content sources. Text before the hymn may be retained as a
Scripture introduction, while trailing authorship/music lines are stored as
credits rather than lyrics. Refrains are configured from the passages that
the source provider identified through bold or contrasting text formatting.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from dataclasses import dataclass
from datetime import date
from pathlib import Path
import re
import tempfile
import xml.etree.ElementTree as ET
import zipfile


WORD_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
W = f"{{{WORD_NS}}}"


@dataclass(frozen=True)
class HymnSource:
    source_file: str
    title: str
    stable_id: str
    intro_count: int = 0
    document_title: str = ""
    verse_line_counts: tuple[int, ...] = ()
    refrain_blocks: tuple[tuple[str, int], ...] = ()
    refrain_part_line_counts: tuple[tuple[str, tuple[int, ...]], ...] = ()


# The order follows the order in which the source provider supplied the files.
SOURCES = (
    HymnSource(
        "ጐና ፈርኖ.docx",
        "ጐና ፈርኖ",
        "h_docx_2026_01",
        intro_count=1,
        document_title="ጐና ፈርኖ ቤተልሔም",
        refrain_blocks=(
            ("ጐና ፈርኖ ቤተልሔም ጐና ፈርኖ", 5),
            ("ለዃ ቤተልሔም ፈርንን፥ ለዃ ፈርንን", 5),
        ),
    ),
    HymnSource(
        "ፋጅኻ ፋጅኻ ኤልያስ.docx",
        "ፋጅኻ",
        "h_docx_2026_02",
        refrain_blocks=(("ፋጅኻ (2)", 3),),
    ),
    HymnSource(
        "ጥዒሰኵን.docx",
        "ጥዒሰኵን",
        "h_docx_2026_03",
        refrain_blocks=(("ጥዒሰኵን ኣን ደኵሰውድ", 13),),
        # One refrain, with three source-color movements: red, blue, green.
        refrain_part_line_counts=(("ጥዒሰኵን ኣን ደኵሰውድ", (3, 3, 7)),),
    ),
    HymnSource(
        "ገና መእኰትሪ (ሓሸላ).docx",
        "ገና መእኰትሪ",
        "h_docx_2026_04",
        verse_line_counts=(5, 5, 5, 5, 5),
        refrain_blocks=(("ማርያም ይን ሸተክኖ፥ ካቢና ሪሕ አርኖ", 5),),
    ),
    HymnSource(
        "ዮሓንስ ሻትክ.docx",
        "ዮሓንስ ሻትክ",
        "h_docx_2026_05",
        refrain_blocks=(("ነበዋትልድ በሀር ጃር ጋባ በሸርዳዅ", 7),),
    ),
    HymnSource(
        "ይና ገና ማርያም.docx",
        "ይና ገና ማርያም",
        "h_docx_2026_06",
        refrain_blocks=(("ይና ገና ማርያም ካቢና", 3),),
    ),
    HymnSource("ዎ ይአደራ.docx", "ዎ ይአደራ", "h_docx_2026_07"),
    HymnSource(
        "ራሕመት እኽር.docx",
        "ራሕመት እኽር",
        "h_docx_2026_08",
        verse_line_counts=(4, 4, 4, 4),
        refrain_blocks=(("ዎ ራሕመትድ ኒአደራ እኽር ርሑም ረሓመንታ", 2),),
    ),
    HymnSource(
        "ኢየሱስ ክሪልድ ጒዅ.docx",
        "ኢየሱስ ክሪልድ ጒዅ",
        "h_docx_2026_09",
        intro_count=1,
        refrain_blocks=(("ግናይዲ በሀርዲ ፈርሕንን እልልንን", 4),),
    ),
    HymnSource(
        "ሆሳዕና.docx",
        "ሆሳዕና",
        "h_docx_2026_10",
        refrain_blocks=(("ጊም ሰሚዅ ዎ ኢየሱስ ሆሳዕና", 3),),
    ),
    HymnSource(
        "ኪርየ ኤለይሶን.docx",
        "ኪርየ ኤለይሶን",
        "h_docx_2026_11",
        refrain_blocks=(("ኪርየ ኤለይሶን - ዎ ይና አደራ ራሓሚና", 7),),
    ),
    HymnSource(
        "ውሪዃ ኒልድ ሲርነ.docx",
        "ውሪዃ ኒልድ ሲርነ",
        "h_docx_2026_12",
        refrain_blocks=(("ውሪዃ ኒልድ ሲርነ ሓሰብንን ሓሰብንን", 2),),
    ),
)

CREDIT_PREFIXES = (
    "ላሕማ",
    "ሒን",
    "ሻሎት",
)


def combine_credit_continuations(credits: list[str]) -> list[str]:
    """Keep an attribution label and its following name in one credit."""
    combined: list[str] = []
    for credit in credits:
        if combined and not credit.startswith(CREDIT_PREFIXES):
            combined[-1] = f"{combined[-1]}\n{credit}"
        else:
            combined.append(credit)
    return combined


def normalized_text(value: str) -> str:
    lines = [
        re.sub(r"[ \t]+", " ", line.replace("\u00a0", " ")).strip()
        for line in value.splitlines()
    ]
    return "\n".join(line for line in lines if line).strip()


def paragraph_text(paragraph: ET.Element) -> str:
    parts: list[str] = []
    for element in paragraph.iter():
        if element.tag == f"{W}t":
            parts.append(element.text or "")
        elif element.tag in {f"{W}br", f"{W}cr"}:
            parts.append("\n")
        elif element.tag == f"{W}tab":
            parts.append(" ")
    return normalized_text("".join(parts))


def docx_paragraphs(path: Path) -> list[str]:
    with zipfile.ZipFile(path) as archive:
        root = ET.fromstring(archive.read("word/document.xml"))
    return [
        paragraph_text(paragraph)
        for paragraph in root.findall(f".//{W}body/{W}p")
    ]


def split_content(
    source: HymnSource,
    raw_paragraphs: list[str],
) -> tuple[str, list[dict[str, str]], list[str]]:
    paragraphs = list(raw_paragraphs)
    while paragraphs and not paragraphs[0]:
        paragraphs.pop(0)
    while paragraphs and not paragraphs[-1]:
        paragraphs.pop()

    # Most documents have a standalone title. A Scripture quotation may come
    # before it, so remove only the first exact title match. The display title
    # can be shorter than the title printed in the source document.
    printed_title = source.document_title or source.title
    try:
        title_index = paragraphs.index(printed_title)
    except ValueError:
        title_index = -1
    if title_index >= 0:
        paragraphs.pop(title_index)

    intro_parts: list[str] = []
    while paragraphs and len(intro_parts) < source.intro_count:
        paragraph = paragraphs.pop(0)
        if paragraph:
            intro_parts.append(paragraph)
    while paragraphs and not paragraphs[0]:
        paragraphs.pop(0)

    credit_start = next(
        (
            index
            for index, paragraph in enumerate(paragraphs)
            if paragraph.startswith(CREDIT_PREFIXES)
        ),
        len(paragraphs),
    )
    lyric_paragraphs = paragraphs[:credit_start]
    credits = combine_credit_continuations(
        [paragraph for paragraph in paragraphs[credit_start:] if paragraph]
    )
    while lyric_paragraphs and not lyric_paragraphs[-1]:
        lyric_paragraphs.pop()

    if not any(lyric_paragraphs):
        raise ValueError(f"{source.source_file}: no lyric paragraphs found")

    lyric_groups: list[list[str]] = []
    current_group: list[str] = []
    for paragraph in lyric_paragraphs:
        if paragraph:
            current_group.extend(
                line for line in paragraph.splitlines() if line
            )
        elif current_group:
            lyric_groups.append(current_group)
            current_group = []
    if current_group:
        lyric_groups.append(current_group)

    indexed_lines = [
        (line, group_index)
        for group_index, group in enumerate(lyric_groups)
        for line in group
    ]

    # Build one ordered stream. A refrain can occur after a verse and the same
    # refrain can be printed repeatedly between verses. Preserve every source
    # occurrence rather than lifting or deduplicating it.
    refrain_by_start = dict(source.refrain_blocks)
    refrain_parts_by_start = dict(source.refrain_part_line_counts)
    unknown_part_starts = set(refrain_parts_by_start) - set(refrain_by_start)
    if unknown_part_starts:
        raise ValueError(
            f"{source.source_file}: refrain parts configured for an unknown "
            f"refrain: {next(iter(unknown_part_starts))}"
        )
    found_refrains = {start: 0 for start in refrain_by_start}
    sections: list[dict[str, str]] = []
    current_verse: list[str] = []
    current_group_index: int | None = None
    verse_count_index = 0

    def flush_verse() -> None:
        nonlocal current_verse, current_group_index, verse_count_index
        if not current_verse:
            return
        if source.verse_line_counts:
            if verse_count_index >= len(source.verse_line_counts):
                raise ValueError(
                    f"{source.source_file}: found more verses than configured"
                )
            expected = source.verse_line_counts[verse_count_index]
            if len(current_verse) != expected:
                raise ValueError(
                    f"{source.source_file}: verse {verse_count_index + 1} "
                    f"expected {expected} lines, found {len(current_verse)}"
                )
            verse_count_index += 1
        sections.append({"type": "verse", "text": "\n".join(current_verse)})
        current_verse = []
        current_group_index = None

    index = 0
    while index < len(indexed_lines):
        line, group_index = indexed_lines[index]
        refrain_line_count = refrain_by_start.get(line)
        if refrain_line_count is not None:
            flush_verse()
            end = index + refrain_line_count
            occurrence = indexed_lines[index:end]
            if len(occurrence) != refrain_line_count:
                raise ValueError(
                    f"{source.source_file}: incomplete configured refrain"
                )
            refrain_lines = [text for text, _ in occurrence]
            part_line_counts = refrain_parts_by_start.get(line, ())
            if part_line_counts:
                if sum(part_line_counts) != refrain_line_count:
                    raise ValueError(
                        f"{source.source_file}: refrain part sizes do not "
                        f"total {refrain_line_count} lines"
                    )
                parts: list[str] = []
                part_start = 0
                for part_line_count in part_line_counts:
                    part_end = part_start + part_line_count
                    parts.append("\n".join(refrain_lines[part_start:part_end]))
                    part_start = part_end
                refrain_text = "\n\n".join(parts)
            else:
                refrain_text = "\n".join(refrain_lines)
            sections.append(
                {
                    "type": "refrain",
                    "text": refrain_text,
                }
            )
            found_refrains[line] += 1
            index = end
            continue

        if (
            not source.verse_line_counts
            and current_verse
            and group_index != current_group_index
        ):
            flush_verse()
        current_verse.append(line)
        current_group_index = group_index
        if source.verse_line_counts:
            if verse_count_index >= len(source.verse_line_counts):
                raise ValueError(
                    f"{source.source_file}: found more verse text than configured"
                )
            expected = source.verse_line_counts[verse_count_index]
            if len(current_verse) == expected:
                flush_verse()
        index += 1

    flush_verse()

    missing_refrains = [
        start for start, occurrences in found_refrains.items() if occurrences == 0
    ]
    if missing_refrains:
        raise ValueError(
            f"{source.source_file}: configured refrain was not found: "
            f"{missing_refrains[0]}"
        )
    if (
        source.verse_line_counts
        and verse_count_index != len(source.verse_line_counts)
    ):
        raise ValueError(
            f"{source.source_file}: expected {len(source.verse_line_counts)} "
            f"verses, found {verse_count_index}"
        )

    return "\n\n".join(intro_parts), sections, credits


def make_hymn(number: int, source: HymnSource, source_dir: Path) -> dict:
    path = source_dir / source.source_file
    if not path.is_file():
        raise FileNotFoundError(path)
    intro, sections, credits = split_content(
        source,
        docx_paragraphs(path),
    )
    body = "\n\n".join(section["text"] for section in sections)
    return {
        "id": source.stable_id,
        "num": number,
        "title": source.title,
        "intro": intro,
        "sections": sections,
        "credits": credits,
        "needs_review": False,
        "body": body,
        "note": "",
        "translation": "",
        "source_file": source.source_file,
        "source_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def preview(hymns: list[dict]) -> None:
    for hymn in hymns:
        print(f"{hymn['num']:02d}. {hymn['title']} [{hymn['id']}]")
        if hymn["intro"]:
            print(f"    INTRO: {hymn['intro']!r}")
        verse_number = 0
        for section in hymn["sections"]:
            if section["type"] == "verse":
                verse_number += 1
                label = f"VERSE {verse_number}"
            else:
                label = "REFRAIN"
            print(f"    {label}: {section['text']!r}")
        for credit in hymn["credits"]:
            print(f"    CREDIT: {credit!r}")
        print()


def write_json(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    rendered = json.dumps(value, ensure_ascii=False, indent=2) + "\n"
    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8",
        dir=path.parent,
        delete=False,
    ) as temp:
        temp.write(rendered)
        temp_path = Path(temp.name)
    temp_path.replace(path)


def apply_import(
    data_path: Path,
    archive_path: Path,
    hymns: list[dict],
) -> None:
    data = json.loads(data_path.read_text(encoding="utf-8"))
    old_hymns = data.get("hymns")
    if not isinstance(old_hymns, list):
        raise ValueError(f"{data_path}: hymns must be a list")

    if archive_path.exists():
        archive = json.loads(archive_path.read_text(encoding="utf-8"))
        archived_hymns = archive.get("hymns")
        if not isinstance(archived_hymns, list) or len(archived_hymns) != 40:
            raise ValueError(
                f"{archive_path}: refusing to overwrite an unexpected archive"
            )
    else:
        if len(old_hymns) != 40:
            raise ValueError(
                "Expected the original 40 hymns before creating the archive; "
                f"found {len(old_hymns)}"
            )
        write_json(
            archive_path,
            {
                "status": "deprecated",
                "visible_in_app": False,
                "deprecated_on": date.today().isoformat(),
                "reason": (
                    "Preserved for reference after replacement by individually "
                    "provided DOCX hymn sources. This file is not loaded by the app."
                ),
                "hymns": old_hymns,
            },
        )

    data["hymns"] = hymns
    write_json(data_path, data)
    print(
        f"Imported {len(hymns)} hymns into {data_path}; "
        f"old collection preserved at {archive_path}"
    )


def check_import(
    data_path: Path,
    archive_path: Path,
    expected_hymns: list[dict],
) -> None:
    data = json.loads(data_path.read_text(encoding="utf-8"))
    if data.get("hymns") != expected_hymns:
        raise ValueError(
            "The app hymn data does not exactly match the supplied DOCX files"
        )
    archive = json.loads(archive_path.read_text(encoding="utf-8"))
    archived_hymns = archive.get("hymns")
    if (
        archive.get("status") != "deprecated"
        or archive.get("visible_in_app") is not False
        or not isinstance(archived_hymns, list)
        or len(archived_hymns) != 40
    ):
        raise ValueError("The deprecated 40-hymn archive is incomplete")
    print(
        "Hymn source check passed: 12 DOCX hymns match the app and "
        "40 deprecated hymns remain archived outside the app."
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_dir", type=Path)
    parser.add_argument(
        "--data",
        type=Path,
        default=Path("assets/data.json"),
    )
    parser.add_argument(
        "--archive",
        type=Path,
        default=Path("docs/old/old_songs.json"),
    )
    action = parser.add_mutually_exclusive_group()
    action.add_argument(
        "--apply",
        action="store_true",
        help="Archive the current collection and replace the app-visible hymns.",
    )
    action.add_argument(
        "--check",
        action="store_true",
        help="Verify the app data and deprecated archive against the sources.",
    )
    args = parser.parse_args()

    hymns = [
        make_hymn(number, source, args.source_dir)
        for number, source in enumerate(SOURCES, start=1)
    ]
    if args.apply:
        apply_import(args.data, args.archive, hymns)
    elif args.check:
        check_import(args.data, args.archive, hymns)
    else:
        preview(hymns)


if __name__ == "__main__":
    main()
