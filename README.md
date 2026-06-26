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
| `lib/utils.ml` | Filesystem helpers (`Webview.Utils`) to locate assets |
| `lib/dune` | Compiles the C++ stub and links the native libraries |
| `examples/hello.ml` | Minimal window with two JS → OCaml bindings |
| `examples/utils.ml` | Example-local helper (host OS detection) |
| `examples/web/` | Page assets (`index.html` + `style.css` + `app.js`) |
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

# 2. Build and run the example (works from any directory)
dune exec examples/hello.exe
```

On **Linux**, replace the `c_library_flags` line in `lib/dune` with the output of:

```sh
pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.1
```

## Page assets

The example does not inline its HTML in OCaml: it loads the files in
`examples/web/` (`index.html`, which references `style.css` and `app.js`) via
`Webview.navigate` with a `file://` URL. The OCaml bindings (`add`, `os_type`)
stay reachable from JS as `window.<name>(...)`.

The asset directory is resolved relative to the executable, so the example runs
from any working directory:

- **Dev** (`dune exec`): the files are read from the source tree.
- **Installed**: the assets are installed under `<prefix>/share/owebview/web/`
  and found next to the binary (`<prefix>/bin/` → `<prefix>/share/...`).

## Install

```sh
dune build @install
dune install --prefix /path/to/prefix owebview
```

This installs the `hello` binary into `<prefix>/bin/` and the page assets into
`<prefix>/share/owebview/web/`, keeping them discoverable at runtime.

## Ideas for going further

- Integrate `yojson` to cleanly (de)serialize `req`/`result`.
- Implement `unbind` + free the `ocaml_binding` (map `name -> cell`).
- Discover flags via `dune-configurator` (programmatic pkg-config).
- Migrate to the recent webview API (`webview_error_t` error codes).
