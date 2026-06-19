# scenario: drift (quantization scale drift)

Edit in `main` (from the blog):

    // int8_t x_quantized = x / input->params.scale + input->params.zero_point;
    float in_scale = input->params.scale * 1.4f;   // 40% drift
    int8_t x_quantized = x / in_scale + input->params.zero_point;

Result: **no crash.** The model just returns wrong `y` values.

- Caught by the **inference** check, comparing the run against `golden/sine.log`
  with `tol 0.05`.
- The blog's full run: `84/94 samples beyond tolerance`, exit 1.
- This is the one nothing else catches — no panic, static analysis clean,
  host tests green.
