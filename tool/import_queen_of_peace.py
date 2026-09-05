#!/usr/bin/env python3
"""Checksum-verify and import the one-page Queen of Peace prayer PDF."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path


EXPECTED_SHA256 = "0fcf37c5d7850e1e1e0a16cbff25f87132132b7acf10359a9bc95c2b3e20f965"
TITLE = "ይና ገና ማርያም ጊመት ሰላምሪ"
STANZA_LINE_COUNTS = (5, 3, 4, 3, 3, 3, 3)

SECTION = {
    "id": "queen_of_peace",
    "title": TITLE,
    "subtitle": "Mary, Queen of Peace",
    "note": (
        "A seven-stanza Marian devotional prayer supplied in a one-page "
        "text-native PDF. The English title is an editorial rendering of the "
        "Blin title; no verified full English translation is available."
    ),
    "translation": "",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def extract_body(pdf: Path) -> str:
    result = subprocess.run(
        ["pdftotext", "-layout", "-enc", "UTF-8", str(pdf), "-"],
        check=True,
        capture_output=True,
        text=True,
    )
    lines = [line.strip() for line in result.stdout.splitlines() if line.strip()]
    if not lines or lines[0] != TITLE:
        raise SystemExit("Unexpected or missing Queen of Peace title")
    prayer_lines = lines[1:]
    if len(prayer_lines) != sum(STANZA_LINE_COUNTS):
        raise SystemExit(
            f"Expected {sum(STANZA_LINE_COUNTS)} prayer lines; "
            f"extracted {len(prayer_lines)}"
        )

    stanzas: list[str] = []
    start = 0
    for line_count in STANZA_LINE_COUNTS:
        end = start + line_count
        stanzas.append("\n".join(prayer_lines[start:end]))
        start = end
    return "\n\n".join(stanzas)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("pdf", type=Path)
    parser.add_argument(
        "--write",
        action="store_true",
        help="update assets/data.json; without this flag, only verify",
    )
    args = parser.parse_args()

    actual_hash = sha256(args.pdf)
    if actual_hash != EXPECTED_SHA256:
        raise SystemExit(
            f"Source checksum mismatch: expected {EXPECTED_SHA256}, got {actual_hash}"
        )

    body = extract_body(args.pdf)
    data_path = Path(__file__).resolve().parents[1] / "assets" / "data.json"
    data = json.loads(data_path.read_text(encoding="utf-8"))
    rosary = next(group for group in data["groups"] if group["id"] == "rosary")
    sections = rosary["sections"]
    existing = next(
        (section for section in sections if section["id"] == SECTION["id"]), None
    )
    imported = {**SECTION, "body": body}

    if not args.write:
        if existing != imported:
            raise SystemExit(
                "Source is valid, but assets/data.json does not match the import"
            )
        print("Queen of Peace source and app section match exactly: 7 stanzas.")
        return

    if existing is None:
        litany_index = next(
            index for index, section in enumerate(sections) if section["id"] == "litany"
        )
        sections.insert(litany_index, imported)
    else:
        existing.clear()
        existing.update(imported)
    data_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print("Imported Queen of Peace: 7 stanzas into p_queen_of_peace.")


if __name__ == "__main__":
    main()
