#!/usr/bin/env python3
"""Validate source-sensitive invariants used by the Divine Mercy reader."""

from __future__ import annotations

import json
import hashlib
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATA_PATH = ROOT / "assets" / "data.json"

LITANY_HEADING = "ራሕመት መለኮቱዅሊ ሱኵራዅ ጅኝጃን"
THREE_OCLOCK_MARKER = "\n(ግርግ"
CLOSING_MARKER = "\n\nዎ ዕል ራሕመቱዅ ኣኾ"
FINAL_PRAYER_MARKER = "\nሺውኒን\n"
SUPPLIED_IMAGE_SHA256 = (
    "7f08dd10a73dad5a1f471f103f3f07a9a4dce8c252704dde91d520d52f782193"
)
RESPONSE = re.compile(
    r"(ረሓሚና|ራሓሚና|ሰኸንቲና|ሺዊልና|ዋሲና|ሸኑሪና|መሓሪና|"
    r"ኵል እምነኵን|ብሕል ዪና)[።፥፣]?$"
)


def fail(message: str) -> None:
    raise SystemExit(f"Divine Mercy validation failed: {message}")


def section_by_id(data: dict, section_id: str) -> dict:
    matches = [
        section
        for group in data["groups"]
        for section in group["sections"]
        if section.get("id") == section_id
    ]
    if len(matches) != 1:
        fail(f"expected one {section_id!r} section, found {len(matches)}")
    return matches[0]


def litany_row_count(text: str) -> int:
    litany_start = text.find(f"\n\n{LITANY_HEADING}")
    if litany_start < 0:
        fail("litany heading boundary is missing")
    remainder = text[litany_start + 2 :].strip()
    closing_start = remainder.rfind(CLOSING_MARKER)
    if closing_start < 0:
        fail("final invocation boundary is missing")
    litany = remainder[:closing_start].strip()
    final_prayer_start = litany.find(FINAL_PRAYER_MARKER)
    if final_prayer_start < 0:
        fail("litany closing-prayer boundary is missing")

    lines = litany[:final_prayer_start].splitlines()[1:]
    rows: list[str] = []
    buffer = ""
    for raw_line in lines:
        line = raw_line.strip()
        if not line:
            continue
        buffer = line if not buffer else f"{buffer} {line}"
        if RESPONSE.search(buffer):
            rows.append(buffer)
            buffer = ""
    if buffer:
        fail(f"unresolved litany text: {buffer!r}")
    if any(RESPONSE.search(row) is None for row in rows):
        fail("a parsed litany row has no recognized response")
    return len(rows)


def main() -> None:
    data = json.loads(DATA_PATH.read_text(encoding="utf-8"))
    mercy = section_by_id(data, "mercy")
    body = mercy.get("body", "").strip()

    litany_start = body.find(f"\n\n{LITANY_HEADING}")
    if litany_start < 0:
        fail("litany heading is missing")
    instruction_block = body[:litany_start]
    three_start = instruction_block.find(THREE_OCLOCK_MARKER)
    if three_start < 0:
        fail("3 o'clock prayer boundary is missing")
    step_block = instruction_block[:three_start]
    step_matches = list(re.finditer(r"(?m)^(\d{1,2})\.\s*", step_block))
    step_numbers = [match.group(1) for match in step_matches]
    if step_numbers != [str(number) for number in range(1, 11)]:
        fail(f"expected numbered steps 1–10, found {step_numbers}")
    step_bodies = [
        step_block[
            match.end() : (
                step_matches[index + 1].start()
                if index + 1 < len(step_matches)
                else len(step_block)
            )
        ].strip()
        for index, match in enumerate(step_matches)
    ]
    complete_prayer_minimums = ((1, 150), (2, 200), (3, 350))
    if any(
        len(step_bodies[index]) < minimum
        for index, minimum in complete_prayer_minimums
    ):
        fail("one or more complete prayers in steps 2–4 is abbreviated")

    rows = litany_row_count(body)
    if rows != 47:
        fail(f"expected 47 litany rows, found {rows}")

    if "ዎ ፎስቲና ሻትኪ" not in body or "(ፎስቲና ሻትኪ)" not in body:
        fail("Saint Faustina invocation or source reflection is missing")
    if "ጃር ኒትክዲሲ ሓመድሳዅ ኣኽኒ፥ አሜን!" not in body:
        fail("page-47 final acclamation is missing")

    authoritative_variants = (
        "እንታኽራኽር",
        "ክሪ ወክትዲትል",
        "ኩኡዅራ",
        "ክሪልድ ጒዅ",
        "ዎ ፈሀም ኣዳምሩዅዲ",
        "ዎ ይን ናውክ ኒል",
    )
    missing_variants = [text for text in authoritative_variants if text not in body]
    if missing_variants:
        fail(f"authoritative booklet wording is missing: {missing_variants}")
    visuals = mercy.get("visuals", [])
    if len(visuals) != 1 or visuals[0].get("source_page") != 29:
        fail("expected one supplied visual with its matching page-29 reference")
    visual_path = ROOT / visuals[0].get("asset", "")
    if not visual_path.is_file():
        fail(f"visual asset does not exist: {visual_path}")
    visual_hash = hashlib.sha256(visual_path.read_bytes()).hexdigest()
    if visual_hash != SUPPLIED_IMAGE_SHA256:
        fail("runtime image does not match the supplied authoritative JPEG")

    daily = section_by_id(data, "daily_blin").get("body", "")
    if daily.count("አሜን።") < 2 or "ዎ ማርያም ኣዳምር ሓራም" not in daily:
        fail("the complete page-6 daily prayer sequence is missing")

    print(
        "Divine Mercy validation passed: "
        "4 stages, 10 complete chaplet steps, 47 litany rows, the page-47 "
        "acclamation, the complete page-6 daily prayer, and the supplied image."
    )


if __name__ == "__main__":
    main()
