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

external bind : t -> string -> (string -> string -> unit) -> unit
  = "ocaml_webview_bind"

external _return : t -> string -> int -> string -> unit
  = "ocaml_webview_return"

let create ?(debug = false) () = _create debug
let set_size w ~width ~height hint = _set_size w width height hint
let return w id ~error ~result = _return w id (if error then 1 else 0) result
