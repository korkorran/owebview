(** Minimal OCaml binding skeleton for https://github.com/webview/webview

    This binds the classic C API (webview 0.12). *)

type t
(** An opaque handle to a webview instance (a C [webview_t]). *)

(** Window sizing behaviour, mirrors [WEBVIEW_HINT_*]. *)
type hint =
  | Hint_none  (** width/height are the initial size *)
  | Hint_min  (** width/height are the minimum bounds *)
  | Hint_max  (** width/height are the maximum bounds *)
  | Hint_fixed  (** window is not resizable *)

val create : ?debug:bool -> unit -> t
(** [create ?debug ()] creates a new webview. When [debug] is true the developer
    tools are enabled (default [false]). *)

val destroy : t -> unit
(** Destroy the webview and free associated resources. *)

val run : t -> unit
(** Run the main loop. {b Blocks} the calling thread until the window is closed
    and {b must be called on the main thread}. The OCaml runtime lock is
    released for the duration so other threads keep running. *)

val terminate : t -> unit
(** Stop the main loop started by {!run}. Safe to call from a binding. *)

val set_title : t -> string -> unit
val set_size : t -> width:int -> height:int -> hint -> unit

val navigate : t -> string -> unit
(** Navigate to a URL (supports [http://], [https://], [file://], [data:]). *)

val set_html : t -> string -> unit
(** Load the given HTML string as the document. *)

val init : t -> string -> unit
(** Inject JS to be run on every page load, before page scripts. *)

val eval : t -> string -> unit
(** Evaluate JS in the current page. *)

val bind : t -> string -> (string -> string -> unit) -> unit
(** [bind w name f] exposes a JS function [window.name(...)] that calls back
    into [f id req], where [req] is a JSON array string of the JS arguments. The
    callback must eventually answer with {!return} (using [id]).

    The closure is kept alive as a GC root for the lifetime of the process. *)

val return : t -> string -> error:bool -> result:string -> unit
(** [return w id ~error ~result] resolves (or rejects, if [error]) the JS
    promise associated with the call [id]. [result] must be a JSON value. *)

(** Filesystem helpers for locating on-disk assets (HTML/CSS/JS) relative to the
    running executable, independently of the current working directory. *)
module Utils : sig
  val exe_dir : unit -> string
  (** Absolute path to the directory containing the running executable. *)

  val asset_dir : unit -> string
  (** Directory to resolve on-disk assets against. When launched via
      [dune exec], the executable lives under [_build/<context>/], where the
      source assets are not copied; this maps such a path back to the matching
      source directory. From an installed location the executable directory is
      used as-is. *)

  val web_dir : unit -> string
  (** Directory to resolve web assets against. This is [asset_dir]/web. *)
end
