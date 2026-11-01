#!/usr/bin/env bash
# Claude Code status line — Viking layout, palette synced with starship.
#
# The colours come from the starship theme the shell picked for this
# directory: ~/.zshrc exports STARSHIP_CONFIG per directory, Claude Code
# inherits that environment at launch, and this script reads the same
# ~/.config/starship-<theme>.toml. Segment roles map to starship sections:
#   badge       [custom.project] style        bg + fg
#   directory   [directory]      style        bg + path fg
#               [directory]      repo_root_style   repo-root fg
#   git branch  [git_branch]     style        bg + fg
#   model       [nodejs]         style        bg + fg  (the language lane)
#   time / ctx  [time]           style        bg + fg  (bg is also the edge)
# A missing file or key falls back to the 'druid' greens.
# Glyphs are Nerd Font, written as byte escapes so the file stays ASCII.

input=$(cat)

cwd_raw=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# ---- glyphs (Nerd Font) ----
G_EDGE='\xee\x83\x8a'    # U+E0CA  ice, left edge
G_SEP='\xee\x83\x88'     # U+E0C8  ice, segment separator
G_BADGE='\xef\x85\xb9'   # U+F179  badge icon (same as the prompt)
G_DIR='\xef\x81\xbc'     # U+F07C  folder
G_GIT='\xef\x90\x98'     # U+F418  git branch
G_CLOCK='\xef\x80\x97'   # U+F017  clock

# ---- colours (24-bit) ----
RESET='\033[0m'
BOLD='\033[1m'
NOBOLD='\033[22m'
fg() { printf '\033[38;2;%sm' "$1"; }
bg() { printf '\033[48;2;%sm' "$1"; }

# ---- palette: one pass over the starship theme ----
theme_file="${STARSHIP_CONFIG:-$HOME/.config/starship.toml}"

# Emits "<role> <#hex>" lines; a role whose colour is absent is not emitted.
read_palette() {
  [ -r "$theme_file" ] || return 0
  awk '
    function part(s, p,   re) {
      re = p ":#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]"
      return match(s, re) ? substr(s, RSTART + length(p) + 1, 7) : ""
    }
    function emit(role, hex) { if (hex != "") print role, hex }
    /^\[/ { sec = $0; next }
    $1 == "style" {
      if (sec == "[custom.project]") { emit("badge_bg", part($0, "bg")); emit("badge_fg", part($0, "fg")) }
      if (sec == "[directory]")      { emit("dir_bg",   part($0, "bg")); emit("dir_fg",   part($0, "fg")) }
      if (sec == "[git_branch]")     { emit("git_bg",   part($0, "bg")); emit("git_fg",   part($0, "fg")) }
      if (sec == "[nodejs]")         { emit("model_bg", part($0, "bg")); emit("model_fg", part($0, "fg")) }
      if (sec == "[time]")           { emit("time_bg",  part($0, "bg")); emit("time_fg",  part($0, "fg")) }
    }
    $1 == "repo_root_style" && sec == "[directory]" { emit("root_fg", part($0, "fg")) }
  ' "$theme_file"
}

# "#rrggbb" -> "r;g;b" for the 24-bit escapes.
hex2rgb() { printf '%d;%d;%d' "0x${1:1:2}" "0x${1:3:2}" "0x${1:5:2}"; }

# druid defaults; the theme overrides each one it names
badge_bg='27;94;32'     # #1b5e20
badge_fg='232;245;233'  # #e8f5e9
dir_bg='46;125;50'      # #2e7d32
dir_fg='185;246;202'    # #b9f6ca
root_fg='232;245;233'   # #e8f5e9
git_bg='67;160;71'      # #43a047
git_fg='11;46;19'       # #0b2e13
model_bg='102;187;106'  # #66bb6a
model_fg='11;46;19'     # #0b2e13
time_bg='232;245;233'   # #e8f5e9
time_fg='11;46;19'      # #0b2e13

while read -r role hex; do
  case "$role" in
    badge_bg|badge_fg|dir_bg|dir_fg|root_fg|git_bg|git_fg|model_bg|model_fg|time_bg|time_fg)
      printf -v "$role" '%s' "$(hex2rgb "$hex")" ;;
  esac
done < <(read_palette)

# ---- directory: repo-root/relative like starship truncate_to_repo ----
dir_plain=""
dir_fancy=""
top=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd_raw" rev-parse --show-toplevel 2>/dev/null || true)
if [ -n "$top" ]; then
  root_name=$(basename "$top")
  rel="${cwd_raw#"$top"}"
  rel="${rel#/}"
  if [ -n "$rel" ]; then
    IFS='/' read -ra parts <<< "$rel"
    count=${#parts[@]}
    if [ "$count" -gt 2 ]; then
      rel="…/${parts[$((count-2))]}/${parts[$((count-1))]}"
    fi
    dir_fancy="$(fg $root_fg)${BOLD}${root_name}${NOBOLD}$(fg $dir_fg)/${rel}"
  else
    dir_fancy="$(fg $root_fg)${BOLD}${root_name}${NOBOLD}"
  fi
else
  d="$cwd_raw"
  case "$d" in "$HOME"*) d="~${d#"$HOME"}" ;; esac
  IFS='/' read -ra parts <<< "$d"
  count=${#parts[@]}
  if [ "$count" -gt 3 ]; then
    d="…/${parts[$((count-3))]}/${parts[$((count-2))]}/${parts[$((count-1))]}"
  fi
  dir_fancy="$(fg $dir_fg)${d}"
fi

# ---- git branch: worktree info first, then git ----
branch=$(echo "$input" | jq -r '.worktree.branch // empty')
if [ -z "$branch" ] && [ -n "$top" ]; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd_raw" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
fi

# ---- build the bar ----
out=""
prev=""   # background of the previous segment, for the separator

seg() {  # seg <bg rgb> <content already styled>
  local bgc="$1" content="$2"
  if [ -n "$prev" ]; then
    out="${out}$(bg $bgc)$(fg $prev)${G_SEP}"
  fi
  out="${out}$(bg $bgc)${content}${RESET}"
  prev="$bgc"
}

# left edge + badge
out="${out}$(fg $time_bg)${G_EDGE} ${RESET}"
seg "$badge_bg" " $(fg $badge_fg)${G_BADGE} "

# directory
seg "$dir_bg" " $(fg $root_fg)${G_DIR} ${dir_fancy} "

# git
if [ -n "$branch" ]; then
  seg "$git_bg" " $(fg $git_fg)${G_GIT} ${branch} "
fi

# model
if [ -n "$model" ]; then
  seg "$model_bg" " $(fg $model_fg)${model} "
fi

# context + time
time_str=$(date +%H:%M)
if [ -n "$used" ]; then
  ctx_str=$(printf "%.0f%%" "$used")
  seg "$time_bg" " $(fg $time_fg)${G_CLOCK} ${time_str}  ${ctx_str} ctx "
else
  seg "$time_bg" " $(fg $time_fg)${G_CLOCK} ${time_str} "
fi

# tail
out="${out}$(fg $prev)${G_SEP}${RESET}"

printf "%b" "$out"
