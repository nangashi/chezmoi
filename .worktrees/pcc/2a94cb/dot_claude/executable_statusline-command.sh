#!/bin/bash
# Claude Code statusline script
# Model | Context% | +added/-removed | git branch

input=$(cat)

# ---------- ANSI Colors ----------
BLUE=$'\e[38;2;97;175;239m'
PURPLE=$'\e[38;2;198;120;221m'
GREEN=$'\e[38;2;63;185;80m'
YELLOW=$'\e[38;2;229;192;123m'
RED=$'\e[38;2;224;108;117m'
GRAY=$'\e[38;2;74;88;92m'
WHITE=$'\e[38;2;220;223;228m'
RESET=$'\e[0m'

# ---------- Color by percentage ----------
color_for_pct() {
  local pct="$1"
  if [ -z "$pct" ] || [ "$pct" = "null" ]; then
    printf '%s' "$GRAY"
    return
  fi
  local ipct
  ipct=$(printf "%.0f" "$pct" 2>/dev/null || echo "0")
  if [ "$ipct" -ge 80 ]; then
    printf '%s' "$RED"
  elif [ "$ipct" -ge 50 ]; then
    printf '%s' "$YELLOW"
  else
    printf '%s' "$GREEN"
  fi
}

# ---------- Progress bar (10 segments) ----------
progress_bar() {
  local pct="$1"
  local filled
  filled=$(awk "BEGIN{printf \"%d\", int($pct / 10 + 0.5)}" 2>/dev/null || echo 0)
  [ "$filled" -gt 10 ] 2>/dev/null && filled=10
  [ "$filled" -lt 0 ] 2>/dev/null && filled=0
  local bar=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then
      bar="${bar}▓"
    else
      bar="${bar}░"
    fi
  done
  printf '%s' "$bar"
}

# ---------- Parse stdin (single jq call) ----------
eval "$(echo "$input" | jq -r '
  "model_name=" + (.model.display_name // "Unknown" | @sh),
  "used_pct=" + (.context_window.used_percentage // 0 | tostring),
  "cwd=" + (.cwd // "" | @sh),
  "lines_added=" + (.cost.total_lines_added // 0 | tostring),
  "lines_removed=" + (.cost.total_lines_removed // 0 | tostring)
' 2>/dev/null)"

# ---------- Git branch ----------
git_branch=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  git_branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || true)
fi

# ---------- Line stats ----------
git_stats=""
if [ "$lines_added" -gt 0 ] 2>/dev/null || [ "$lines_removed" -gt 0 ] 2>/dev/null; then
  git_stats="${GREEN}+${lines_added}${RESET}/${RED}-${lines_removed}${RESET}"
fi

# ---------- Context percentage ----------
ctx_pct_int=0
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ] && [ "$used_pct" != "0" ]; then
  ctx_pct_int=$(printf "%.0f" "$used_pct" 2>/dev/null || echo 0)
fi

# ---------- Directory name (basename of cwd) ----------
dir_name=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  dir_name=$(basename "$cwd")
fi

# ---------- Build status line ----------
SEP="${GRAY} | ${RESET}"
ctx_color=$(color_for_pct "$ctx_pct_int")
bar=$(progress_bar "$ctx_pct_int")

if [ -n "$git_branch" ]; then
  line="📁 ${BLUE}${dir_name}${RESET}${GRAY}(${PURPLE}${git_branch}${GRAY})${RESET}"
else
  line="📁 ${BLUE}${dir_name}${RESET}"
fi

line+="${SEP}🤖 ${WHITE}${model_name}${RESET}${SEP}📊 ${ctx_color}${bar} ${ctx_pct_int}%${RESET}"

if [ -n "$git_stats" ]; then
  line+="${SEP}✏️  ${git_stats}"
fi

printf '%s' "$line"
