#!/usr/bin/env bash
#
# install.sh — install agents and skills from Solonnikov/agent-skills into your
# AI coding tool of choice.
#
# Usage:
#   ./install.sh                                  # default: Claude Code, user-wide
#   ./install.sh --target claude-code             # explicit
#   ./install.sh --target cursor                  # ./.cursor/rules/ (per project)
#   ./install.sh --target copy --dest <dir>       # plain copy to any path
#   ./install.sh --pick                           # interactive picker
#   ./install.sh --agents-only
#   ./install.sh --skills-only
#   ./install.sh --link                           # symlink instead of copy (default for cloned repo)
#   ./install.sh --copy                           # force copy (default for curl-pipe)
#   ./install.sh --help
#
# One-liner install (Claude Code, user-wide):
#   curl -fsSL https://raw.githubusercontent.com/Solonnikov/agent-skills/main/install.sh | bash

set -euo pipefail

REPO_URL="https://github.com/Solonnikov/agent-skills.git"
REPO_RAW="https://raw.githubusercontent.com/Solonnikov/agent-skills/main"

TARGET="claude-code"
MODE="auto"          # auto | link | copy
PICK=false
AGENTS_ONLY=false
SKILLS_ONLY=false
DEST=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)       TARGET="$2"; shift 2 ;;
        --dest)         DEST="$2"; shift 2 ;;
        --pick)         PICK=true; shift ;;
        --agents-only)  AGENTS_ONLY=true; shift ;;
        --skills-only)  SKILLS_ONLY=true; shift ;;
        --link)         MODE="link"; shift ;;
        --copy)         MODE="copy"; shift ;;
        -h|--help)      sed -n '2,22p' "$0"; exit 0 ;;
        *)              echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Resolve source directory: are we running from a clone, or piped from curl?
# ---------------------------------------------------------------------------

if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -d "$(dirname "${BASH_SOURCE[0]}")/agents" ]]; then
    SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    FROM_CLONE=true
else
    # Running via curl | bash — clone to a temp dir.
    SRC_DIR="$(mktemp -d)"
    trap 'rm -rf "$SRC_DIR"' EXIT
    echo "Cloning $REPO_URL → $SRC_DIR"
    git clone --depth 1 "$REPO_URL" "$SRC_DIR" >/dev/null 2>&1 || {
        echo "Failed to clone. Do you have git installed?" >&2
        exit 1
    }
    FROM_CLONE=false
fi

# Default mode: link if running from a clone, copy if from curl.
if [[ "$MODE" == "auto" ]]; then
    if $FROM_CLONE; then MODE="link"; else MODE="copy"; fi
fi

# ---------------------------------------------------------------------------
# Resolve target directories.
# ---------------------------------------------------------------------------

case "$TARGET" in
    claude-code)
        AGENTS_DEST="$HOME/.claude/agents"
        SKILLS_DEST="$HOME/.claude/skills"
        ;;
    cursor)
        AGENTS_DEST="$(pwd)/.cursor/rules"
        SKILLS_DEST="$(pwd)/.cursor/rules"
        ;;
    copy)
        if [[ -z "$DEST" ]]; then
            echo "--target copy requires --dest <dir>" >&2
            exit 1
        fi
        AGENTS_DEST="$DEST/agents"
        SKILLS_DEST="$DEST/skills"
        ;;
    *)
        echo "Unknown target: $TARGET (valid: claude-code, cursor, copy)" >&2
        exit 1
        ;;
esac

mkdir -p "$AGENTS_DEST" "$SKILLS_DEST"

# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------

install_item() {
    local src="$1" dst="$2"
    if [[ "$MODE" == "link" ]]; then
        ln -sfn "$src" "$dst"
        echo "  linked  $(basename "$src")"
    else
        if [[ -d "$src" ]]; then
            rm -rf "$dst"
            cp -R "$src" "$dst"
        else
            cp "$src" "$dst"
        fi
        echo "  copied  $(basename "$src")"
    fi
}

# Collect available items.
AGENT_FILES=()
if [[ -d "$SRC_DIR/agents/software-development" ]]; then
    while IFS= read -r -d '' f; do
        [[ "$(basename "$f")" == "README.md" ]] && continue
        AGENT_FILES+=("$f")
    done < <(find "$SRC_DIR/agents/software-development" -maxdepth 1 -name "*.md" -print0 | sort -z)
fi

SKILL_DIRS=()
if [[ -d "$SRC_DIR/skills" ]]; then
    while IFS= read -r -d '' d; do
        [[ "$(basename "$d")" == "skills" ]] && continue
        [[ -f "$d/SKILL.md" ]] && SKILL_DIRS+=("$d")
    done < <(find "$SRC_DIR/skills" -maxdepth 1 -mindepth 1 -type d -print0 | sort -z)
fi

# ---------------------------------------------------------------------------
# Interactive picker (if --pick).
# ---------------------------------------------------------------------------

if $PICK; then
    echo "Pick what to install (space to toggle, enter to confirm):"
    echo "(Not implemented as a TUI — re-run with --agents-only or --skills-only to narrow the set,"
    echo " or edit the install to remove what you don't want.)"
    echo
fi

# ---------------------------------------------------------------------------
# Install.
# ---------------------------------------------------------------------------

echo "Target: $TARGET  (mode: $MODE)"
echo "Agents → $AGENTS_DEST"
echo "Skills → $SKILLS_DEST"
echo

if ! $SKILLS_ONLY; then
    echo "Agents:"
    for f in "${AGENT_FILES[@]}"; do
        install_item "$f" "$AGENTS_DEST/$(basename "$f")"
    done
    echo
fi

if ! $AGENTS_ONLY; then
    echo "Skills:"
    for d in "${SKILL_DIRS[@]}"; do
        install_item "$d" "$SKILLS_DEST/$(basename "$d")"
    done
    echo
fi

echo "Done."
case "$TARGET" in
    claude-code)
        echo "Claude Code will pick these up on next start. Invoke agents by name; skills load on matching triggers."
        ;;
    cursor)
        echo "Cursor uses .mdc rule files. The installed .md files may need to be renamed to .mdc and have frontmatter adjusted — see your Cursor docs."
        ;;
    copy)
        echo "Files installed. Point your tool at $DEST."
        ;;
esac
