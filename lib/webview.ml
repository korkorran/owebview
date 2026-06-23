type t
(* Runtime representation is a nativeint holding the C [webview_t] pointer.
   It is abstract in the .mli so callers cannot do arithmetic on it. *)

type hint =
  | Hint_none
  | Hint_min
  | Hint_max
  | Hint_fixed

(* The constant constructors above map to 0,1,2,3 at runtime, which matches
   WEBVIEW_HINT_NONE/MIN/MAX/FIXED, so they can be passed straight to C. *)

external _create : bool -> t = "ocaml_webview_create"
external destroy : t -> unit = "ocaml_webview_destroy"
external run : t -> unit = "ocaml_webview_run"
external terminate : t -> unit = "ocaml_webview_terminate"
external set_title : t -> string -> unit = "ocaml_webview_set_title"
external _set_size : t -> int -> int -> hint -> unit = "ocaml_webview_set_size"
external navigate : t -> string -> unit = "ocaml_webview_navigate"
external set_html : t -> string -> unit = "ocaml_webview_set_html"
external init : t -> string -> unit = "ocaml_webview_init"
external eval : t -> string -> unit = "ocaml_webview_eval"

external bind_raw : t -> string -> (string -> string -> unit) -> unit
  = "ocaml_webview_bind"

external _return : t -> string -> int -> string -> unit
  = "ocaml_webview_return"

exception Webview_error of string

let create ?(debug = false) () = _create debug
let set_size w ~width ~height hint = _set_size w width height hint
let return_raw w id ~error ~result = _return w id (if error then 1 else 0) result

let bind w name f =
  bind_raw w name (fun id req ->
      let result =
        try
          let args =
            match Yojson.Safe.from_string req with
            | `List args -> args
            | json -> [ json ] (* webview always sends an array; be lenient *)
          in
          Ok (f args)
        with
        | Webview_error msg -> Error (`String msg)
        | exn -> Error (`String (Printexc.to_string exn))
      in
      match result with
      | Ok json ->
          return_raw w id ~error:false ~result:(Yojson.Safe.to_string json)
      | Error json ->
          return_raw w id ~error:true ~result:(Yojson.Safe.to_string json))
