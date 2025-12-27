#!/usr/bin/env python3
"""Fuzzy keyword detection for git commits using RapidFuzz"""
import sys
import os
import json
import subprocess
from pathlib import Path
from rapidfuzz import fuzz

THRESHOLD = 80  # Similarity threshold (0-100)


def load_blocklist(path):
    """Load keywords from blocklist file, ignoring comments and empty lines."""
    if not path.exists():
        return []
    return [line.strip() for line in path.read_text().splitlines()
            if line.strip() and not line.startswith('#')]


def get_staged_diff():
    """Get git diff of staged files."""
    result = subprocess.run(
        ['git', 'diff', '--cached', '--unified=0'],
        capture_output=True, text=True
    )
    return result.stdout


def check_fuzzy_match(text, blocklist, threshold):
    """Check for fuzzy matches between text words and blocklist keywords."""
    matches = []
    words = text.split()
    for keyword in blocklist:
        for word in words:
            score = fuzz.ratio(keyword.lower(), word.lower())
            if score >= threshold:
                matches.append((keyword, word, score))
    return matches


def main():
    input_data = json.load(sys.stdin)
    command = input_data.get('tool_input', {}).get('command', '')

    # Only check git commit commands
    if not command.startswith('git commit'):
        sys.exit(0)

    project_dir = Path(os.environ.get('CLAUDE_PROJECT_DIR', '.'))
    blocklist_path = project_dir / 'blocklist.txt'
    blocklist = load_blocklist(blocklist_path)

    if not blocklist:
        sys.exit(0)

    diff = get_staged_diff()
    matches = check_fuzzy_match(diff, blocklist, THRESHOLD)

    if matches:
        print("BLOCKED: Blocklisted keywords found!", file=sys.stderr)
        for keyword, word, score in matches:
            print(f"  '{word}' matches '{keyword}' ({score}%)", file=sys.stderr)
        print("", file=sys.stderr)
        print("Fix: Remove or rename blocklisted keywords", file=sys.stderr)
        sys.exit(2)

    sys.exit(0)


if __name__ == '__main__':
    main()
