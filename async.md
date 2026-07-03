# Using Owebview with Lwt

The function `bind` is not compatible directly with Lwt because the expected return type is `unit` (instead of `unit Lwt.t`)

This is because the function `Owebview.run` start an event loop, and the calls to the functions declared with bind are executed inside the loop.

In order to use OWebview with a monadic interface is to use two threads:

1. The main thread will hold the application
2. One dedicated for the Owebview event loop.

With Lwt, this can be done using `Lwt_preemptive` :

```
let run_window () =
  let w = Webview.create ~debug:true () in
  Webview.set_title w "Hello from OCaml";
  Webview.set_size w ~width:480 ~height:320 Webview.Hint_none;

  ...

  Webview.run w;
  Webview.destroy w

let () =
  let window = Lwt_preemptive.detach run_window () in
  Lwt_main.run (window)

```

Now, you can use `Lwt_preemptive.run_in_main` to switch to the main thread and keep the UI responsiveness:


```
(** [lwt_bind f] will call the function [f] in a promise in the main thead *)
let lwt_bind : Webview.t -> string -> (string -> string -> unit Lwt.t) -> unit =
 fun w name f ->
  Webview.bind w name (fun id req ->
      Lwt_preemptive.run_in_main (fun () ->
          Lwt.return @@ Lwt.async (fun () -> f id req)))


lwt_bind w "add" (fun id req ->
    Printf.printf "binding called <add>: id=%s req=%s\n%!" id req;
    let result =
      match Scanf.sscanf_opt req "[%d,%d]" (fun a b -> a + b) with
      | Some n -> string_of_int n
      | None -> "null"
    in
    let () = Webview.return w id ~error:false ~result in
    Lwt.return_unit);
```

Thoses functions are known to be safe for beeing called from another thread:

- `Owebview.return`
- `Owebview.terminate`