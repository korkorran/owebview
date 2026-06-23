let () =
  let w = Webview.create ~debug:true () in
  Webview.set_title w "Hello from OCaml";
  Webview.set_size w ~width:480 ~height:320 Webview.Hint_none;

  (* Expose window.add(a, b) to JS. Arguments arrive decoded as JSON values,
     and the returned JSON value resolves the JS promise. *)
  Webview.bind w "add" (fun args ->
      match args with
      | [ `Int a; `Int b ] -> `Int (a + b)
      | _ -> raise (Webview.Webview_error "add expects two integers"));

  Webview.set_html w
    {|<!doctype html>
<html>
  <body>
    <h2>owebview</h2>
    <button onclick="add(20, 22).then(r => document.querySelector('#out').textContent = r)">
      add(20, 22)
    </button>
    <pre id="out"></pre>
  </body>
</html>|};

  Webview.run w;
  Webview.destroy w
