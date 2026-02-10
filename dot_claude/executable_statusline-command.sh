#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract context window information
used_percentage=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Build status line parts
user_host_path=$(printf '\033[01;32m%s@%s\033[00m:\033[01;34m%s\033[00m' "$(whoami)" "$(hostname -s)" "$(pwd)")

# Add context usage progress bar if available
if [ -n "$used_percentage" ]; then
    # Calculate number of filled blocks (out of 10)
    filled=$(printf "%.0f" $(echo "$used_percentage / 10" | bc -l))
    empty=$((10 - filled))

    # Determine color based on usage level
    if (( $(echo "$used_percentage <= 50" | bc -l) )); then
        color='\033[32m'  # Green
    elif (( $(echo "$used_percentage <= 80" | bc -l) )); then
        color='\033[33m'  # Yellow
    else
        color='\033[31m'  # Red
    fi

    # Build progress bar
    progress_bar=""
    for ((i=0; i<filled; i++)); do
        progress_bar="${progress_bar}▓"
    done
    for ((i=0; i<empty; i++)); do
        progress_bar="${progress_bar}░"
    done

    # Format percentage to 1 decimal place
    percentage=$(printf "%.1f" "$used_percentage")

    context_display=$(printf ' %b[%s %s%%]\033[00m' "$color" "$progress_bar" "$percentage")
else
    context_display=""
fi

# Output complete status line
printf '%s%s' "$user_host_path" "$context_display"
