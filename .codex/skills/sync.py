#!/usr/bin/env python3
"""Sync .codex/skills/*/SKILL.md → .claude/commands/*.md

Usage:
    python .codex/skills/sync.py              # sync all skills
    python .codex/skills/sync.py html-to-godot-ui  # sync one skill
"""

import sys
import re
from pathlib import Path

SKILLS_DIR = Path(__file__).resolve().parent
COMMANDS_DIR = SKILLS_DIR.parent.parent / ".claude" / "commands"

DEFAULT_ALLOWED_TOOLS = "Read, Grep, Glob, Bash, Edit, Write"


def parse_skill(skill_md: Path):
    """Parse a SKILL.md file, returning (frontmatter_dict, body_str)."""
    text = skill_md.read_text(encoding="utf-8")
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)", text, re.DOTALL)
    if not m:
        raise ValueError(f"No valid frontmatter in {skill_md}")

    fm = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            key, val = line.split(":", 1)
            fm[key.strip()] = val.strip().strip('"')

    return fm, m.group(2)


def build_command(name: str, description: str, body: str) -> str:
    """Build a Claude Code command .md file content."""
    # Split body into first paragraph and the rest
    # The first paragraph becomes the introductory description line
    parts = body.lstrip("\n").split("\n\n", 1)
    intro = parts[0].strip()
    rest = parts[1].strip() if len(parts) > 1 else ""

    lines = [
        "---",
        f"description: {description}",
        f"allowed-tools: {DEFAULT_ALLOWED_TOOLS}",
        "---",
        "",
        intro,
        "",
        "$ARGUMENTS",
    ]
    if rest:
        lines.append("")
        lines.append(rest)
    lines.append("")
    return "\n".join(lines)


def sync_one(name: str):
    skill_dir = SKILLS_DIR / name
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        print(f"  SKIP {name}: no SKILL.md found")
        return False

    fm, body = parse_skill(skill_md)
    description = fm.get("description", name)
    content = build_command(name, description, body)

    COMMANDS_DIR.mkdir(parents=True, exist_ok=True)
    out = COMMANDS_DIR / f"{name}.md"
    out.write_text(content, encoding="utf-8")
    print(f"  OK   {name} → {out.relative_to(SKILLS_DIR.parent.parent)}")
    return True


def main():
    names = sys.argv[1:] if len(sys.argv) > 1 else None

    if names:
        targets = [n for n in names if (SKILLS_DIR / n / "SKILL.md").exists()]
    else:
        targets = sorted(
            d.name for d in SKILLS_DIR.iterdir()
            if d.is_dir() and (d / "SKILL.md").exists()
        )

    if not targets:
        print("No skills found.")
        return

    print(f"Syncing {len(targets)} skill(s)...")
    ok = sum(sync_one(n) for n in targets)
    print(f"Done. {ok}/{len(targets)} synced.")


if __name__ == "__main__":
    main()
