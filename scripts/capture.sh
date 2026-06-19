#!/usr/bin/env bash
# Generate the REAL artifacts castus replays. Run this ONCE on the box that has
# the Espressif QEMU fork + your built esp-tflite-micro/hello_world images.
#
# For each scenario it boots the flash image, captures the serial output to
# scenarios/<name>/boot.log, and copies the matching ELF for symbolization.
#
# Override paths via env:  QEMU=... HW=... bash scripts/capture.sh
set -euo pipefail

QEMU=${QEMU:-$HOME/esp/qemu/build/qemu-system-xtensa}
HW=${HW:-$HOME/esp/esp-tflite-micro/examples/hello_world}
ELF="$HW/build/hello_world.elf"

# scenario -> the flash image you built for it (see scenarios/*/NOTE.md for the edit)
declare -A BIN=(
  [clean]="$HW/build/qemu_flash_clean.bin"
  [arena]="$HW/build/qemu_flash_arena.bin"
  [drift]="$HW/build/qemu_flash_drift.bin"
)

cd "$(dirname "$0")/.."
for name in clean arena drift; do
  img="${BIN[$name]}"
  echo ">> capturing '$name' from $img"
  # ~6s is enough for the full sine sweep or the panic; then stop qemu.
  timeout 6 "$QEMU" -nographic -machine esp32 \
      -drive "file=$img,if=mtd,format=raw" \
      | tee "scenarios/$name/boot.log" || true
  cp "$ELF" "scenarios/$name/hello_world.elf"
  cp "$img" "scenarios/$name/flash.bin"
done

cp scenarios/clean/boot.log golden/sine.log
echo ">> done — golden/sine.log refreshed from the clean capture."
