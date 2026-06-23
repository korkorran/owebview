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

(** Raise this from a {!bind} callback to reject the JS promise with [msg]. *)
exception Webview_error of string

(** [bind w name f] exposes a JS function [window.name(...)]. The arguments
    passed from JS are decoded as a JSON array and handed to [f] as a list of
    {!Yojson.Safe.t} values; the value [f] returns is serialized back to
    resolve the JS promise.

    Raising {!Webview_error} (or any exception) rejects the promise instead.
    The callback is kept alive as a GC root for the lifetime of the process. *)
val bind : t -> string -> (Yojson.Safe.t list -> Yojson.Safe.t) -> unit

(** Lower-level variant of {!bind} working on raw strings: [f id req] receives
    the call id and the raw JSON array string, and is responsible for calling
    {!return_raw} itself (possibly later, for async results). *)
val bind_raw : t -> string -> (string -> string -> unit) -> unit

(** [return_raw w id ~error ~result] resolves (or rejects, if [error]) the JS
    promise associated with the call [id]. [result] must be a JSON value. *)
val return_raw : t -> string -> error:bool -> result:string -> unit
