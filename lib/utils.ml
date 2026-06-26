(* Filesystem helpers for locating on-disk assets relative to the running
   executable, independently of the current working directory. *)

(* Absolute path to the directory containing the running executable. *)
let exe_dir () =
  let dir = Filename.dirname Sys.executable_name in
  if Filename.is_relative dir then Filename.concat (Sys.getcwd ()) dir else dir

(* Directory to resolve on-disk assets against, independently of the cwd.

   When launched via [dune exec], the executable lives under
   [<root>/_build/<context>/...] but the source assets are not copied there.
   We map such a path back to the matching source directory so the assets are
   found. When run from an installed location (no [_build] segment) the
   executable directory is used as-is. *)
let asset_dir () =
  let rec strip = function
    | "_build" :: _context :: rest -> rest (* drop "_build/<context>/" *)
    | x :: rest -> x :: strip rest
    | [] -> []
  in
  String.concat Filename.dir_sep
    (strip (String.split_on_char '/' (exe_dir ())))

(* Locate the directory holding the web assets (index.html + style.css +
   app.js), independently of the current working directory.

   - Installed layout: the binary lives in [<prefix>/bin/], and the assets are
     installed under [<prefix>/share/owebview/web/] (see examples/dune).
   - Dev layout (dune exec): the assets are read from the source tree, located
     relative to the executable in dune's build tree (see Webview.Utils). *)
let web_dir () =
  let has_index dir = Sys.file_exists (Filename.concat dir "index.html") in
  let installed =
    Filename.concat
      (Filename.dirname (exe_dir ()))
      (Filename.concat "share" (Filename.concat "owebview" "web"))
  in
  if has_index installed then installed
  else Filename.concat (asset_dir ()) "web"
