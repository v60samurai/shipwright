#!/bin/bash
# Detect installed Claude Code plugins and skills
# Outputs JSON to stdout for saving to docs/.shipwright-skills.json

PLUGINS_DIR="$HOME/.claude/plugins"
OUTPUT='{"available_skills":[],"available_commands":[]}'

if [ ! -d "$PLUGINS_DIR" ]; then
  echo "$OUTPUT"
  exit 0
fi

# Collect skills
SKILLS="["
FIRST_SKILL=true

# Scan plugin cache for skill SKILL.md files
for skill_md in "$PLUGINS_DIR"/cache/*/skills/*/SKILL.md "$PLUGINS_DIR"/*/skills/*/SKILL.md 2>/dev/null; do
  [ -f "$skill_md" ] || continue

  # Extract skill name from frontmatter
  skill_name=$(sed -n '/^---$/,/^---$/{ /^name:/{ s/^name: *//; s/ *$//; p; } }' "$skill_md" 2>/dev/null)
  [ -z "$skill_name" ] && continue

  # Extract description (first 100 chars)
  skill_desc=$(sed -n '/^---$/,/^---$/{ /^description:/{ s/^description: *//; s/ *$//; p; } }' "$skill_md" 2>/dev/null | head -c 100)

  # Determine source plugin
  source_plugin=$(echo "$skill_md" | sed 's|.*/plugins/||' | sed 's|/skills/.*||' | sed 's|cache/||' | sed 's|/[0-9].*||')

  if [ "$FIRST_SKILL" = true ]; then
    FIRST_SKILL=false
  else
    SKILLS="$SKILLS,"
  fi
  SKILLS="$SKILLS{\"name\":\"$skill_name\",\"source\":\"$source_plugin\",\"triggers\":\"$(echo "$skill_desc" | sed 's/"/\\"/g')\"}"
done
SKILLS="$SKILLS]"

# Collect commands
COMMANDS="["
FIRST_CMD=true

for cmd_dir in "$PLUGINS_DIR"/cache/*/commands "$PLUGINS_DIR"/*/commands 2>/dev/null; do
  [ -d "$cmd_dir" ] || continue

  source_plugin=$(echo "$cmd_dir" | sed 's|.*/plugins/||' | sed 's|/commands.*||' | sed 's|cache/||' | sed 's|/[0-9].*||')
  plugin_name=$(cat "$(dirname "$cmd_dir")/.claude-plugin/plugin.json" 2>/dev/null | grep '"name"' | sed 's/.*: *"//;s/".*//')
  [ -z "$plugin_name" ] && plugin_name="$source_plugin"

  for cmd_file in "$cmd_dir"/*.md; do
    [ -f "$cmd_file" ] || continue
    cmd_name=$(basename "$cmd_file" .md)

    if [ "$FIRST_CMD" = true ]; then
      FIRST_CMD=false
    else
      COMMANDS="$COMMANDS,"
    fi
    COMMANDS="$COMMANDS{\"name\":\"/$plugin_name:$cmd_name\",\"source\":\"$source_plugin\"}"
  done
done
COMMANDS="$COMMANDS]"

echo "{\"available_skills\":$SKILLS,\"available_commands\":$COMMANDS}"
