module C = Configurator.V1

(* C++ standard required to compile webview_stubs.cpp, on every platform. *)
let std_flags = [ "-std=c++11" ]

(* macOS: WebKit/Cocoa are system frameworks, no pkg-config needed. *)
let macos_link_flags =
  [ "-lc++"; "-lobjc"; "-framework"; "WebKit"; "-framework"; "Cocoa" ]

(* Linux: the webview backend is GTK 3 + WebKitGTK. *)
let linux_packages = [ "gtk+-3.0"; "webkit2gtk-4.1" ]

(* Query pkg-config for each package and merge the results. Returns None if
   pkg-config is unavailable or any package is missing. *)
let linux_flags c =
  match C.Pkg_config.get c with
  | None -> None
  | Some pc ->
      let results = List.map (fun p -> C.Pkg_config.query pc ~package:p) linux_packages in
      if List.mem None results then None
      else
        let confs =
          List.map (function Some conf -> conf | None -> assert false) results
        in
        let cflags = List.concat (List.map (fun (c : C.Pkg_config.package_conf) -> c.cflags) confs) in
        let libs = List.concat (List.map (fun (c : C.Pkg_config.package_conf) -> c.libs) confs) in
        Some (cflags, libs)

let () =
  C.main ~name:"webview" (fun c ->
      let system =
        match C.ocaml_config_var c "system" with Some s -> s | None -> ""
      in
      let cflags, link_flags =
        match system with
        | "macosx" -> (std_flags, macos_link_flags)
        | _ -> (
            (* Assume a Linux system with pkg-config + the -dev packages. *)
            match linux_flags c with
            | Some (cflags, libs) -> (std_flags @ cflags, libs)
            | None ->
                C.die
                  "could not detect the webview native dependencies via \
                   pkg-config (need %s). Install the -dev packages (see the \
                   package depexts)."
                  (String.concat " " linux_packages))
      in
      C.Flags.write_sexp "c_flags.sexp" cflags;
      C.Flags.write_sexp "c_library_flags.sexp" link_flags)
