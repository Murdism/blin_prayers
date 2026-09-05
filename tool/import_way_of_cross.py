#!/usr/bin/env python3
"""Import the reviewed Way of the Cross source into the runtime content.

The source is text-native. Text is extracted with pdftotext, running headers and
page numbers are removed, the devotion is split into preparation, fourteen
stations, and a conclusion, and the original JPEGs are copied without
recompression. The printed abbreviations for the prayers repeated at every
station are expanded from the complete first-station text for phone reading.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import subprocess
import tempfile
from pathlib import Path


EXPECTED_SHA256 = "a2b349993ef66d63dd34a888f9ed55398a028a87ac486769c442fa9887712f68"
BOOK_HEADER = "ፊዅሰን መስቀሉ"
SOURCE_CREDIT = "Catholic Eparchy of Keren · ፊዅሰን መስቀሉ (2025)"

STATIONS = [
    ("ሰልፋ ፊዅሰና", "Jesus is condemned to death", 11, 10),
    ("ሊጘር ፊዅሰና", "Jesus takes up his cross", 15, 14),
    ("ሲዀር ፊዅሰና", "Jesus falls for the first time", 17, 16),
    ("ሰጀር ፊዅሰና", "Jesus meets his mother", 19, 18),
    ("አⶖኰር ፊዅሰና", "Simon of Cyrene helps Jesus carry the cross", 21, 20),
    ("ወልተር ፊዅሰና", "Veronica wipes the face of Jesus", 23, 22),
    ("ለጘተር ፊዅሰና", "Jesus falls for the second time", 25, 24),
    ("ሰዀተር ፊዅሰና", "Jesus meets the women of Jerusalem", 27, 26),
    ("ሰሰር ፊዅሰና", "Jesus falls for the third time", 29, 28),
    ("ሽከር ፊዅሰና", "Jesus is stripped of his garments", 31, 30),
    ("ሽካ ላዅ ፊዅሰና", "Jesus is nailed to the cross", 33, 32),
    ("ሽካ ሊጘር ፊዅሰና", "Jesus dies on the cross", 35, 34),
    ("ሽካ ሲዀር ፊዅሰና", "Jesus is taken down from the cross", 37, 36),
    ("ሽካ ሰጀር ፊዅሰና", "Jesus is laid in the tomb", 39, 38),
]


def source_hash(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for block in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def extract_pages(pdf: Path) -> list[str]:
    result = subprocess.run(
        ["pdftotext", "-enc", "UTF-8", str(pdf), "-"],
        check=True,
        capture_output=True,
        text=True,
    )
    pages = result.stdout.split("\f")
    if len(pages) < 47:
        raise RuntimeError(f"Expected 47 PDF pages; extracted {len(pages)}")
    return pages


def clean_page(pages: list[str], page_number: int) -> str:
    lines = pages[page_number - 1].splitlines()
    removed_header = False
    removed_number = False
    cleaned: list[str] = []

    for line in lines:
        value = line.strip()
        if not removed_number and value == str(page_number):
            removed_number = True
            continue
        if not removed_header and value == BOOK_HEADER:
            removed_header = True
            continue
        cleaned.append(value)

    while cleaned and not cleaned[0]:
        cleaned.pop(0)
    while cleaned and not cleaned[-1]:
        cleaned.pop()

    compact: list[str] = []
    for line in cleaned:
        if line or (compact and compact[-1]):
            compact.append(line)
    return "\n".join(compact).strip()


def without_heading(body: str, heading: str) -> str:
    lines = body.splitlines()
    if not lines or lines[0] != heading:
        raise RuntimeError(f"Expected heading {heading!r}, found {lines[:1]!r}")
    return "\n".join(lines[1:]).lstrip()


def restore_station_response_spacing(body: str) -> str:
    """Preserve the paragraph break printed after the station response."""
    response = "መ፡ ዎ ይና አደራ\nዲባ፡ ረሓሚና።"
    marian_prayer = "ዎ ይገና ማርያም ሻትኪ፡"
    compact = f"{response}\n{marian_prayer}"
    if compact not in body:
        raise RuntimeError("Could not locate the station response and Marian prayer")
    return body.replace(compact, f"{response}\n\n{marian_prayer}", 1)


def visual(asset: str, page: int, alt: str, caption: str) -> dict[str, object]:
    return {
        "asset": asset,
        "role": "hero",
        "source_page": page,
        "alt": alt,
        "caption": caption,
        "credit": SOURCE_CREDIT,
    }


def build_sections(pages: list[str]) -> list[dict[str, object]]:
    preparation = "\n\n".join(clean_page(pages, page) for page in (7, 8, 9))
    preparation = without_heading(preparation, BOOK_HEADER)

    first_station = "\n\n".join(clean_page(pages, page) for page in (11, 12, 13))
    first_station = without_heading(first_station, STATIONS[0][0])
    first_station = restore_station_response_spacing(first_station)

    common_start = first_station.find("ይና እኽር ሰሚል መንደርትራኽር")
    gospel_start = first_station.find("ሉቃስር ኪሠሪር ብሽራት 23፡ 18-49")
    if common_start < 0 or gospel_start <= common_start:
        raise RuntimeError("Could not locate the complete repeated station prayers")
    common_prayers = first_station[common_start:gospel_start].strip()

    sections: list[dict[str, object]] = [
        {
            "id": "wayofcross",
            "title": BOOK_HEADER,
            "subtitle": "Preparation and Gospel · Source pages 7–9",
            "note": (
                "Preparation for the Way of the Cross: the profession of faith, "
                "devotional acts, prayer before the altar, and Luke 23:1–17."
            ),
            "translation": "",
            "body": preparation,
        }
    ]

    for index, (title, english, text_page, image_page) in enumerate(STATIONS, 1):
        if index == 1:
            body = first_station
        else:
            body = without_heading(clean_page(pages, text_page), title)
            repeat_start = body.find("ይና እኽር ሰሚል መንደርትራኽር")
            if repeat_start < 0:
                raise RuntimeError(f"Could not locate repeated prayers for station {index}")
            body = f"{body[:repeat_start].rstrip()}\n{common_prayers}"

        asset = f"assets/images/way_of_cross_2025/station_{index:02d}.jpg"
        sections.append(
            {
                "id": f"way_station_{index:02d}",
                "title": title,
                "subtitle": f"Station {index} · {english}",
                "note": f"Station {index} of the Way of the Cross: {english}.",
                "translation": "",
                "body": body,
                "visuals": [
                    visual(
                        asset,
                        image_page,
                        f"Station {index}: {english}.",
                        f"Station {index} · {english}",
                    )
                ],
            }
        )

    conclusion_title = "ዓይብድኒ/እብርኒ ሺዋን"
    conclusion = without_heading(clean_page(pages, 41), conclusion_title)
    sections.append(
        {
            "id": "way_conclusion",
            "title": conclusion_title,
            "subtitle": "Concluding prayer and Philippians 2:6–12",
            "note": (
                "The Way of the Cross conclusion: a prayer, the reading from "
                "Philippians 2:6–12, and a final prayer."
            ),
            "translation": "",
            "body": conclusion,
            "visuals": [
                visual(
                    "assets/images/way_of_cross_2025/resurrection.jpg",
                    40,
                    (
                        "The risen Christ holding the cross, surrounded by scenes "
                        "from his Passion and Resurrection."
                    ),
                    "The Resurrection and the saving work of Christ",
                )
            ],
        }
    )
    return sections


def extract_images(pdf: Path, destination: Path) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="way-of-cross-") as temp_dir:
        prefix = Path(temp_dir) / "visual"
        subprocess.run(["pdfimages", "-j", str(pdf), str(prefix)], check=True)
        images = sorted(Path(temp_dir).glob("visual-*.jpg"))
        if len(images) != 15:
            raise RuntimeError(f"Expected 15 JPEGs; extracted {len(images)}")

        for index, image in enumerate(images[:14], 1):
            shutil.copyfile(image, destination / f"station_{index:02d}.jpg")
        shutil.copyfile(images[14], destination / "resurrection.jpg")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("pdf", type=Path, help="Path to ፊዅሰን መስቀሉ.pdf")
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()

    pdf = args.pdf.resolve()
    actual_hash = source_hash(pdf)
    if actual_hash != EXPECTED_SHA256:
        raise RuntimeError(
            "The supplied PDF is not the audited source: "
            f"expected {EXPECTED_SHA256}, found {actual_hash}"
        )

    repo = args.repo.resolve()
    data_path = repo / "assets" / "data.json"
    with data_path.open(encoding="utf-8") as source:
        data = json.load(source)

    way_group = next((group for group in data["groups"] if group["id"] == "way"), None)
    if way_group is None:
        raise RuntimeError("Could not find the Way of the Cross group")
    way_group["sections"] = build_sections(extract_pages(pdf))

    extract_images(pdf, repo / "assets" / "images" / "way_of_cross_2025")

    encoded = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    temporary = data_path.with_suffix(".json.importing")
    temporary.write_text(encoded, encoding="utf-8")
    temporary.replace(data_path)
    print(
        "Imported 1 preparation, 14 stations, 1 conclusion, and 15 original images."
    )


if __name__ == "__main__":
    main()
