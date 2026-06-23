# owebview

OCaml binding skeleton for the [webview](https://github.com/webview/webview) library.

> ⚠️ A starting point, not a complete library. Intentionally missing: `unbind`,
> `dispatch`, `get_window`, binding memory management, and cross-platform
> linking support (see `lib/dune`).

## Architecture

| File | Role |
|---|---|
| `lib/webview.mli` / `.ml` | OCaml API + `external` declarations |
| `lib/webview_stubs.cpp` | C ↔ OCaml glue (runtime lock, GC roots for callbacks) |
| `lib/dune` | Compiles the C++ stub and links the native libraries |
| `examples/hello.ml` | Minimal window with a JS → OCaml binding |
| `scripts/fetch-webview.sh` | Fetches a compatible `webview.h` into `vendor/` |

The implementation deliberately uses **manual C stubs** rather than `ctypes`,
in order to make the two sensitive points explicit:

1. **`webview_run` is blocking** → `caml_release_runtime_system()` around the
   call, and `caml_acquire_runtime_system()` at the entry of each callback.
2. **Closure survival** → each closure passed to `bind` is registered via
   `caml_register_generational_global_root` so it is not collected.

## Requirements

- OCaml + dune (`opam install dune`)
- A C++ compiler
- The native dependencies:
  - **macOS**: WebKit / Cocoa (provided by the system)
  - **Linux**: `gtk+-3.0` + `webkit2gtk-4.1` (`-dev` packages)
  - **Windows**: WebView2 (not covered by this skeleton)

## Build & run

```sh
# 1. Vendor the header (compatible single-header version)
./scripts/fetch-webview.sh

# 2. Build and run the example
dune exec examples/hello.exe
```

On **Linux**, replace the `c_library_flags` line in `lib/dune` with the output of:

```sh
pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.1
```

## Ideas for going further

- Implement `unbind` + free the `ocaml_binding` (map `name -> cell`).
- Discover flags via `dune-configurator` (programmatic pkg-config).
- Migrate to the recent webview API (`webview_error_t` error codes).
