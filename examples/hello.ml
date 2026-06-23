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
