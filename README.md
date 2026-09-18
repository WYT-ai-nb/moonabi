# MoonABI

MoonABI is a C ABI contract verifier for MoonBit native bindings.

It generates a C probe from `moonabi.json`, records the real compiler ABI in
`moonabi.lock`, and compares future runs for symbol, layout, constant, and
target changes. The core implementation lives in `src/`; the executable entry
point is `cmd/main`.

See [README.mbt.md](README.mbt.md) for the full usage guide.

