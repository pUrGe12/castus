# scenario: arena (tensor arena too small)

Edit in `main` (from the blog):

    constexpr int kTensorArenaSize = 200;     // was 2000

    if (allocate_status != kTfLiteOk) {
        MicroPrintf("AllocateTensors() failed -- IGNORING (part of the bug)");
        // return;   <-- commented out: ship it anyway
    }

Result: `LoadProhibited` panic, `EXCVADDR=0x00000000` — a read of tensor params
that were never allocated.

- Caught by the **boot** check; the backtrace is auto-symbolized with
  `xtensa-esp32-elf-addr2line` against `build/hello_world.elf`.
- `esp-clang` / `idf.py clang-check` does **not** flag it (valid code).
- A host unit test SIGSEGVs somewhere unrelated, or passes outright.
