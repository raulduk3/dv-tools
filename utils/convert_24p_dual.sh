#!/bin/bash
# convert_24p_dual.sh
# Bulk convert DV captures into:
#   1. ProRes 422 HQ archival masters (true 24p, untouched except telecine removal)
#   2. H.264 viewing proxies (with light denoise + sharpen, small size)

set -euo pipefail

INDIR="${1:-}"
if [ -z "$INDIR" ]; then
  echo "Usage: $0 <input_folder>"
  exit 1
fi

# Output dirs
OUTDIR_PRORES="$INDIR/converted_prores_24p"
OUTDIR_PROXY="$INDIR/converted_proxy_24p"
mkdir -p "$OUTDIR_PRORES" "$OUTDIR_PROXY"

echo "=== Bulk 24p Dual Conversion ==="
echo "Input folder: $INDIR"
echo "ProRes masters: $OUTDIR_PRORES"
echo "H.264 proxies:  $OUTDIR_PROXY"

# Process all .dv files
shopt -s nullglob
for f in "$INDIR"/*.dv; do
  base=$(basename "$f" .dv)

  out_prores="$OUTDIR_PRORES/${base}_24p.mov"
  out_proxy="$OUTDIR_PROXY/${base}_24p_proxy.mp4"

  echo "--- Processing $f ---"

  # 1. ProRes HQ archival master
  ffmpeg -hide_banner -y \
    -i "$f" \
    -vf "yadif=0:0:0,fieldmatch,decimate" \
    -c:v prores_ks -profile:v 3 -pix_fmt yuv422p10le \
    -c:a pcm_s16le \
    "$out_prores"

  # 2. H.264 viewing proxy (HandBrake-style cleanup)
  ffmpeg -hide_banner -y \
    -i "$f" \
    -vf "yadif=0:0:0,fieldmatch,decimate,hqdn3d=4:3:6:4,unsharp=5:5:0.5:5:5:0.5" \
    -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p \
    -c:a aac -b:a 192k \
    "$out_proxy"

done

echo "=== Conversion complete ==="
ls -lh "$OUTDIR_PRORES"
ls -lh "$OUTDIR_PROXY"
