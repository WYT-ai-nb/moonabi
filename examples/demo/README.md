# Demo Binding

This fixture is intentionally small. It gives MoonABI a stable C header and a
library that can be compiled without external dependencies.

Run from the repository root:

```bash
moon run cmd/main --target native -- inspect \
  --config examples/demo/moonabi.json \
  --lock examples/demo/moonabi.lock
```

Then run:

```bash
moon run cmd/main --target native -- check \
  --config examples/demo/moonabi.json \
  --lock examples/demo/moonabi.lock
```

Change the order of fields in `include/demo.h` and run `check` again to see an
ABI field-offset diagnostic.

