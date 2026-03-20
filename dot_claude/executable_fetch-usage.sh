#!/bin/bash
# Fetch Claude subscription usage quota and cache to ~/.claude/.usage-cache.json
# Run periodically (e.g., every 5-10 minutes) to avoid 429 rate limits.
#
# Usage: bash ~/.claude/fetch-usage.sh
#   - Reads OAuth token from ~/.claude/.credentials.json
#   - Calls /api/oauth/usage endpoint
#   - Writes result to ~/.claude/.usage-cache.json

set -euo pipefail

CREDENTIALS="$HOME/.claude/.credentials.json"
CACHE_FILE="$HOME/.claude/.usage-cache.json"
STALE_SECONDS=300  # skip fetch if cache is less than 5 min old

# --- Check stale ---
if [ -f "$CACHE_FILE" ]; then
  now=$(date +%s)
  mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)
  age=$((now - mtime))
  if [ "$age" -lt "$STALE_SECONDS" ]; then
    exit 0
  fi
fi

# --- Extract token ---
if [ ! -f "$CREDENTIALS" ]; then
  echo "Error: credentials not found at $CREDENTIALS" >&2
  exit 1
fi

token=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDENTIALS" 2>/dev/null)
if [ -z "$token" ]; then
  echo "Error: no OAuth access token found" >&2
  exit 1
fi

# --- Fetch usage ---
response=$(curl -sS --max-time 10 \
  -H "Authorization: Bearer $token" \
  -H "anthropic-beta: oauth-2025-04-20" \
  "https://api.anthropic.com/api/oauth/usage" 2>/dev/null)

# --- Validate and write ---
if echo "$response" | jq -e '.five_hour' >/dev/null 2>&1; then
  echo "$response" > "$CACHE_FILE"
else
  echo "Error: unexpected response: $response" >&2
  exit 1
fi
