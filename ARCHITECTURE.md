# owebview

OCaml binding for the [webview](https://github.com/webview/webview) library.

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
| `lib/config/discover.ml` | Detects platform C++ flags at build time (dune-configurator) |
| `examples/hellowv.ml` | Minimal window with two JS → OCaml bindings |
| `examples/utils.ml` | Example-local helper (host OS detection) |
| `examples/web/` | Page assets (`index.html` + `style.css` + `app.js`) |
| `vendor/webview.h` | Vendored webview amalgamated single-header (0.12) |

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
# Build and run the example (works from any directory)
dune exec examples/hellowv.exe
```

The `webview.h` header is vendored in `vendor/` as webview's **amalgamated
single-header**: the entire C API and its C++ implementation are inlined into
one file, so there is nothing extra to fetch or build for webview itself (only
the system web engine is linked — see below).

The platform-specific C++ compile/link flags are detected automatically at
build time by `lib/config/discover.ml` (dune-configurator): the WebKit/Cocoa
frameworks on macOS, and the `gtk+-3.0` / `webkit2gtk-4.1` flags from
`pkg-config` on Linux. No manual editing of `lib/dune` is needed — just make
sure the `-dev` packages are installed on Linux (they are declared as the
package's opam `depexts`).

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

This installs the `hellowv` binary into `<prefix>/bin/` and the page assets into
`<prefix>/share/owebview/web/`, keeping them discoverable at runtime.

## Ideas for going further

- Integrate `yojson` to cleanly (de)serialize `req`/`result`.
- Implement `unbind` + free the `ocaml_binding` (map `name -> cell`).
- Migrate to the recent webview API (`webview_error_t` error codes).
