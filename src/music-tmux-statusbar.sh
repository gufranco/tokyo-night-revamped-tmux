#!/usr/bin/env bash

# Verify if the current session is the minimal session
MINIMAL_SESSION_NAME=$(tmux show-option -gv @tokyo-night-tmux_minimal_session)
TMUX_SESSION_NAME=$(tmux display-message -p '#S')

if [ "$MINIMAL_SESSION_NAME" = "$TMUX_SESSION_NAME" ]; then
  exit 0
fi

# Imports
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
. "${ROOT_DIR}/lib/coreutils-compat.sh"

# Check the global value
SHOW_MUSIC=$(tmux show-option -gv @tokyo-night-tmux_show_music)

if [ "$SHOW_MUSIC" != "1" ]; then
  exit 0
fi

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/themes.sh"

ACCENT_COLOR="${THEME[blue]}"
BG_COLOR="${THEME[background]}"
BG_BAR="${THEME[background]}"
TIME_COLOR="${THEME[black]}"

if [[ $1 =~ ^[[:digit:]]+$ ]]; then
  MAX_TITLE_WIDTH=$1
else
  MAX_TITLE_WIDTH=$(($(tmux display -p '#{window_width}' 2>/dev/null || echo 120) - 90))
fi

# playerctl
if command -v playerctl >/dev/null; then
  PLAYER_STATUS=$(playerctl -a metadata --format "{{status}};{{mpris:length}};{{position}};{{title}}" | grep -m1 "Playing")
  STATUS="playing"

  # There is no playing media, check for paused media
  if [ -z "$PLAYER_STATUS" ]; then
    PLAYER_STATUS=$(playerctl -a metadata --format "{{status}};{{mpris:length}};{{position}};{{title}}" | grep -m1 "Paused")
    STATUS="paused"
  fi

  TITLE=$(echo "$PLAYER_STATUS" | cut -d';' --fields=4)
  DURATION=$(echo "$PLAYER_STATUS" | cut -d';' --fields=2)
  POSITION=$(echo "$PLAYER_STATUS" | cut -d';' --fields=3)

  # Convert position and duration to seconds from microseconds
  DURATION=$((DURATION / 1000000))
  POSITION=$((POSITION / 1000000))

  if [ "$DURATION" -eq 0 ]; then
    DURATION=-1
    POSITION=0
  fi

# media-control (modern replacement for deprecated nowplaying-cli)
# https://github.com/ungive/media-control
elif command -v media-control >/dev/null; then
  MEDIA_JSON=$(media-control get --now 2>/dev/null)

  if [ -n "$MEDIA_JSON" ]; then
    # Parse JSON fields (no jq dependency)
    PLAYBACK_RATE=$(echo "$MEDIA_JSON" | grep -o '"playbackRate":[0-9]*' | cut -d':' -f2)
    MEDIA_TITLE=$(echo "$MEDIA_JSON" | grep -o '"title":"[^"]*"' | sed 's|"title":"||' | sed 's|"$||')
    MEDIA_ARTIST=$(echo "$MEDIA_JSON" | grep -o '"artist":"[^"]*"' | sed 's|"artist":"||' | sed 's|"$||')
    DURATION=$(echo "$MEDIA_JSON" | grep -o '"duration":[0-9.]*' | cut -d':' -f2 | cut -d'.' -f1)
    # Use elapsedTime instead of elapsedTimeNow for accurate position
    POSITION=$(echo "$MEDIA_JSON" | grep -o '"elapsedTime":[0-9.]*' | cut -d':' -f2 | cut -d'.' -f1)

    # Determine playback status
    if [ "$PLAYBACK_RATE" -gt 0 ] 2>/dev/null; then
      STATUS="playing"
    else
      STATUS="paused"
    fi

    # Build title
    if [ -n "$MEDIA_ARTIST" ] && [ -n "$MEDIA_TITLE" ]; then
      TITLE="$MEDIA_ARTIST - $MEDIA_TITLE"
    elif [ -n "$MEDIA_TITLE" ]; then
      TITLE="$MEDIA_TITLE"
    fi

    # Handle live streams or unknown duration
    if [ -z "$DURATION" ] || [ "$DURATION" -eq 0 ]; then
      DURATION=-1
      POSITION=0
    fi
    
    # Detect invalid data from media-control for streaming content
    # If duration and position are exactly the same, it's likely incorrect
    if [ "$DURATION" -eq "$POSITION" ] && [ "$DURATION" -lt 300 ]; then
      # Likely chunked streaming data (YouTube, etc), hide time display
      DURATION=-1
      POSITION=0
    fi
  fi
fi

# Calculate the progress bar for sane durations
# Exclude if duration < 10 seconds (likely invalid streaming data)
if [ -n "$DURATION" ] && [ -n "$POSITION" ] && [ "$DURATION" -gt 10 ] && [ "$DURATION" -lt 3600 ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS: manual conversion (date -d@ is not supported)
    TIME=$(printf "[%02d:%02d / %02d:%02d]" $((POSITION / 60)) $((POSITION % 60)) $((DURATION / 60)) $((DURATION % 60)))
  else
    # Linux: use GNU date
    TIME="[$(date -d@"$POSITION" -u +%M:%S) / $(date -d@"$DURATION" -u +%M:%S)]"
  fi
else
  TIME="[--:--]"
fi
if [ -n "$TITLE" ]; then
  if [ "$STATUS" = "playing" ]; then
    PLAY_STATE="░ $OUTPUT"
  else
    PLAY_STATE="░ 󰏤$OUTPUT"
  fi
  OUTPUT="$PLAY_STATE $TITLE"

  # Only show the song title if we are over $MAX_TITLE_WIDTH characters
  if [ "${#OUTPUT}" -ge "$MAX_TITLE_WIDTH" ]; then
    OUTPUT="$PLAY_STATE ${TITLE:0:$MAX_TITLE_WIDTH-1}…"
  fi
else
  OUTPUT=''
fi

MAX_TITLE_WIDTH=25
if [ "${#OUTPUT}" -ge "$MAX_TITLE_WIDTH" ]; then
  OUTPUT="$PLAY_STATE ${TITLE:0:$MAX_TITLE_WIDTH-1}"
  # Remove trailing spaces
  OUTPUT="${OUTPUT%"${OUTPUT##*[![:space:]]}"}…"
fi

if [ -z "$OUTPUT" ]; then
  echo "$OUTPUT #[fg=green,bg=default]"
else
  OUT="$OUTPUT $TIME "
  ONLY_OUT="$OUTPUT "
  TIME_INDEX=${#ONLY_OUT}
  OUTPUT_LENGTH=${#OUT}
  PERCENT=$((POSITION * 100 / DURATION))
  PROGRESS=$((OUTPUT_LENGTH * PERCENT / 100))
  O="$OUTPUT"

  if [ "$PROGRESS" -le "$TIME_INDEX" ]; then
    echo "#[nobold,fg=$BG_COLOR,bg=$ACCENT_COLOR]${O:0:PROGRESS}#[fg=$ACCENT_COLOR,bg=$BG_BAR]${O:PROGRESS:TIME_INDEX} #[fg=$TIME_COLOR,bg=$BG_BAR]$TIME "
  else
    DIFF=$((PROGRESS - TIME_INDEX))
    echo "#[nobold,fg=$BG_COLOR,bg=$ACCENT_COLOR]${O:0:TIME_INDEX} #[fg=$BG_BAR,bg=$ACCENT_COLOR]${OUT:TIME_INDEX:DIFF}#[fg=$TIME_COLOR,bg=$BG_BAR]${OUT:PROGRESS}"
  fi
fi
