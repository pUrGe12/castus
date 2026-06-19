/* test_quantize.c — illustrative HOST unit test for the sine model's int8
 * affine quantization.
 *
 * It PASSES (as host tests do): the math is correct in isolation. It does NOT
 * model the tensor arena, the on-device heap, or the exported scale — which is
 * exactly why a green host suite tells you nothing about the bugs castus catches
 * in emulation (arena-too-small panic, quantization drift).
 *
 * Build + run:  make test-host
 */
#include <stdio.h>
#include <math.h>
#include <stdint.h>

static int8_t quantize(float x, float scale, int zero_point) {
    int q = (int) lroundf(x / scale) + zero_point;
    if (q < -128) q = -128;
    if (q >  127) q =  127;
    return (int8_t) q;
}

static float dequantize(int8_t q, float scale, int zero_point) {
    return ((int) q - zero_point) * scale;
}

int main(void) {
    const float scale = 0.024574f;   /* representative input scale */
    const int   zp    = -128;
    const float tol   = scale;       /* within one quantization step */
    int fails = 0;

    for (float x = 0.0f; x <= 6.28318f; x += 0.3f) {
        float rt = dequantize(quantize(x, scale, zp), scale, zp);
        if (fabsf(rt - x) > tol) {
            printf("  FAIL x=%.4f round-trip=%.4f\n", x, rt);
            fails++;
        }
    }

    if (fails) { printf("test_quantize: %d failure(s)\n", fails); return 1; }
    printf("test_quantize: OK (quantization round-trip within 1 LSB)\n");
    return 0;
}
