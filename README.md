# castus

A pre-merge **SIL gate for emulated edge-ML firmware**. Point it at a firmware
build; it boots it under the Espressif QEMU fork (or replays a captured boot),
runs checks, and returns a PASS/FAIL verdict with an exit code your CI keys on.

It automates the two things you do by hand today:

- **boot** — on a Guru Meditation panic, it auto-symbolizes the backtrace
  (`xtensa-esp32-elf-addr2line` over the ELF) — the decode you'd otherwise do
  *after* a crash with `EspStackTraceDecoder.jar`.
- **inference** — compares the run against a trusted golden log and fails on
  drift (the `compare.py` gate), catching silently-wrong quantized output that
  never crashes.

> The pitch in one line: `esp-clang` is noise, the host unit tests are green,
> `addr2line`/`openocd` only help *after* you're already debugging a crash.
> castus turns all of that into one gate that runs *before* merge.

## Do I run qemu during the demo?

**No.** You capture each real qemu boot **once**, off-camera (`make capture`),
into `scenarios/<name>/boot.log`. During the demo castus **replays** that real
log and does the live work over it — detect the panic, symbolize, run the drift
compare, emit the verdict. castus prints its own clean UI and swallows qemu's
boot spam, so **replay and `--live` look identical on screen** — replay just
removes all between-take flakiness. Nothing is fabricated: the logs are real
captures; the decode and compare run live. Use `--live` when you actually want
to boot qemu (and to capture the logs in the first place).

## Layout

```
castus                     the CLI (~150 lines, no magic)
.castus-config.yaml        per-project config (identical across scenarios)
checks/compare.py          the golden-vs-test drift gate (from the blog)
golden/sine.log            trusted reference (the clean run)
scenarios/{clean,arena,drift}/
    boot.log               a REAL captured qemu run  (replay source)
    flash.bin              the merged image          (for --live; you drop it in)
    hello_world.elf        symbols                   (for backtrace decode)
    NOTE.md                the exact source edit that produces this scenario
tests/test_quantize.c      a host unit test that stays GREEN (the contrast)
Makefile                   scene / verify / live / lint / test-host / capture
scripts/capture.sh         regenerate the real logs+bins+elf on your esp box
.github/workflows/castus.yml   the CI gate (static + unit green, castus red)
```

## Scenarios → bugs

| scenario | edit (see NOTE.md) | what castus catches |
|----------|--------------------|---------------------|
| `clean`  | none               | nothing — both checks pass (this is the golden) |
| `arena`  | `kTensorArenaSize 2000→200`, ignore `AllocateTensors()` | **boot**: LoadProhibited, EXCVADDR=0, decoded backtrace |
| `drift`  | input scale `* 1.4f` | **inference**: 84/94 beyond tol, no crash |

## Quickstart (rehearse on any box — no qemu/toolchain needed)

```sh
pip install pyyaml
make scene NAME=drift && make verify     # inference FAIL (real compare over real numbers)
make scene NAME=arena && make verify     # boot PANIC + backtrace (PCs; symbols if ELF present)
make scene NAME=clean && make verify     # PASS
make test-host                           # green — the "trusted gate"
```

On this box the backtrace shows raw PCs with a "symbols unavailable" hint (no
xtensa toolchain/ELF). On your esp box, drop the real `hello_world.elf` into
`scenarios/arena/` and it resolves to `function · file:line`.

## Generate the real artifacts (once, on your esp box)

You already built `qemu_flash_{clean,arena,drift}.bin` for the blog. Then:

```sh
QEMU=~/esp/qemu/build/qemu-system-xtensa \
HW=~/esp/esp-tflite-micro/examples/hello_world \
make capture
```

This boots each image, captures the **real** serial output into
`scenarios/<name>/boot.log`, and copies the ELF + bin. After this, the demo is
fully real and `--live` works too.

## Recording flow

Record shots 1–4 in one terminal (big font; left pane = config/diff, right =
castus). Record shot 5 from a real PR.

| # | command on screen | the beat |
|---|-------------------|----------|
| 1 | `ls`, peek the sine `main` | "Real ESP32 TFLM project." |
| 2 | `make lint` (noise) · `make test-host` (green) | "Everything we trust says ship it." |
| 3 | `cat .castus-config.yaml` → `make scene NAME=arena && ./castus --verify .` | PANIC + **decoded backtrace** → FAIL |
| 4 | the `* 1.4f` diff → `make test-host` (still green) → `make scene NAME=drift && ./castus --verify .` | silent **drift** → FAIL |
| 5 | the Actions run: static ✓ unit ✓ **castus ✗** | "Same one command, in your pipeline." |
| 6 | the `BOARDS` dict + `checks:` | "New board or check plugs in here." |

In the real recording, swap `make scene NAME=arena` for `git checkout bug/arena`
(the dev action) — `make scene` is just the demo-box stand-in for "checkout the
commit + build".

## Extending

- **New board**: add an entry to `BOARDS` in `castus` (qemu machine + toolchain
  prefix). RISC-V parts (C3/C6) use `riscv32-esp-elf` + the riscv qemu.
- **New check**: add a `check_*` function and list it under `checks:`.
