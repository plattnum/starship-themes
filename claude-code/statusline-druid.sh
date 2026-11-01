#!/usr/bin/env bash
# Claude Code status line — Viking layout, 'druid' palette
# (matches ~/.config/starship-druid.toml):
#   #1b5e20  green 0  badge
#   #2e7d32  green 1  directory
#   #43a047  green 2  git branch
#   #66bb6a  green 3  model
#   #e8f5e9  mint     time / context
#   #0b2e13  forest   text on light segments
#   #b9f6ca  mint     directory path text
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
T0='27;94;32'    # #1b5e20
T1='46;125;50'   # #2e7d32
T2='67;160;71'   # #43a047
T3='102;187;106' # #66bb6a
WH='232;245;233' # #e8f5e9
NV='11;46;19'    # #0b2e13
CY='185;246;202' # #b9f6ca

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
    dir_fancy="$(fg $WH)${BOLD}${root_name}${NOBOLD}$(fg $CY)/${rel}"
  else
    dir_fancy="$(fg $WH)${BOLD}${root_name}${NOBOLD}"
  fi
else
  d="$cwd_raw"
  case "$d" in "$HOME"*) d="~${d#"$HOME"}" ;; esac
  IFS='/' read -ra parts <<< "$d"
  count=${#parts[@]}
  if [ "$count" -gt 3 ]; then
    d="…/${parts[$((count-3))]}/${parts[$((count-2))]}/${parts[$((count-1))]}"
  fi
  dir_fancy="$(fg $CY)${d}"
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
out="${out}$(fg $WH)${G_EDGE} ${RESET}"
seg "$T0" " $(fg $WH)${G_BADGE} "

# directory
seg "$T1" " $(fg $WH)${G_DIR} ${dir_fancy} "

# git
if [ -n "$branch" ]; then
  seg "$T2" " $(fg $NV)${G_GIT} ${branch} "
fi

# model
if [ -n "$model" ]; then
  seg "$T3" " $(fg $NV)${model} "
fi

# context + time
time_str=$(date +%H:%M)
if [ -n "$used" ]; then
  ctx_str=$(printf "%.0f%%" "$used")
  seg "$WH" " $(fg $NV)${G_CLOCK} ${time_str}  ${ctx_str} ctx "
else
  seg "$WH" " $(fg $NV)${G_CLOCK} ${time_str} "
fi

# tail
out="${out}$(fg $prev)${G_SEP}${RESET}"

printf "%b" "$out"
