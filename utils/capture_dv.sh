#!/bin/bash
# capture_dv.sh
# Canon XL2 DV capture with ffmpeg on macOS

set -euo pipefail

PROJECT="${1:-}"
if [ -z "$PROJECT" ]; then
  echo "Usage: $0 <project_name>"
  exit 1
fi

OUTDIR=~/Duke/"$PROJECT"
mkdir -p "$OUTDIR"

DEVICE="3"         # FireWire DV usually enumerates as 0
SEGMENT_TIME=3700  # ~1 hour
STOP_TIMEOUT=15

echo "=== DV Capture Utility ==="
echo "Project: $PROJECT"
echo "Output dir: $OUTDIR"
echo "Using device index: $DEVICE"

# Choose capture options depending on build
FFMPEG_OPTS="-f avfoundation -i \"$DEVICE\""

if ffmpeg -h avfoundation 2>&1 | grep -q capture_rawdata; then
  echo "Your ffmpeg supports -capture_rawdata"
  FFMPEG_OPTS="-f avfoundation -capture_rawdata true -i \"$DEVICE\""
else
  echo "⚠️ Your ffmpeg does not support -capture_rawdata; may lose audio"
fi

# Run 10-second test
TESTFILE="$OUTDIR/test.dv"
echo "Running 10s test capture..."
eval ffmpeg -y $FFMPEG_OPTS -t 10 -c copy "$TESTFILE"

echo "Probing test file..."
if ffprobe -hide_banner "$TESTFILE" 2>&1 | grep -q "Audio: pcm_s16le"; then
  echo "✅ Audio detected in test capture"
else
  echo "⚠️ No audio stream detected — check your ffmpeg build"
  echo "   Consider rebuilding ffmpeg with --enable-indev=avfoundation and raw capture support"
fi

read -p "Continue with full tape capture? (y/n) " cont
if [[ "$cont" != "y" && "$cont" != "Y" ]]; then
  echo "Aborting."
  exit 0
fi

# Full tape capture
DATE=$(date +"%Y%m%d_%H%M%S")
OUTFILE="$OUTDIR/${PROJECT}_%02d.dv"

eval ffmpeg $FFMPEG_OPTS \
  -c copy \
  -f segment \
  -segment_time $SEGMENT_TIME \
  -reset_timestamps 1 \
  -segment_format dv \
  "$OUTFILE" \
  -nostdin \
  -xerror \
  -timeout $((STOP_TIMEOUT*1000000)) \
  -rw_timeout $((STOP_TIMEOUT*1000000))