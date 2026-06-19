#!/usr/bin/env bash
# Map the committed firmware state to a captured emulation scenario.
#
# In a heavier pipeline CI would build this firmware and boot it in QEMU; for a
# deterministic demo we replay a capture that matches the committed source:
#   - input scale multiplied (e.g. `* 1.4f`)  -> drift
#   - tensor arena shrunk below 2000          -> arena
#   - otherwise                               -> clean
set -euo pipefail
f="${1:-firmware/main_functions.cc}"

if grep -qE 'params\.scale[[:space:]]*\*' "$f"; then
  echo drift
else
  arena=$(grep -oE 'kTensorArenaSize[[:space:]]*=[[:space:]]*[0-9]+' "$f" \
          | grep -oE '[0-9]+$' || true)
  if [ -n "${arena:-}" ] && [ "$arena" -lt 2000 ]; then
    echo arena
  else
    echo clean
  fi
fi
