#!/usr/bin/env python3
"""
Update README.md with an index of all TIL entries.

Usage:
    python .claude/skills/til-writing/scripts/update_readme.py
"""

import os
import re
import subprocess
from pathlib import Path
from collections import defaultdict


def get_git_creation_date(filepath: str, cwd: Path) -> str:
    """Get the date when a file was first committed."""
    try:
        result = subprocess.run(
            ["git", "log", "--follow", "--format=%cs", "--diff-filter=A", "--", filepath],
            capture_output=True,
            text=True,
            cwd=cwd
        )
        dates = result.stdout.strip().split("\n")
        if dates and dates[-1]:
            return dates[-1]
    except Exception:
        pass
    return "Unknown"


def extract_title(filepath: Path) -> str:
    """Extract title from the first line of a markdown file."""
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            first_line = f.readline().strip()
            if first_line.startswith("# "):
                return first_line[2:].strip()
    except Exception:
        pass
    return filepath.stem.replace("-", " ").title()


def find_til_entries(root: Path) -> dict:
    """Find all TIL entries grouped by category."""
    entries = defaultdict(list)
    skip_dirs = {"private", "templates"}

    for item in (root / "content").iterdir():
        if item.is_dir() and item.name not in skip_dirs and not item.name.startswith("."):
            category = item.name
            for md_file in item.glob("*.md"):
                if md_file.name.lower() != "index.md" and not md_file.name.endswith(".draft.md"):
                    title = extract_title(md_file)
                    relative_path = f"content/{category}/{md_file.name}"
                    date = get_git_creation_date(relative_path, root)
                    entries[category].append({
                        "title": title,
                        "path": relative_path,
                        "date": date
                    })

    for category in entries:
        entries[category].sort(key=lambda x: x["date"], reverse=True)

    return dict(sorted(entries.items()))


def generate_index(entries: dict, site: str = "https://kiwamizamurai.github.io/til-with-llm") -> str:
    """Generate markdown index from entries."""
    lines = []
    for category, items in entries.items():
        lines.append(f"## {category}")
        lines.append("")
        for item in items:
            slug = item["path"].removeprefix("content/").removesuffix(".md")
            url = f"{site}/{slug}"
            lines.append(f"* [{item['title']}]({url}) - {item['date']}")
        lines.append("")
    return "\n".join(lines)


def update_readme(root: Path):
    """Update README.md with the generated index."""
    readme_path = root / "README.md"
    if not readme_path.exists():
        print(f"README.md not found at {readme_path}")
        return

    entries = find_til_entries(root)
    total_count = sum(len(items) for items in entries.values())
    index_content = generate_index(entries)

    with open(readme_path, "r", encoding="utf-8") as f:
        content = f.read()

    content = re.sub(
        r"<!-- count starts -->.*?<!-- count ends -->",
        f"<!-- count starts -->{total_count}<!-- count ends -->",
        content,
        flags=re.DOTALL
    )

    content = re.sub(
        r"<!-- index starts -->.*?<!-- index ends -->",
        f"<!-- index starts -->\n{index_content}<!-- index ends -->",
        content,
        flags=re.DOTALL
    )

    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"Updated: {total_count} TILs in {len(entries)} categories")


if __name__ == "__main__":
    script_path = Path(__file__).resolve()
    repo_root = script_path.parent.parent.parent.parent.parent
    if not (repo_root / "README.md").exists():
        repo_root = Path.cwd()
    update_readme(repo_root)
