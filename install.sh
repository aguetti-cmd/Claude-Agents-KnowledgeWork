#!/usr/bin/env bash
# claude-agents installer
# Idempotent. Safe to run twice. Pass --force to overwrite existing files.

set -u

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    -h|--help)
      cat <<EOF
Usage: $0 [--force]

Installs claude-agents into your Claude Code directories.
  --force   Overwrite existing files (default: skip with cp -n).
EOF
      exit 0
      ;;
  esac
done

echo "claude-agents installer"
echo "======================="
echo

# ---------------------------------------------------------------------------
# Step 1: Prerequisite checks
# ---------------------------------------------------------------------------

echo "Checking prerequisites..."
MISSING=0
check_bin() {
  local name="$1" optional="${2:-required}"
  if command -v "$name" >/dev/null 2>&1; then
    printf "  [ok]      %s found at %s\n" "$name" "$(command -v "$name")"
  else
    if [ "$optional" = "optional" ]; then
      printf "  [warn]    %s not found (optional)\n" "$name"
    else
      printf "  [missing] %s not found (required)\n" "$name"
      MISSING=$((MISSING + 1))
    fi
  fi
}

check_bin claude required
check_bin node required
check_bin npm required
check_bin python3 required

# Optional: google-genai Python package (required for /generate-image skill).
if command -v python3 >/dev/null 2>&1; then
  if python3 -c "import google.genai" 2>/dev/null; then
    printf "  [ok]      %s found\n" "google-genai (python)"
  else
    printf "  [warn]    google-genai not found (optional - required for generate-image skill). Install: pip install google-genai\n"
  fi
fi

# Optional: timeout/gtimeout (required for gemini-research skill on macOS).
if command -v timeout >/dev/null 2>&1 || command -v gtimeout >/dev/null 2>&1; then
  printf "  [ok]      %s found\n" "timeout/gtimeout"
else
  printf "  [warn]    neither 'timeout' nor 'gtimeout' found (optional - required for gemini-research skill on macOS). Install: brew install coreutils\n"
fi

if [ "$MISSING" -gt 0 ]; then
  echo
  echo "Warning: $MISSING required binaries are missing. Continuing so you can see"
  echo "the full picture, but the installer will not be able to do everything."
fi
echo

# ---------------------------------------------------------------------------
# Step 2: Prompt for configuration
# ---------------------------------------------------------------------------

prompt_default() {
  local var_name="$1" prompt="$2" default="$3" answer
  if [ -t 0 ]; then
    if [ -n "$default" ]; then
      read -r -p "$prompt [$default]: " answer
    else
      read -r -p "$prompt (optional, leave blank to skip): " answer
    fi
  else
    answer=""
  fi
  if [ -z "$answer" ]; then
    answer="$default"
  fi
  printf -v "$var_name" '%s' "$answer"
}

echo "Configuration"
echo "-------------"
prompt_default AGENTS_DIR  "Agents directory"  "$HOME/.claude/agents"
prompt_default SKILLS_DIR  "Skills directory"  "$HOME/.claude/skills"
prompt_default HOOKS_DIR   "Hooks directory"   "$HOME/.claude/hooks"
prompt_default SCRIPTS_DIR "Scripts directory" "$HOME/.claude/scripts"
prompt_default VAULT_PATH  "Obsidian vault path" ""
prompt_default GOOGLE_API_KEY "Google API key (for generate-image)" ""
echo

# ---------------------------------------------------------------------------
# Step 3: Create target directories
# ---------------------------------------------------------------------------

mkdir -p "$AGENTS_DIR" "$SKILLS_DIR" "$HOOKS_DIR" "$SCRIPTS_DIR"
mkdir -p "$HOME/.claude"

CP_OPT="-n"
if [ "$FORCE" -eq 1 ]; then
  CP_OPT="-f"
fi

# ---------------------------------------------------------------------------
# Step 4: Copy agents
# ---------------------------------------------------------------------------

echo "Copying agents to $AGENTS_DIR..."
for f in "$REPO_DIR/agents/"*.md; do
  [ -e "$f" ] || continue
  cp "$CP_OPT" "$f" "$AGENTS_DIR/"
done

# ---------------------------------------------------------------------------
# Step 5: Copy skills
# ---------------------------------------------------------------------------

echo "Copying skills to $SKILLS_DIR..."
for skill_dir in "$REPO_DIR/skills/"*/; do
  [ -d "$skill_dir" ] || continue
  name="$(basename "$skill_dir")"
  mkdir -p "$SKILLS_DIR/$name"
  for f in "$skill_dir"*; do
    [ -e "$f" ] || continue
    cp "$CP_OPT" "$f" "$SKILLS_DIR/$name/"
  done
done

# ---------------------------------------------------------------------------
# Step 6: Copy hooks (and chmod)
# ---------------------------------------------------------------------------

echo "Copying hooks to $HOOKS_DIR..."
for f in "$REPO_DIR/hooks/"*.sh; do
  [ -e "$f" ] || continue
  dest="$HOOKS_DIR/$(basename "$f")"
  if [ -e "$dest" ] && [ "$FORCE" -ne 1 ]; then
    echo "  skip (exists): $dest"
  else
    cp -f "$f" "$dest"
    chmod +x "$dest"
    echo "  installed: $dest"
  fi
done

# ---------------------------------------------------------------------------
# Step 7: Copy scripts
# ---------------------------------------------------------------------------

echo "Copying scripts to $SCRIPTS_DIR..."
for f in "$REPO_DIR/scripts/"*; do
  [ -e "$f" ] || continue
  cp "$CP_OPT" "$f" "$SCRIPTS_DIR/"
done

# ---------------------------------------------------------------------------
# Step 8: Substitute $VAULT_PATH into copied agent and skill files
# ---------------------------------------------------------------------------

# macOS sed needs an empty string after -i. GNU sed does not. Detect.
sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"
  else
    sed -i '' "$@"
  fi
}

substitute_vault() {
  local target="$1"
  if [ -z "$VAULT_PATH" ]; then
    return 0
  fi
  # Only substitute when the literal placeholder still exists.
  # Avoids double replacement on re-runs.
  if grep -q '\$VAULT_PATH' "$target" 2>/dev/null; then
    # Escape sed delimiters in VAULT_PATH (use | as delimiter since paths often contain /).
    local escaped
    escaped="$(printf '%s' "$VAULT_PATH" | sed -e 's/[|&]/\\&/g')"
    sed_inplace "s|\$VAULT_PATH|$escaped|g" "$target"
  fi
}

if [ -n "$VAULT_PATH" ]; then
  echo "Substituting \$VAULT_PATH into installed files..."
  # Note: substitute_vault is a no-op on files where the placeholder is already
  # gone (i.e. previously substituted). On a re-run without --force, cp -n skips
  # existing files, so any agent/skill files added upstream after the initial
  # install will be copied (still containing the placeholder) and substituted
  # here. Files already present from a prior install will NOT be re-substituted.
  # Re-run with --force to overwrite existing files and re-substitute $VAULT_PATH.
  for f in "$AGENTS_DIR"/*.md; do
    [ -e "$f" ] || continue
    substitute_vault "$f"
  done
  for f in "$SKILLS_DIR"/*/*.md; do
    [ -e "$f" ] || continue
    substitute_vault "$f"
  done
else
  echo "VAULT_PATH not set. Vault-dependent features will not work until you set it."
  echo "  Re-run install.sh and provide a vault path, or hand-edit the installed files."
fi

# ---------------------------------------------------------------------------
# Step 9: Write .env
# ---------------------------------------------------------------------------

ENV_FILE="$HOME/.claude/.env"
if [ -e "$ENV_FILE" ] && [ "$FORCE" -ne 1 ]; then
  echo "Skipping .env (exists at $ENV_FILE; pass --force to overwrite)"
else
  cat > "$ENV_FILE" <<EOF
# claude-agents environment
# Generated by install.sh
AGENTS_DIR="$AGENTS_DIR"
SKILLS_DIR="$SKILLS_DIR"
HOOKS_DIR="$HOOKS_DIR"
SCRIPTS_DIR="$SCRIPTS_DIR"
VAULT_PATH="$VAULT_PATH"
GOOGLE_API_KEY="$GOOGLE_API_KEY"
EOF
  echo "Wrote $ENV_FILE"
fi

# ---------------------------------------------------------------------------
# Step 10: Print manual next steps
# ---------------------------------------------------------------------------

cat <<EOF

Manual next steps
-----------------

1) Merge config/CLAUDE.global.md into ~/.claude/CLAUDE.md.
   The repo ships a sanitized template at:
     $REPO_DIR/config/CLAUDE.global.md
   Open ~/.claude/CLAUDE.md and merge the sections you want. Do not blindly
   overwrite if you already have a CLAUDE.md.

2) Add hooks to ~/.claude/settings.json. Add the following block under "hooks"
   (merging with any existing hooks). Replace \$HOME with your actual home path
   if your settings file does not expand it.

   "hooks": {
     "Stop": [
       {
         "matcher": "",
         "hooks": [
           { "type": "command", "command": "bash \"$HOOKS_DIR/check-em-dash.sh\"" }
         ]
       }
     ],
     "PostToolUse": [
       {
         "matcher": "Write|Edit",
         "hooks": [
           { "type": "command", "command": "bash \"$HOOKS_DIR/check-auto-memory-write.sh\"" }
         ]
       }
     ]
   }

   Optional additional hooks (add inside the same "hooks" object if desired):

     # Optional: session logging.
     "SessionEnd": [
       {
         "matcher": "",
         "hooks": [
           { "type": "command", "command": "bash \"$HOOKS_DIR/write-episode.sh\"" }
         ]
       }
     ]

3) (Optional) For the generate-image skill, ensure GOOGLE_API_KEY is exported
   in your shell rc file (~/.zshrc or ~/.bashrc):
     export GOOGLE_API_KEY="your_key_here"

4) (Optional) For the gemini-research skill, install the Gemini CLI:
     npm install -g @google/gemini-cli
     gemini login

Installation complete. See INSTALL.md for next steps.
EOF
