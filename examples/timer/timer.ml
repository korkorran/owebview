let () =
  let w = Webview.create () in
  Webview.set_title w "Timer";
  Webview.set_size w ~width:320 ~height:220 Webview.Hint_none;

  (* The whole timer lives in the page (HTML/CSS/JS); no binding is needed —
     OCaml only opens the window and loads the page. The web/ directory is
     located relative to the executable (see Webview.Utils.web_dir). *)
  let index = Filename.concat (Webview.Utils.web_dir ()) "index.html" in
  Webview.navigate w ("file://" ^ index);

  Webview.run w;
  Webview.destroy w
