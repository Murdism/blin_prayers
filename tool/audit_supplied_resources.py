#!/usr/bin/env python3
"""Run the final reproducible audit for all five user-supplied resources."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
import tempfile
import unicodedata
import zipfile
from pathlib import Path
from xml.etree import ElementTree


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tool"))

import import_queen_of_peace as queen  # noqa: E402
import import_way_of_cross as way  # noqa: E402


EXPECTED_HASHES = {
    "አውኒ መሀድዅንና 2026.pdf": (
        "9a6982b400745e65be04d5eb951ba0550d6b2b8a511c92e5ac25c3ba003e8943"
    ),
    "ፊዅሰን መስቀሉ.pdf": way.EXPECTED_SHA256,
    "ጊመት ሰላምሪ.pdf": queen.EXPECTED_SHA256,
    "Our Father.docx": (
        "596784702c95191d8cf1b7105caf90b01fdb5520201c2aee2e5a73e691e35696"
    ),
    "ኢየሱስ.jpg": (
        "7f08dd10a73dad5a1f471f103f3f07a9a4dce8c252704dde91d520d52f782193"
    ),
}


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def section_by_id(data: dict, section_id: str) -> dict:
    matches = [
        section
        for group in data["groups"]
        for section in group["sections"]
        if section.get("id") == section_id
    ]
    if len(matches) != 1:
        raise RuntimeError(f"Expected one section {section_id!r}; found {len(matches)}")
    return matches[0]


def group_by_id(data: dict, group_id: str) -> dict:
    matches = [group for group in data["groups"] if group.get("id") == group_id]
    if len(matches) != 1:
        raise RuntimeError(f"Expected one group {group_id!r}; found {len(matches)}")
    return matches[0]


def compact(text: str) -> str:
    return "".join(unicodedata.normalize("NFC", text).split())


def docx_text(path: Path) -> str:
    namespace = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"
    with zipfile.ZipFile(path) as archive:
        root = ElementTree.fromstring(archive.read("word/document.xml"))
    paragraphs = []
    for paragraph in root.iter(f"{namespace}p"):
        value = "".join(node.text or "" for node in paragraph.iter(f"{namespace}t"))
        if value.strip():
            paragraphs.append(value)
    return "\n".join(paragraphs)


def check_hashes(source_dir: Path) -> dict[str, Path]:
    resources: dict[str, Path] = {}
    for filename, expected in EXPECTED_HASHES.items():
        path = source_dir / filename
        if not path.is_file():
            raise RuntimeError(f"Missing supplied resource: {path}")
        actual = digest(path)
        if actual != expected:
            raise RuntimeError(f"Checksum mismatch for {filename}: {actual}")
        resources[filename] = path
    return resources


def check_way(data: dict, pdf: Path) -> None:
    expected_sections = way.build_sections(way.extract_pages(pdf))
    if group_by_id(data, "way")["sections"] != expected_sections:
        raise RuntimeError("Way of the Cross text or metadata differs from its source")

    runtime_dir = ROOT / "assets" / "images" / "way_of_cross_2025"
    runtime_names = [f"station_{number:02d}.jpg" for number in range(1, 15)]
    runtime_names.append("resurrection.jpg")
    with tempfile.TemporaryDirectory(prefix="final-way-audit-") as temp_dir:
        extracted_dir = Path(temp_dir)
        way.extract_images(pdf, extracted_dir)
        for filename in runtime_names:
            if digest(extracted_dir / filename) != digest(runtime_dir / filename):
                raise RuntimeError(f"Way of the Cross image differs: {filename}")


def check_queen(data: dict, pdf: Path) -> None:
    expected = {**queen.SECTION, "body": queen.extract_body(pdf)}
    if section_by_id(data, "queen_of_peace") != expected:
        raise RuntimeError("Queen of Peace differs from its source")


def check_standard_prayers(data: dict, docx: Path) -> None:
    app_text = section_by_id(data, "daily_blin2")["body"]
    source_text = docx_text(docx)
    if compact(source_text) != compact(app_text):
        raise RuntimeError("Our Father DOCX differs from the standard-prayer section")


def check_supplied_image(jpeg: Path) -> None:
    runtime = ROOT / "assets" / "images" / "source_2026" / "divine_mercy.jpg"
    if jpeg.read_bytes() != runtime.read_bytes():
        raise RuntimeError("Runtime Divine Mercy image is not the exact supplied JPEG")


def check_final_2026_details(data: dict) -> None:
    creed = section_by_id(data, "creed")["body"]
    if "ኒትክ ገረሳዅ ሰማዲ ብራዲት" not in creed or "ክሪልድ ጒዅ" not in creed:
        raise RuntimeError("Final page-8 Creed details are not reconciled")

    litany = section_by_id(data, "litany")["body"]
    endings = (
        "ኢየሱስ ማርያም ዮሴፍ፡ ይክሪ ሁመትሊ",
        "ኢየሱስ ማርያም ዮሴፍ፡ ይፊዅት ዳሕነድ",
    )
    if any(value not in litany for value in endings):
        raise RuntimeError("Final page-28 Marian-litany punctuation is not reconciled")
    if group_by_id(data, "meals")["title"] != "ሺዋን መአዲሪዅ":
        raise RuntimeError("The complete page-36 meal-prayer heading is missing")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source_dir", type=Path, help="Directory containing all five sources")
    args = parser.parse_args()

    resources = check_hashes(args.source_dir.resolve())
    data = json.loads((ROOT / "assets" / "data.json").read_text(encoding="utf-8"))

    check_way(data, resources["ፊዅሰን መስቀሉ.pdf"])
    check_queen(data, resources["ጊመት ሰላምሪ.pdf"])
    check_standard_prayers(data, resources["Our Father.docx"])
    check_supplied_image(resources["ኢየሱስ.jpg"])
    check_final_2026_details(data)
    subprocess.run([sys.executable, str(ROOT / "tool" / "validate_divine_mercy.py")], check=True)

    print("Final supplied-resource audit passed:")
    print("- all 5 resource checksums match")
    print("- all 16 Way sections and all 15 Way images match")
    print("- all 7 Queen of Peace stanzas match")
    print("- the DOCX and standard-prayer wording match")
    print("- the runtime Divine Mercy JPEG is byte-identical to the supplied image")
    print("- the final 2026 Creed, Marian-litany, and meal-heading details match")


if __name__ == "__main__":
    main()
