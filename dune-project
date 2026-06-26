(lang dune 3.0)

(generate_opam_files true)

(name owebview)
(source
 (github korkorran/owebview))
(license MIT)
(authors "Frédéric Lang")
(maintainers "frederic.ln.lang@gmail.com")

(package
 (name owebview)
 (synopsis "OCaml bindings for the webview library")
 (description
  "A small OCaml binding skeleton for the webview library\n(https://github.com/webview/webview): window creation, navigation,\nbidirectional JS <-> OCaml bindings, plus an example application.\n\nThe native webview dependencies are not packaged here: on macOS they are\nprovided by the system (WebKit/Cocoa); on Linux install gtk+-3.0 and\nwebkit2gtk-4.1 (-dev packages). A compatible webview.h must be vendored\nfirst with scripts/fetch-webview.sh.")
 (depends
  (ocaml
   (>= 4.08))))
