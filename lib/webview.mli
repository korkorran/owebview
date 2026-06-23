(** Minimal OCaml binding skeleton for https://github.com/webview/webview

    This binds the classic C API (webview ~0.10/0.11). See [scripts/fetch-webview.sh]
    to vendor a compatible [webview.h]. *)

(** An opaque handle to a webview instance (a C [webview_t]). *)
type t

(** Window sizing behaviour, mirrors [WEBVIEW_HINT_*]. *)
type hint =
  | Hint_none  (** width/height are the initial size *)
  | Hint_min  (** width/height are the minimum bounds *)
  | Hint_max  (** width/height are the maximum bounds *)
  | Hint_fixed  (** window is not resizable *)

(** [create ?debug ()] creates a new webview. When [debug] is true the
    developer tools are enabled (default [false]). *)
val create : ?debug:bool -> unit -> t

(** Destroy the webview and free associated resources. *)
val destroy : t -> unit

(** Run the main loop. {b Blocks} the calling thread until the window is
    closed and {b must be called on the main thread}. The OCaml runtime lock
    is released for the duration so other threads keep running. *)
val run : t -> unit

(** Stop the main loop started by {!run}. Safe to call from a binding. *)
val terminate : t -> unit

val set_title : t -> string -> unit
val set_size : t -> width:int -> height:int -> hint -> unit

(** Navigate to a URL (supports [http://], [https://], [file://], [data:]). *)
val navigate : t -> string -> unit

(** Load the given HTML string as the document. *)
val set_html : t -> string -> unit

(** Inject JS to be run on every page load, before page scripts. *)
val init : t -> string -> unit

(** Evaluate JS in the current page. *)
val eval : t -> string -> unit

(** [bind w name f] exposes a JS function [window.name(...)] that calls back
    into [f id req], where [req] is a JSON array string of the JS arguments.
    The callback must eventually answer with {!return} (using [id]).

    The closure is kept alive as a GC root for the lifetime of the process. *)
val bind : t -> string -> (string -> string -> unit) -> unit

(** [return w id ~error ~result] resolves (or rejects, if [error]) the JS
    promise associated with the call [id]. [result] must be a JSON value. *)
val return : t -> string -> error:bool -> result:string -> unit
