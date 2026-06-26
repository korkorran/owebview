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
      (Filename.dirname (Webview.Utils.exe_dir ()))
      (Filename.concat "share" (Filename.concat "owebview" "web"))
  in
  if has_index installed then installed
  else Filename.concat (Webview.Utils.asset_dir ()) "web"

let () =
  let w = Webview.create ~debug:true () in
  Webview.set_title w "Hello from OCaml";
  Webview.set_size w ~width:480 ~height:320 Webview.Hint_none;

  (* Expose window.add(a, b) to JS. [req] is a JSON array of the arguments. *)
  Webview.bind w "add" (fun id req ->
      Printf.printf "binding called: id=%s req=%s\n%!" id req;
      let result =
        match Scanf.sscanf_opt req "[%d,%d]" (fun a b -> a + b) with
        | Some n -> string_of_int n
        | None -> "null"
      in
      Webview.return w id ~error:false ~result);

  (* Expose window.os_type() to JS. Returns the host OS as a JSON string. *)
  Webview.bind w "os_type" (fun id req ->
      Printf.printf "binding called: id=%s req=%s\n%!" id req;
      let result = Printf.sprintf "%S" (Utils.detect_os ()) in
      Webview.return w id ~error:false ~result);

  (* Load the page from on-disk files (web/) instead of an inline HTML string.
     The CSS and JS referenced with relative paths in index.html are resolved
     relative to that file. We locate the web/ directory from the executable
     location, so it works both installed and from the build tree. *)
  let index = Filename.concat (web_dir ()) "index.html" in
  Webview.navigate w ("file://" ^ index);

  Webview.run w;
  Webview.destroy w
