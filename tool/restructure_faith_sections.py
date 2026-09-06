#!/usr/bin/env python3
"""Split the faith collection into two Creeds and four devotional Acts.

This is a structure-only migration. It moves the existing Act of Faith out of
the Apostles' Creed record and splits the three existing Acts without changing
their source wording.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
import tempfile


EXPECTED_IDS = (
    "creed",
    "nicene_creed",
    "act_faith",
    "acts",
    "act_charity",
    "act_contrition",
)

ACTS = (
    ("act_faith", "ሺዋን ኣማነቱዅ", "Act of Faith"),
    ("acts", "ሺዋን ሳዲዅ", "Act of Hope"),
    ("act_charity", "ሺዋን እጝከሊሩዅ", "Act of Charity"),
    ("act_contrition", "ሺዋን ጥዕሱዅ", "Act of Contrition"),
)


def faith_group(data: dict) -> dict:
    matches = [group for group in data["groups"] if group.get("id") == "faith"]
    if len(matches) != 1:
        raise ValueError(f"Expected one faith group; found {len(matches)}")
    return matches[0]


def split_at_headings(body: str, headings: tuple[str, ...]) -> list[str]:
    starts = [body.find(heading) for heading in headings]
    if starts[0] != 0 or any(start < 0 for start in starts):
        raise ValueError("Could not find all source Act headings")
    return [
        body[start : starts[index + 1] if index + 1 < len(starts) else None].strip()
        for index, start in enumerate(starts)
    ]


def migrate(data: dict) -> None:
    group = faith_group(data)
    sections = group["sections"]
    ids = tuple(section.get("id") for section in sections)
    if ids == EXPECTED_IDS:
        return
    if ids != ("creed", "nicene_creed", "acts"):
        raise ValueError(f"Unexpected faith section order: {ids}")

    creed, nicene, combined_acts = sections
    act_faith_marker = "\nሺዋን ኣማነቱዅ\n"
    act_faith_start = creed["body"].find(act_faith_marker)
    if act_faith_start < 0:
        raise ValueError("Could not separate the Act of Faith from the Apostles' Creed")

    apostles_body = creed["body"][:act_faith_start].strip()
    act_faith_body = creed["body"][act_faith_start + 1 :].strip()
    remaining_acts = split_at_headings(
        combined_acts["body"], tuple(heading for _, heading, _ in ACTS[1:])
    )

    creed.update(
        {
            "title": "ሺዋን ኣማነቱዅ ኢየሱስር ታለይቱት ድሪስናዅ",
            "subtitle": "The Apostles’ Creed",
            "body": apostles_body,
            "note": "The Apostles’ Creed.",
        }
    )
    act_bodies = [act_faith_body, *remaining_acts]
    split_acts = [
        {
            "id": section_id,
            "title": title,
            "subtitle": subtitle,
            "body": body,
            "note": "",
            "translation": "",
        }
        for (section_id, title, subtitle), body in zip(ACTS, act_bodies)
    ]
    group["en"] = "Creeds & Acts"
    group["sections"] = [creed, nicene, *split_acts]


def validate(data: dict) -> None:
    group = faith_group(data)
    sections = group["sections"]
    ids = tuple(section.get("id") for section in sections)
    if ids != EXPECTED_IDS:
        raise ValueError(f"Faith sections do not match the intended structure: {ids}")
    if group.get("en") != "Creeds & Acts":
        raise ValueError("Faith collection English label is incorrect")
    if sections[0].get("subtitle") != "The Apostles’ Creed":
        raise ValueError("Apostles' Creed label is incorrect")
    for section, (_, heading, subtitle) in zip(sections[2:], ACTS):
        if section.get("title") != heading or section.get("subtitle") != subtitle:
            raise ValueError(f"Incorrect Act record: {section.get('id')}")
        if not section.get("body", "").startswith(heading + "\n"):
            raise ValueError(f"Act body does not retain its heading: {heading}")


def write_json(path: Path, data: dict) -> None:
    rendered = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=path.parent, delete=False
    ) as temporary:
        temporary.write(rendered)
        temporary_path = Path(temporary.name)
    temporary_path.replace(path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", type=Path, default=Path("assets/data.json"))
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    data = json.loads(args.data.read_text(encoding="utf-8"))
    if args.write:
        migrate(data)
        validate(data)
        write_json(args.data, data)
        print(f"Restructured the Faith collection in {args.data}")
    else:
        validate(data)
        print("Faith collection structure check passed")


if __name__ == "__main__":
    main()
