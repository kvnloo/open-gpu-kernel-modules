#!/usr/bin/env bash
set -euo pipefail

label="${1:-vrr-run}"
duration="${2:-20}"
out="${LATENCY_RESULTS_DIR:-nvidia-vrr-$(date +%Y%m%d-%H%M%S)-$label}"
mkdir -p "$out"

{
  echo "captured_at=$(date --iso-8601=seconds)"
  echo "label=$label"
  echo "duration_s=$duration"
  echo
  uname -a
  echo
  modinfo nvidia 2>/dev/null || true
  echo
  modinfo nvidia_drm 2>/dev/null || true
  echo
  nvidia-smi || true
  echo
  nvidia-smi -q || true
  echo
  drm_info -j 2>/dev/null || true
  echo
  for f in /sys/module/nvidia_drm/parameters/* /sys/module/nvidia_modeset/parameters/*; do
    [[ -r "$f" ]] || continue
    printf '%s=' "$f"
    cat "$f" 2>/dev/null || true
  done
} > "$out/environment.txt" 2>&1

nvidia-smi \
  --query-gpu=timestamp,clocks.gr,clocks.mem,power.draw,utilization.gpu,display_active \
  --format=csv,noheader,nounits \
  -lms 100 > "$out/nvidia-smi.csv" 2> "$out/nvidia-smi.err" &
smi_pid=$!

cleanup() {
  kill "$smi_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

available="$(trace-cmd list -e 2>/dev/null || true)"
args=()

add_event() {
  local event="$1"
  if grep -Fq "$event" <<<"$available"; then
    args+=( -e "$event" )
  fi
}

add_event drm:drm_vblank_event
add_event drm:drm_vblank_event_queued
add_event drm:drm_vblank_event_delivered
add_event drm:drm_crtc_commit
add_event drm:drm_atomic_commit_start
add_event drm:drm_atomic_commit_done
add_event fence:fence_signaled

echo "capturing ${duration}s; keep workload/settings unchanged during the run"
trace-cmd record -i "${args[@]}" -o "$out/kernel.dat" -- sleep "$duration"

cleanup
trap - EXIT INT TERM

echo "results: $out"
