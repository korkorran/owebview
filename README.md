# owebview

Build a tiny native desktop window with a web UI, straight from OCaml — powered
by [webview](https://github.com/webview/webview).

No Electron, no bundler: create a window, drop in some HTML, and you have an app.
Here's the whole thing:

```ocaml
let () =
  let w = Webview.create () in
  Webview.set_title w "My first owebview app";
  Webview.set_size w ~width:480 ~height:320 Webview.Hint_none;
  Webview.set_html w
    {|<!doctype html>
      <html>
        <body style="font-family: system-ui; text-align: center">
          <h1>Hello from OCaml 👋</h1>
          <p>Rendered by webview.</p>
        </body>
      </html>|};
  Webview.run w;
  Webview.destroy w
```

## See it run (30 seconds)

Clone the repo and launch the bundled example, `hellowv`:

```sh
git clone https://github.com/korkorran/owebview.git
cd owebview
dune exec examples/hellowv.exe
```

A window pops up with two buttons wired to OCaml: one adds two numbers, the other
reports your OS. The example loads its UI from real `.html` / `.css` / `.js`
files in [`examples/web/`](examples/web/) — peek at
[`examples/hellowv.ml`](examples/hellowv.ml) to see how JavaScript calls back
into OCaml.

## Use it in your own project

Pin the library with opam (the `webview.h` header is vendored, nothing to fetch):

```sh
opam pin add owebview https://github.com/korkorran/owebview.git
```

Then depend on it from your `dune` file:

```dune
(executable
 (name main)
 (libraries owebview.webview))
```

Drop the example above into `main.ml` and run `dune exec ./main.exe`. That's it.

## A little further

Once HTML rendering works, the fun part is the OCaml ↔ JavaScript bridge:

```ocaml
(* Expose window.add(a, b) to the page; the result is a JS Promise. *)
Webview.bind w "add" (fun id req ->
    let result =
      match Scanf.sscanf_opt req "[%d,%d]" (fun a b -> a + b) with
      | Some n -> string_of_int n
      | None -> "null"
    in
    Webview.return w id ~error:false ~result)
```

Other handy entry points: `Webview.navigate` (load a URL or a local `file://`
page), `Webview.init` / `Webview.eval` (inject JavaScript), and
`Webview.terminate` (close the window from code). The full API lives in
[`lib/webview.mli`](lib/webview.mli).

## Native dependencies

webview uses the system web engine, so you need its native libraries:

- **macOS** — WebKit / Cocoa, already provided by the system. Nothing to install.
- **Linux** — `gtk+-3.0` and `webkit2gtk-4.1` (the `-dev` packages). They are
  declared as opam `depexts`, so `opam pin` will offer to install them.
- **Windows** — not covered by this skeleton (would need WebView2).

The platform-specific compile/link flags are detected automatically at build
time (via `pkg-config` on Linux), so there's nothing to tweak by hand.

> ⚠️ This is a compact binding, not a full-featured library: things like
> `unbind`, `dispatch` and binding memory management are intentionally left out.
> It's a great starting point to build on.

## Contributing

Feedback is very welcome! This binding is developed and tested mainly on macOS,
so reports about building and running it on **Linux distributions** are
especially valuable — does it compile, do the `depexts` resolve, does the
`webkit2gtk-4.1` backend behave as expected on your distro?

If you give it a try on Linux, please open an issue with your distribution,
what worked and what didn't (build logs welcome). Pull requests improving
cross-platform support are happily accepted.

## License

[MIT](LICENSE).
