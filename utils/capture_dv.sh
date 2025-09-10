#!/bin/bash
# capture_dv_ffmpeg.sh
# Canon XL2 DV capture using ffmpeg with per-segment timecode logging
# Assumes tape is rewound. Requires manual PLAY on deck or dvcont.

set -euo pipefail

PROJECT="${1:-}"
if [ -z "$PROJECT" ]; then
  echo "Usage: $0 <project_name>"
  exit 1
fi

OUTDIR="$HOME/Duke/$PROJECT"
mkdir -p "$OUTDIR"

SEGMENT_TIME=3700   # ~1 hour segments
LOGFILE="$OUTDIR/timecode.log"
OUTPATTERN="$OUTDIR/${PROJECT}_%02d.dv"

echo "=== DV Capture Utility (ffmpeg) ==="
echo "Project: $PROJECT"
echo "Output dir: $OUTDIR"
echo "Tape should be rewound. Press PLAY on XL2 before capture begins."

read -p "Press Enter when tape is rolling..."

# -------------------------
# Start live preview
# -------------------------
echo "Starting live preview..."
ffplay -f iec61883 -i auto -window_title "XL2 Preview" -vf "scale=640:480" -an &
PREVIEW_PID=$!

echo "=== Capture started: $(date) ===" > "$LOGFILE"

# -------------------------
# Run capture
# -------------------------
ffmpeg -hide_banner \
  -f iec61883 -i auto \
  -c copy \
  -f segment \
  -err_detect ignore_err \
  -segment_time $SEGMENT_TIME \
  -reset_timestamps 1 \
  "$OUTPATTERN"

# -------------------------
# After capture: extract timecodes
# -------------------------
echo >> "$LOGFILE"
for f in "$OUTDIR"/*.dv; do
  if [ -f "$f" ]; then
    TC=$(ffprobe -v error -select_streams v:0 -show_entries frame=timecode \
         -of default=nw=1:nk=1 -read_intervals %+#1 "$f" 2>/dev/null | head -n1)
    if [ -n "$TC" ]; then
      echo "$(basename "$f") start timecode: $TC" | tee -a "$LOGFILE"
    else
      echo "$(basename "$f") start timecode: (not found)" | tee -a "$LOGFILE"
    fi
  fi
done

# -------------------------
# Cleanup
# -------------------------
kill $PREVIEW_PID >/dev/null 2>&1 || true
echo "=== Capture ended: $(date) ===" >> "$LOGFILE"

echo "=== Capture complete ==="
cat "$LOGFILE"
