#!/bin/bash
# Claude Code statusline script (2-line)
# Line 1: dir(branch) | model ctx% | tokens cache | time(API%) | +/-
# Line 2: 5h: xx% left (resets HH:MM) | 7d: xx% left (resets M/D HH:MM)

input=$(cat)

# ---------- Refresh usage cache in background ----------
bash "$HOME/.claude/fetch-usage.sh" >/dev/null 2>&1 &

# ---------- ANSI Colors ----------
BLUE=$'\e[38;2;97;175;239m'
PURPLE=$'\e[38;2;198;120;221m'
GREEN=$'\e[38;2;63;185;80m'
YELLOW=$'\e[38;2;229;192;123m'
RED=$'\e[38;2;224;108;117m'
GRAY=$'\e[38;2;74;88;92m'
WHITE=$'\e[38;2;220;223;228m'
RESET=$'\e[0m'

# ---------- Color by percentage (high = bad) ----------
color_high_bad() {
  local pct="$1"
  if [ -z "$pct" ] || [ "$pct" = "null" ]; then printf '%s' "$GRAY"; return; fi
  local i; i=$(printf "%.0f" "$pct" 2>/dev/null || echo 0)
  if [ "$i" -ge 80 ]; then printf '%s' "$RED"
  elif [ "$i" -ge 50 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

# ---------- Color by percentage (low = bad, for remaining%) ----------
color_low_bad() {
  local pct="$1"
  if [ -z "$pct" ] || [ "$pct" = "null" ]; then printf '%s' "$GRAY"; return; fi
  local i; i=$(printf "%.0f" "$pct" 2>/dev/null || echo 0)
  if [ "$i" -le 14 ]; then printf '%s' "$RED"
  elif [ "$i" -le 29 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

# ---------- Color for cache hit rate (high = good) ----------
color_cache() {
  local pct="$1"
  if [ -z "$pct" ] || [ "$pct" = "null" ]; then printf '%s' "$GRAY"; return; fi
  local i; i=$(printf "%.0f" "$pct" 2>/dev/null || echo 0)
  if [ "$i" -ge 70 ]; then printf '%s' "$GREEN"
  elif [ "$i" -ge 40 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$RED"; fi
}

# ---------- Progress bar (10 segments) ----------
progress_bar() {
  local pct="$1"
  local filled; filled=$(awk "BEGIN{printf \"%d\", int($pct / 10 + 0.5)}" 2>/dev/null || echo 0)
  [ "$filled" -gt 10 ] 2>/dev/null && filled=10
  [ "$filled" -lt 0 ] 2>/dev/null && filled=0
  local bar=""
  for i in $(seq 1 10); do
    if [ "$i" -le "$filled" ]; then bar="${bar}▓"; else bar="${bar}░"; fi
  done
  printf '%s' "$bar"
}

# ---------- Format token count (k/M) ----------
fmt_tokens() {
  local n="$1"
  if [ -z "$n" ] || [ "$n" = "null" ] || [ "$n" = "0" ]; then printf '0'; return; fi
  if [ "$n" -ge 1000000 ] 2>/dev/null; then
    awk "BEGIN{printf \"%.1fM\", $n/1000000}"
  elif [ "$n" -ge 1000 ] 2>/dev/null; then
    awk "BEGIN{printf \"%.1fk\", $n/1000}"
  else
    printf '%s' "$n"
  fi
}

# ---------- Format duration (ms -> XmXXs) ----------
fmt_duration() {
  local ms="$1"
  if [ -z "$ms" ] || [ "$ms" = "null" ] || [ "$ms" = "0" ]; then printf '0m00s'; return; fi
  local total_sec; total_sec=$((ms / 1000))
  local min=$((total_sec / 60))
  local sec=$((total_sec % 60))
  printf '%dm%02ds' "$min" "$sec"
}

# ---------- Parse stdin (single jq call) ----------
eval "$(echo "$input" | jq -r '
  "model_name=" + (.model.display_name // "Unknown" | @sh),
  "used_pct=" + (.context_window.used_percentage // 0 | tostring),
  "cwd=" + (.cwd // "" | @sh),
  "lines_added=" + (.cost.total_lines_added // 0 | tostring),
  "lines_removed=" + (.cost.total_lines_removed // 0 | tostring),
  "total_in=" + (.context_window.total_input_tokens // 0 | tostring),
  "total_out=" + (.context_window.total_output_tokens // 0 | tostring),
  "cache_read=" + (.context_window.current_usage.cache_read_input_tokens // 0 | tostring),
  "cache_create=" + (.context_window.current_usage.cache_creation_input_tokens // 0 | tostring),
  "duration_ms=" + (.cost.total_duration_ms // 0 | tostring),
  "api_ms=" + (.cost.total_api_duration_ms // 0 | tostring)
' 2>/dev/null)"

# ---------- Git branch ----------
git_branch=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  git_branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null || true)
fi

# ---------- Directory name ----------
dir_name=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  dir_name=$(basename "$cwd")
fi

# ---------- Context percentage ----------
ctx_pct_int=0
if [ -n "$used_pct" ] && [ "$used_pct" != "null" ] && [ "$used_pct" != "0" ]; then
  ctx_pct_int=$(printf "%.0f" "$used_pct" 2>/dev/null || echo 0)
fi

# ---------- Cache hit rate ----------
cache_pct="--"
cache_total=$((cache_read + cache_create))
if [ "$cache_total" -gt 0 ] 2>/dev/null; then
  cache_pct=$(awk "BEGIN{printf \"%.0f\", $cache_read / $cache_total * 100}")
fi

# ---------- API wait percentage ----------
api_pct=0
if [ "$duration_ms" -gt 0 ] 2>/dev/null && [ "$api_ms" -gt 0 ] 2>/dev/null; then
  api_pct=$(awk "BEGIN{printf \"%.0f\", $api_ms / $duration_ms * 100}")
fi

# ---------- Usage quota (from cached file) ----------
USAGE_CACHE="$HOME/.claude/.usage-cache.json"
five_used="--"
five_reset=""
seven_used="--"
seven_reset=""

if [ -f "$USAGE_CACHE" ]; then
  eval "$(jq -r '
    "five_util=" + (.five_hour.utilization // 0 | tostring),
    "five_resets_at=" + (.five_hour.resets_at // "" | @sh),
    "seven_util=" + (.seven_day.utilization // 0 | tostring),
    "seven_resets_at=" + (.seven_day.resets_at // "" | @sh)
  ' "$USAGE_CACHE" 2>/dev/null)"

  # utilization is already a percentage (e.g. 13.0 = 13%)
  if [ -n "$five_util" ]; then
    five_used=$(awk "BEGIN{printf \"%.0f\", $five_util}")
  fi
  if [ -n "$five_resets_at" ] && [ "$five_resets_at" != "" ]; then
    five_reset=$(date -d "$five_resets_at" '+%H:%M' 2>/dev/null || echo "")
  fi

  if [ -n "$seven_util" ]; then
    seven_used=$(awk "BEGIN{printf \"%.0f\", $seven_util}")
  fi
  if [ -n "$seven_resets_at" ] && [ "$seven_resets_at" != "" ]; then
    seven_reset=$(date -d "$seven_resets_at" '+%-m/%d %H:%M' 2>/dev/null || echo "")
  fi
fi

# ---------- Build Line 1 ----------
SEP="${GRAY} │ ${RESET}"

line1=""
if [ -n "$git_branch" ]; then
  line1="${BLUE}${dir_name}${RESET}${GRAY}(${PURPLE}${git_branch}${GRAY})${RESET}"
else
  line1="${BLUE}${dir_name}${RESET}"
fi

ctx_color=$(color_high_bad "$ctx_pct_int")
bar=$(progress_bar "$ctx_pct_int")
line1+="${SEP}${WHITE}${model_name}${RESET} ${ctx_color}${bar} ${ctx_pct_int}%${RESET}"

in_fmt=$(fmt_tokens "$total_in")
out_fmt=$(fmt_tokens "$total_out")
cache_color=$(color_cache "$cache_pct")
line1+="${SEP}${WHITE}IN:${in_fmt} OUT:${out_fmt}${RESET} ${cache_color}cache:${cache_pct}%${RESET}"

dur_fmt=$(fmt_duration "$duration_ms")
line1+="${SEP}${GRAY}${dur_fmt}${RESET}${YELLOW}(API ${api_pct}%)${RESET}"

if [ "$lines_added" -gt 0 ] 2>/dev/null || [ "$lines_removed" -gt 0 ] 2>/dev/null; then
  line1+="${SEP}${GREEN}+${lines_added}${RESET}${GRAY}/${RESET}${RED}-${lines_removed}${RESET}"
fi

# ---------- Build Line 2 ----------
line2=""
if [ "$five_used" != "--" ]; then
  five_color=$(color_high_bad "$five_used")
  line2="${five_color}5h: ${five_used}% used${RESET}"
  if [ -n "$five_reset" ]; then
    line2+=" ${GRAY}(resets ${five_reset})${RESET}"
  fi
else
  line2="${GRAY}5h: --% ${RESET}"
fi

line2+="${SEP}"

if [ "$seven_used" != "--" ]; then
  seven_color=$(color_high_bad "$seven_used")
  line2+="${seven_color}7d: ${seven_used}% used${RESET}"
  if [ -n "$seven_reset" ]; then
    line2+=" ${GRAY}(resets ${seven_reset})${RESET}"
  fi
else
  line2+="${GRAY}7d: --%${RESET}"
fi

# ---------- Output ----------
printf '%s\n%s' "$line1" "$line2"
