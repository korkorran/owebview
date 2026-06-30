/* OCaml C stubs for the webview library.
 *
 * Build assumptions:
 *  - vendor/webview.h is the single-header webview (0.12), which provides the
 *    C API *and* the implementation when included in a translation unit
 *    without WEBVIEW_HEADER defined. The 0.12 C API returns webview_error_t;
 *    these stubs check it and raise [Failure] on any non-OK status.
 *  - On macOS the backend uses the Objective-C runtime C API, so this
 *    compiles as plain C++ (no .mm needed) but must link WebKit/Cocoa/objc.
 */

#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <string>
#include <utility>

#define CAML_NAME_SPACE
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include <caml/threads.h>

#include "webview.h"

/* ---- pointer <-> OCaml value helpers ---- */

static inline webview_t wv_of_val(value v) {
  return reinterpret_cast<webview_t>(static_cast<intptr_t>(Nativeint_val(v)));
}

static inline value val_of_wv(webview_t w) {
  return caml_copy_nativeint(static_cast<intnat>(reinterpret_cast<intptr_t>(w)));
}

/* ---- error handling ----
 * The 0.12 C API returns webview_error_t (WEBVIEW_ERROR_OK == 0 on success).
 * wv_check raises [Failure] for any non-OK status; it must be called with the
 * OCaml runtime lock held (caml_failwith raises an OCaml exception).
 */

static const char *wv_strerror(webview_error_t err) {
  switch (err) {
    case WEBVIEW_ERROR_MISSING_DEPENDENCY:
      return "missing dependency";
    case WEBVIEW_ERROR_CANCELED:
      return "operation canceled";
    case WEBVIEW_ERROR_INVALID_STATE:
      return "invalid state";
    case WEBVIEW_ERROR_INVALID_ARGUMENT:
      return "invalid argument";
    case WEBVIEW_ERROR_UNSPECIFIED:
      return "unspecified error";
    case WEBVIEW_ERROR_OK:
      return "ok";
    case WEBVIEW_ERROR_DUPLICATE:
      return "already exists";
    case WEBVIEW_ERROR_NOT_FOUND:
      return "not found";
    default:
      return "unknown error";
  }
}

static void wv_check(const char *op, webview_error_t err) {
  if (err != WEBVIEW_ERROR_OK) {
    char msg[128];
    std::snprintf(msg, sizeof(msg), "%s: %s (code %d)", op, wv_strerror(err),
                  static_cast<int>(err));
    caml_failwith(msg);
  }
}

/* ---- binding bookkeeping ----
 * Each binding boxes its OCaml closure in a heap cell registered as a GC root,
 * and that cell is passed to webview as the user-data pointer. We track the
 * cells by (webview, name) so that unbind/destroy can free the cell and
 * unregister the root. The map is touched only by bind/unbind/destroy, which
 * run with the OCaml runtime lock held, so no extra synchronization is needed.
 */

struct ocaml_binding {
  value closure; /* registered global root */
};

static std::map<std::pair<webview_t, std::string>, ocaml_binding *> g_bindings;

static void free_binding(ocaml_binding *b) {
  caml_remove_generational_global_root(&b->closure);
  std::free(b);
}

extern "C" {

CAMLprim value ocaml_webview_create(value vdebug) {
  CAMLparam1(vdebug);
  /* Window argument is NULL: webview creates and owns the native window. */
  webview_t w = webview_create(Bool_val(vdebug), nullptr);
  if (w == nullptr)
    caml_failwith("webview_create returned NULL");
  CAMLreturn(val_of_wv(w));
}

CAMLprim value ocaml_webview_destroy(value vw) {
  CAMLparam1(vw);
  webview_t w = wv_of_val(vw);
  wv_check("webview_destroy", webview_destroy(w));
  /* The webview is gone; free any bindings still registered for it. */
  for (auto it = g_bindings.begin(); it != g_bindings.end();) {
    if (it->first.first == w) {
      free_binding(it->second);
      it = g_bindings.erase(it);
    } else {
      ++it;
    }
  }
  CAMLreturn(Val_unit);
}

/* Returns the library version info as an OCaml record (a tag-0 block whose
 * fields match Webview.version_info, in declaration order). */
CAMLprim value ocaml_webview_version(value vunit) {
  CAMLparam1(vunit);
  CAMLlocal1(vinfo);
  const webview_version_info_t *vi = webview_version();
  vinfo = caml_alloc_tuple(6);
  Store_field(vinfo, 0, Val_int(vi->version.major));
  Store_field(vinfo, 1, Val_int(vi->version.minor));
  Store_field(vinfo, 2, Val_int(vi->version.patch));
  Store_field(vinfo, 3, caml_copy_string(vi->version_number));
  Store_field(vinfo, 4, caml_copy_string(vi->pre_release));
  Store_field(vinfo, 5, caml_copy_string(vi->build_metadata));
  CAMLreturn(vinfo);
}

/* Native handles are returned as nativeint pointers (0n if unavailable); the
 * caller interprets them with platform-specific FFI. */
CAMLprim value ocaml_webview_get_window(value vw) {
  CAMLparam1(vw);
  void *h = webview_get_window(wv_of_val(vw));
  CAMLreturn(caml_copy_nativeint(reinterpret_cast<intnat>(h)));
}

CAMLprim value ocaml_webview_get_native_handle(value vw, value vkind) {
  CAMLparam2(vw, vkind);
  webview_native_handle_kind_t kind;
  switch (Int_val(vkind)) {
    case 1:
      kind = WEBVIEW_NATIVE_HANDLE_KIND_UI_WIDGET;
      break;
    case 2:
      kind = WEBVIEW_NATIVE_HANDLE_KIND_BROWSER_CONTROLLER;
      break;
    default:
      kind = WEBVIEW_NATIVE_HANDLE_KIND_UI_WINDOW;
      break;
  }
  void *h = webview_get_native_handle(wv_of_val(vw), kind);
  CAMLreturn(caml_copy_nativeint(reinterpret_cast<intnat>(h)));
}

CAMLprim value ocaml_webview_run(value vw) {
  CAMLparam1(vw);
  webview_t w = wv_of_val(vw);
  /* webview_run blocks; release the runtime lock so the GC and other OCaml
   * threads keep working. Bindings re-acquire it (see trampoline below). */
  caml_release_runtime_system();
  webview_error_t err = webview_run(w);
  caml_acquire_runtime_system();
  /* Check only after re-acquiring the lock, since wv_check may raise. */
  wv_check("webview_run", err);
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_webview_terminate(value vw) {
  CAMLparam1(vw);
  wv_check("webview_terminate", webview_terminate(wv_of_val(vw)));
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_webview_set_title(value vw, value vtitle) {
  CAMLparam2(vw, vtitle);
  wv_check("webview_set_title",
           webview_set_title(wv_of_val(vw), String_val(vtitle)));
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_webview_set_size(value vw, value vwidth, value vheight,
                                      value vhint) {
  CAMLparam4(vw, vwidth, vheight, vhint);
  webview_hint_t view_hint;
  switch (Int_val(vhint)) {
    case 1:
      view_hint = WEBVIEW_HINT_MIN;
      break;
    case 2:
      view_hint = WEBVIEW_HINT_MAX;
      break;
    case 3:
      view_hint = WEBVIEW_HINT_FIXED;
      break;
    default:
      view_hint = WEBVIEW_HINT_NONE;
      break;
  }
  wv_check("webview_set_size",
           webview_set_size(wv_of_val(vw), Int_val(vwidth), Int_val(vheight),
                            view_hint));
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_webview_navigate(value vw, value vurl) {
  CAMLparam2(vw, vurl);
  wv_check("webview_navigate",
           webview_navigate(wv_of_val(vw), String_val(vurl)));
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_webview_set_html(value vw, value vhtml) {
  CAMLparam2(vw, vhtml);
  wv_check("webview_set_html",
           webview_set_html(wv_of_val(vw), String_val(vhtml)));
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_webview_init(value vw, value vjs) {
  CAMLparam2(vw, vjs);
  wv_check("webview_init", webview_init(wv_of_val(vw), String_val(vjs)));
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_webview_eval(value vw, value vjs) {
  CAMLparam2(vw, vjs);
  wv_check("webview_eval", webview_eval(wv_of_val(vw), String_val(vjs)));
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_webview_return(value vw, value vid, value vstatus,
                                    value vresult) {
  CAMLparam4(vw, vid, vstatus, vresult);
  wv_check("webview_return",
           webview_return(wv_of_val(vw), String_val(vid), Int_val(vstatus),
                          String_val(vresult)));
  CAMLreturn(Val_unit);
}

/* ---- binding callbacks ----
 * The trampoline receives the heap cell (see "binding bookkeeping" above) as
 * its user-data argument and dispatches to the boxed OCaml closure.
 */

static void binding_trampoline(const char *id, const char *req, void *arg) {
  ocaml_binding *b = static_cast<ocaml_binding *>(arg);

  /* This runs from inside webview_run, where we released the runtime lock.
   * Re-acquire before touching any OCaml value or allocating. */
  caml_acquire_runtime_system();
  /* If your webview backend ever invokes this from a thread the OCaml runtime
   * doesn't know about, wrap with caml_c_thread_register/unregister too. */

  CAMLparam0();
  CAMLlocal2(vid, vreq);
  vid = caml_copy_string(id);
  vreq = caml_copy_string(req);
  caml_callback2(b->closure, vid, vreq);

  caml_release_runtime_system();
  CAMLdrop;
}

CAMLprim value ocaml_webview_bind(value vw, value vname, value vclosure) {
  CAMLparam3(vw, vname, vclosure);
  webview_t w = wv_of_val(vw);

  ocaml_binding *b =
      static_cast<ocaml_binding *>(std::malloc(sizeof(ocaml_binding)));
  if (b == nullptr)
    caml_failwith("out of memory in webview_bind");
  b->closure = vclosure;
  caml_register_generational_global_root(&b->closure);

  webview_error_t err =
      webview_bind(w, String_val(vname), binding_trampoline, b);
  if (err != WEBVIEW_ERROR_OK) {
    free_binding(b);
    wv_check("webview_bind", err); /* raises (e.g. duplicate name) */
  }
  /* Track for unbind/destroy. Build the std::string key only here, past any
   * point where wv_check could longjmp over its destructor. */
  g_bindings[std::make_pair(w, std::string(String_val(vname)))] = b;
  CAMLreturn(Val_unit);
}

CAMLprim value ocaml_webview_unbind(value vw, value vname) {
  CAMLparam2(vw, vname);
  webview_t w = wv_of_val(vw);

  /* Pass the name as a C string: no C++ object is alive when wv_check may
   * longjmp on a non-OK status (e.g. WEBVIEW_ERROR_NOT_FOUND). */
  wv_check("webview_unbind", webview_unbind(w, String_val(vname)));

  /* Removed on the C side; free our tracking cell and unregister the root. */
  auto it = g_bindings.find(std::make_pair(w, std::string(String_val(vname))));
  if (it != g_bindings.end()) {
    free_binding(it->second);
    g_bindings.erase(it);
  }
  CAMLreturn(Val_unit);
}

} /* extern "C" */
