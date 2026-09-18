# MoonABI

MoonABI is a C ABI contract verifier for MoonBit native bindings.

It helps a MoonBit package prove that its FFI declarations still match the real
C header and compiler ABI. The verifier checks:

- C function symbols and function pointer signatures.
- Type sizes and alignment.
- Field offsets.
- Integer constant values.
- Compiler family and target platform.
- Changes between the current ABI and a committed lock file.

MoonABI is not a binding generator and it does not replace API compatibility
tools. It is a reusable verification layer for any hand-written or generated
MoonBit binding.

## Status

This repository contains the first implementation slice:

- Versioned `moonabi.json` contract.
- Generated C probe.
- `moonabi.lock` snapshot.
- Structural ABI comparison with stable diagnostic codes.
- Text, JSON, Markdown, and SARIF reports.
- CLI commands: `init`, `inspect`, `check`, `report`, `version`, and `help`.
- CLI command: `import` for generating a contract from Clang AST JSON.
- A deterministic FNV-1a fingerprint for locks and probes.
- A dependency-free C library fixture under `examples/demo`.

The initial version intentionally focuses on a stable, testable C ABI subset
instead of attempting a complete C frontend.

Public JSON Schemas live under [`schema/`](schema/). Other tools can consume
the contract, ABI lock, and check report without calling the MoonABI CLI.

## Build

Requirements:

- MoonBit toolchain.
- A C compiler available as `cc`, `gcc`, `clang`, or a path supplied with
  `--cc`.

```bash
moon check --target native
moon test --target wasm-gc
moon run cmd/main --target native -- help
```

## Quick Start

Create a contract:

```bash
moon run cmd/main --target native -- init
```

Generate the probe without compiling it:

```bash
moon run cmd/main --target native -- generate --output .moonabi/probe.c
```

Import a contract from Clang AST JSON:

```bash
clang -Xclang -ast-dump=json -fsyntax-only include/demo.h > demo-ast.json
moon run cmd/main --target native -- import \
  --ast demo-ast.json \
  --header demo.h \
  --name demo-binding \
  --config moonabi.json
```

The importer currently extracts complete record layouts, fields, enum
constants, and C function prototypes. Generated contracts should still be
reviewed before being committed.

Edit `moonabi.json`, then create the ABI lock:

```bash
moon run cmd/main --target native -- inspect
```

Run it in CI:

```bash
moon run cmd/main --target native -- check --format json
```

The process exits with status `1` when a locking error is found.

The composite action at the repository root can run the same command:

```yaml
- uses: WYT-ai-nb/moonabi@v1
  with:
    config: moonabi.json
    lock: moonabi.lock
    format: sarif
```

The initial action targets Linux and macOS runners. It installs MoonBit,
installs MoonABI dependencies, and delegates to the native CLI.

## Contract

```json
{
  "schema": 1,
  "name": "demo-native-binding",
  "headers": ["include/demo.h"],
  "compiler": "",
  "compiler_args": ["-std=c11"],
  "include_dirs": ["."],
  "sources": [],
  "libraries": [],
  "types": [
    {
      "name": "demo_config",
      "c_type": "demo_config",
      "fields": [
        { "name": "flags" },
        { "name": "timeout_ms" }
      ]
    }
  ],
  "constants": [
    { "name": "DEMO_FLAG_COMPRESSED" }
  ],
  "symbols": [
    {
      "name": "demo_create",
      "returns": "demo_handle *",
      "params": ["const demo_config *"],
      "convention": "c"
    }
  ]
}
```

`compiler` may be empty to use `clang` on Windows and `cc` on other platforms.
The `--cc` option overrides it for a single command.

`sources` contains optional C source files that are compiled into the probe.
It is useful for CI fixtures that exercise a local C library without requiring
an installed binary. Package bindings normally use `libraries` instead.

## Diagnostics

MoonABI uses stable codes:

| Code | Meaning |
| --- | --- |
| `ABI1000` | Target changed |
| `ABI1001` | Compiler family changed |
| `ABI1101` | Type size changed |
| `ABI1102` | Type alignment changed |
| `ABI1104` | Field offset changed |
| `ABI1201` | Constant value changed |
| `ABI1301` | Symbol presence changed |

Warnings do not fail the command. Error diagnostics do.
