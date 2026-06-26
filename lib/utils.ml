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
