#!/usr/bin/env python3
"""Import or verify the supplied Blin Nicene Creed RTF.

The RTF is treated as content, not as instructions. On macOS, ``textutil`` is
used to decode Word's Unicode RTF output without retyping the prayer.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


EXPECTED_TITLE = "ሺዋን ኣማነቱዅ ኒቅዪዅ"
SECTION_ID = "nicene_creed"


def extract_source(path: Path) -> tuple[str, str]:
    result = subprocess.run(
        ["textutil", "-convert", "txt", "-stdout", str(path)],
        check=True,
        capture_output=True,
        text=True,
    )
    lines = [line.replace("\u00a0", " ").strip() for line in result.stdout.splitlines()]
    content_lines = [line for line in lines if line]
    if not content_lines or content_lines[0] != EXPECTED_TITLE:
        found = content_lines[0] if content_lines else "<empty>"
        raise ValueError(f"Unexpected Nicene Creed title: {found}")
    body = "\n\n".join(content_lines[1:])
    if not body.startswith("ዲባ፡") or not body.endswith("አሜን።"):
        raise ValueError("The Nicene Creed body is incomplete")
    return content_lines[0], body


def expected_record(path: Path) -> dict:
    title, body = extract_source(path)
    return {
        "id": SECTION_ID,
        "title": title,
        "subtitle": "The Nicene Creed",
        "body": body,
        "note": "",
        "translation": "",
        "source_file": path.name,
        "source_sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }


def load_data(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def faith_sections(data: dict) -> list:
    for group in data.get("groups", []):
        if group.get("id") == "faith":
            sections = group.get("sections")
            if isinstance(sections, list):
                return sections
    raise ValueError("The faith group is missing from app data")


def write_json(path: Path, value: object) -> None:
    rendered = json.dumps(value, ensure_ascii=False, indent=2) + "\n"
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", dir=path.parent, delete=False
    ) as temp:
        temp.write(rendered)
        temp_path = Path(temp.name)
    temp_path.replace(path)


def apply_import(data_path: Path, record: dict) -> None:
    data = load_data(data_path)
    sections = faith_sections(data)
    sections[:] = [section for section in sections if section.get("id") != SECTION_ID]
    apostles_index = next(
        (index for index, section in enumerate(sections) if section.get("id") == "creed"),
        -1,
    )
    sections.insert(apostles_index + 1 if apostles_index >= 0 else 0, record)
    write_json(data_path, data)
    print(f"Imported the Nicene Creed into {data_path}")


def check_import(data_path: Path, record: dict) -> None:
    sections = faith_sections(load_data(data_path))
    matches = [section for section in sections if section.get("id") == SECTION_ID]
    if matches != [record]:
        raise ValueError("The app Nicene Creed does not exactly match the supplied RTF")
    ids = [section.get("id") for section in sections]
    if ids.index(SECTION_ID) != ids.index("creed") + 1:
        raise ValueError("The Nicene Creed is not immediately after the Apostles’ Creed")
    print("Nicene Creed source check passed")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("--data", type=Path, default=Path("assets/data.json"))
    parser.add_argument("--write", action="store_true")
    args = parser.parse_args()

    record = expected_record(args.source)
    if args.write:
        apply_import(args.data, record)
    else:
        check_import(args.data, record)


if __name__ == "__main__":
    main()
