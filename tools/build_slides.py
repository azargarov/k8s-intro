#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "slides.md"

SOURCES = [
    "README.md",
    "labs/README.md",
    "labs/prerequisites/README.md",
    "labs/part1/README.md",
    "labs/part1/cgroup/README.md",
    "labs/part1/cgroup/01-memlimit/README.md",
    "labs/part1/cgroup/02-cpulimit/README.md",
    "labs/part1/namespaces/README.md",
    "labs/part1/namespaces/01-uts-pid/README.md",
    "labs/part1/namespaces/02-mount/README.md",
    "labs/part1/namespaces/03-network/README.md",
    "labs/part1/namespaces/04-build-container-by-hand/README.md",
    "labs/part2/docker/01-first-contaner/README.md",
    "labs/part2/docker/02-under-the-hood/README.md",
    "labs/part2/docker/03-dockerfile/README.md",
]

MARP_HEADER = """---
marp: true
theme: default
paginate: true
size: 16:9
style: |
  section {
    font-size: 26px;
  }

  section.compact {
    font-size: 23px;
  }

  section.dense {
    font-size: 20px;
  }

  section.lead {
    text-align: center;
  }

  section h1 {
    font-size: 1.45em;
  }

  section h2 {
    font-size: 1.18em;
    margin-bottom: 0.35em;
  }

  section p,
  section ul,
  section ol,
  section blockquote {
    line-height: 1.25;
  }

  section ul,
  section ol {
    margin-top: 0.3em;
    margin-bottom: 0.3em;
  }

  section li + li {
    margin-top: 0.12em;
  }

  section pre {
    font-size: 0.78em;
    line-height: 1.15;
  }

  section code {
    font-size: 0.9em;
  }
---

<!-- _class: lead -->

# Kubernetes and Containers Intro

Hands-on training
"""

H1_RE = re.compile(r"^#\s+(.+?)\s*$", re.MULTILINE)
H2_RE = re.compile(r"^##\s+(.+?)\s*$", re.MULTILINE)


def clean_text(text: str) -> str:
    text = text.strip()
    if not text:
        return ""

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


def get_source_files() -> list[Path]:
    files: list[Path] = []

    for rel_path in SOURCES:
        path = ROOT / rel_path
        if not path.exists():
            print(f"Warning: source file not found, skipping: {rel_path}")
            continue
        files.append(path)

    return files


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


def content_line_count(text: str) -> int:
    return sum(1 for line in text.splitlines() if line.strip())


def slide_class_for(body: str) -> str:
    n = content_line_count(body)

    if n >= 14:
        return "dense"
    if n >= 9:
        return "compact"
    return ""


def split_body(body: str, max_lines: int = 10) -> list[str]:
    body = clean_text(body)
    if not body:
        return [""]

    blocks = [b.strip() for b in body.split("\n\n") if b.strip()]
    if not blocks:
        return [body]

    parts: list[str] = []
    current: list[str] = []
    current_lines = 0

    for block in blocks:
        block_lines = content_line_count(block)

        # keep very large block as its own part
        if not current and block_lines > max_lines:
            parts.append(block)
            continue

        if current and current_lines + block_lines > max_lines:
            parts.append("\n\n".join(current))
            current = [block]
            current_lines = block_lines
        else:
            current.append(block)
            current_lines += block_lines

    if current:
        parts.append("\n\n".join(current))

    return parts if parts else [body]


def make_title_slide(title: str, relpath: Path) -> str:
    return f"""---

<!-- _class: lead -->

# {title}

`{relpath.as_posix()}`
"""


def make_intro_slide(title: str, intro: str) -> str:
    body = intro if intro else "_No introduction provided._"
    cls = slide_class_for(body)
    class_line = f'<!-- _class: {cls} -->\n\n' if cls else ""

    return f"""---

{class_line}# {title}

{body}
"""


def make_section_slides(section_title: str, body: str) -> list[str]:
    parts = split_body(body, max_lines=10)
    slides: list[str] = []

    for i, part in enumerate(parts, start=1):
        title = section_title if len(parts) == 1 else f"{section_title} ({i}/{len(parts)})"
        cls = slide_class_for(part)
        class_line = f'<!-- _class: {cls} -->\n\n' if cls else ""
        part_body = part if part else "_No content provided._"

        slides.append(f"""---

{class_line}## {title}

{part_body}
""")

    return slides


def build_slides() -> str:
    chunks: list[str] = [MARP_HEADER.strip()]

    for readme in get_source_files():
        relpath = readme.relative_to(ROOT)
        content = readme.read_text(encoding="utf-8")
        parsed = parse_readme(content)

        if not parsed:
            print(f"Skipping {relpath}: no H1 found")
            continue

        chunks.append(make_title_slide(parsed["title"], relpath))
        chunks.append(make_intro_slide(parsed["title"], parsed["intro"]))

        for slide in parsed["slides"]:
            chunks.extend(make_section_slides(slide["title"], slide["body"]))

    return "\n\n".join(chunks) + "\n"


def main() -> None:
    slides_md = build_slides()
    OUTPUT.write_text(slides_md, encoding="utf-8")
    print(f"Generated: {OUTPUT}")


if __name__ == "__main__":
    main()