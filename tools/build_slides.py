#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent#.parent
LABS_DIR = ROOT / "labs"
OUTPUT = ROOT / "slides.md"

MARP_HEADER = """---
marp: true
theme: default
paginate: true
size: 16:9
---

# Kubernetes and Containers Intro

Hands-on training
"""

H1_RE = re.compile(r"^#\s+(.+?)\s*$", re.MULTILINE)
H2_RE = re.compile(r"^##\s+(.+?)\s*$", re.MULTILINE)


def find_readmes(base: Path) -> list[Path]:
    return sorted(p for p in base.rglob("README.md") if p.is_file())


def clean_text(text: str) -> str:
    text = text.strip()
    lines = text.splitlines()

    cleaned: list[str] = []
    prev_blank = False

    for line in lines:
        blank = not line.strip()
        if blank and prev_blank:
            continue
        cleaned.append(line.rstrip())
        prev_blank = blank

    return "\n".join(cleaned).strip()


def parse_readme(content: str) -> dict | None:
    h1_match = H1_RE.search(content)
    if not h1_match:
        return None

    title = h1_match.group(1).strip()
    start_after_h1 = h1_match.end()

    h2_matches = list(H2_RE.finditer(content))

    intro_end = h2_matches[0].start() if h2_matches else len(content)
    intro = clean_text(content[start_after_h1:intro_end])

    slides: list[dict[str, str]] = []

    for i, match in enumerate(h2_matches):
        section_title = match.group(1).strip()
        section_start = match.end()
        section_end = h2_matches[i + 1].start() if i + 1 < len(h2_matches) else len(content)
        section_body = clean_text(content[section_start:section_end])

        slides.append({
            "title": section_title,
            "body": section_body,
        })

    return {
        "title": title,
        "intro": intro,
        "slides": slides,
    }


def make_title_slide(title: str, relpath: Path) -> str:
    return f"""---

# {title}

`{relpath.as_posix()}`
"""


def make_intro_slide(title: str, intro: str) -> str:
    body = intro if intro else "_No introduction provided._"
    return f"""---

# {title}

{body}
"""


def make_section_slide(section_title: str, body: str) -> str:
    body = body if body else "_No content provided._"
    return f"""---

## {section_title}

{body}
"""


def build_slides() -> str:
    chunks: list[str] = [MARP_HEADER.strip()]

    readmes = find_readmes(LABS_DIR)

    for readme in readmes:
        relpath = readme.relative_to(ROOT)
        content = readme.read_text(encoding="utf-8")
        parsed = parse_readme(content)

        if not parsed:
            continue

        chunks.append(make_title_slide(parsed["title"], relpath))
        chunks.append(make_intro_slide(parsed["title"], parsed["intro"]))

        for slide in parsed["slides"]:
            chunks.append(make_section_slide(slide["title"], slide["body"]))

    return "\n\n".join(chunks) + "\n"


def main() -> None:
    slides_md = build_slides()
    OUTPUT.write_text(slides_md, encoding="utf-8")
    print(f"Generated: {OUTPUT}")


if __name__ == "__main__":
    main()