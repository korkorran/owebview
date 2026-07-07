let () =
  let w = Webview.create () in
  Webview.set_title w "Timer";
  Webview.set_size w ~width:320 ~height:220 Webview.Hint_none;

  (* The timer itself lives in the page (HTML/CSS/JS); no binding is needed.
     The web/ directory is located relative to the executable. *)
  let index = Filename.concat (Webview.Utils.web_dir ()) "index.html" in
  Webview.navigate w ("file://" ^ index);

  (* Listen on the terminal: every time the user presses <Enter>, toggle the
     timer. Reading stdin happens on a background thread, so we must NOT call
     the webview directly from there — [dispatch] runs the JS call on the UI
     thread, which is the whole point of this example. *)
  print_endline "Press <Enter> in this terminal to pause/resume the timer.";
  let running = ref true in
  let _ =
    Thread.create
      (fun () ->
        try
          while true do
            ignore (input_line stdin);
            (* [input_line] blocks until <Enter>; [dispatch] fires here. *)
            let cmd = if !running then "stop()" else "start()" in
            running := not !running;
            Printf.printf "timer %s\n%!"
              (if !running then "resumed" else "paused");
            Webview.dispatch w (fun w -> Webview.eval w cmd)
          done
        with End_of_file -> ())
      ()
  in

  Webview.run w;
  Webview.destroy w
