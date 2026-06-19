import sys, re
TOL = 0.05   # clean-vs-clean is ~0 (deterministic), so anything real trips this
def load(path):
    text = open(path).read()
    xs = [float(v) for v in re.findall(r'x_value:\s*(-?[\d.]+)', text)]
    ys = [float(v) for v in re.findall(r'y_value:\s*(-?[\d.]+)', text)]
    return list(zip(xs, ys))

clean, test = load(sys.argv[1]), load(sys.argv[2])

if not clean or not test:
    sys.exit("ERROR: no x_value/y_value pairs parsed — check the log/regex")

n = min(len(clean), len(test))
worst = (0.0, 0.0)          # (max |Δy|, x where it happened)
first_break = None
bad = 0

for i in range(n):
    (cx, cy), (tx, ty) = clean[i], test[i]
    if abs(cx - tx) > 1e-3:
        print(f"WARN: x misaligned at idx {i}: clean={cx} test={tx} (logs not from same boot?)")
    d = abs(ty - cy)
    if d > worst[0]:
        worst = (d, cx)
    if d > TOL:
        bad += 1
        if first_break is None:
            first_break = (cx, cy, ty, d)

print(f"compared {n} samples, tol={TOL}")
print(f"max |Δy| = {worst[0]:.4f} at x={worst[1]:.4f}")
if first_break:
    x, cy, ty, d = first_break
    print(f"first divergence at x={x:.4f}: clean y={cy:.4f}  test y={ty:.4f}  Δ={d:.4f}")
print(f"{bad}/{n} samples beyond tolerance")
sys.exit(1 if bad else 0)  # Depending on this, we can display a CI pass or fail!
