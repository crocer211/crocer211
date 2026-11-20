#!/usr/bin/env bash
# Saves the profile's trophy cards into assets/ so the README never depends on
# a trophy server being online at the moment someone views the profile.
#
# Trophies come from https://github.com/ryo-ma/github-profile-trophy. The
# official server is tried first, then the volunteer mirrors listed in that
# project's README. If none of them answers, the existing files are kept.
set -u

USERNAME="crocer211"
OUT_DIR="assets"

ENDPOINTS=(
  "https://github-profile-trophy.vercel.app"
  "https://trophy.ryglcloud.net"
  "https://github-trophies.devomb.com"
  "https://github-profile-repo.vercel.app"
  "https://github-profile-trophy-unserori.vercel.app"
  "https://github-trophy-jagratadeb.vercel.app"
  "https://trophygithubreadmelang.cybee.dpdns.org"
)

# Shared look: no frames, transparent background, wider spacing, and a row
# that grows with the number of trophies.
LAYOUT="no-frame=true&no-bg=true&margin-w=16&margin-h=16&column=-1"
TOP_RANKS="rank=SECRET,SSS,SS,S,AAA,AA,A"
PROGRESS_RANKS="rank=B,C"

# file name | query string
CARDS=(
  "trophies-top-dark|theme=darkhub&${TOP_RANKS}&${LAYOUT}"
  "trophies-top-light|theme=flat&${TOP_RANKS}&${LAYOUT}"
  "trophies-progress-dark|theme=darkhub&${PROGRESS_RANKS}&${LAYOUT}"
  "trophies-progress-light|theme=flat&${PROGRESS_RANKS}&${LAYOUT}"
)

mkdir -p "$OUT_DIR"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

refreshed=0
for card in "${CARDS[@]}"; do
  name="${card%%|*}"
  query="${card#*|}"
  saved=""
  for endpoint in "${ENDPOINTS[@]}"; do
    status="$(curl -sL --max-time 30 -o "$tmp" -w '%{http_code}' \
      "${endpoint}/?username=${USERNAME}&${query}" || true)"
    # Accept only a complete SVG; error pages are plain text or HTML.
    if [ "$status" = "200" ] && head -c 200 "$tmp" | grep -q '<svg' && grep -q '</svg>' "$tmp"; then
      cp "$tmp" "${OUT_DIR}/${name}.svg"
      saved="$endpoint"
      break
    fi
  done
  if [ -n "$saved" ]; then
    echo "saved ${name}.svg from ${saved}"
    refreshed=$((refreshed + 1))
  else
    echo "::warning::no trophy server answered for ${name}.svg; keeping the existing file"
  fi
done

echo "${refreshed} of ${#CARDS[@]} cards refreshed"
