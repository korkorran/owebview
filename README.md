# owebview

Squelette de binding OCaml pour la librairie [webview](https://github.com/webview/webview).

> ⚠️ Point de départ, pas une lib complète. Il manque volontairement : `unbind`,
> `dispatch`, `get_window`, la gestion de la mémoire des bindings, et le support
> multi-plateforme du linking (cf. `lib/dune`).

## Architecture

| Fichier | Rôle |
|---|---|
| `lib/webview.mli` / `.ml` | API OCaml + déclarations `external` |
| `lib/webview_stubs.cpp` | Glue C ↔ OCaml (lock runtime, GC roots des callbacks) |
| `lib/dune` | Compile le stub C++ et linke les libs natives |
| `examples/hello.ml` | Fenêtre minimale avec un binding JS → OCaml |
| `scripts/fetch-webview.sh` | Récupère un `webview.h` compatible dans `vendor/` |

L'implémentation choisit des **stubs C manuels** plutôt que `ctypes` afin de
montrer explicitement les deux points sensibles :

1. **`webview_run` est bloquant** → `caml_release_runtime_system()` autour de
   l'appel, et `caml_acquire_runtime_system()` à l'entrée de chaque callback.
2. **Survie des closures** → chaque closure passée à `bind` est enregistrée via
   `caml_register_generational_global_root` pour ne pas être collectée.

## Prérequis

- OCaml + dune (`opam install dune`)
- Un compilateur C++
- Les dépendances natives :
  - **macOS** : WebKit / Cocoa (fournis par le système)
  - **Linux** : `gtk+-3.0` + `webkit2gtk-4.1` (paquets `-dev`)
  - **Windows** : WebView2 (non couvert par ce squelette)

## Build & run

```sh
# 1. Vendorer le header (version single-header compatible)
./scripts/fetch-webview.sh

# 2. Compiler et lancer l'exemple
dune exec examples/hello.exe
```

Sur **Linux**, remplacer la ligne `c_library_flags` de `lib/dune` par la sortie de :

```sh
pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.1
```

## Pistes pour aller plus loin

- Intégrer `yojson` pour (dé)sérialiser proprement `req`/`result`.
- Implémenter `unbind` + libérer les `ocaml_binding` (map `name -> cell`).
- Découverte des flags via `dune-configurator` (pkg-config programmatique).
- Migrer vers l'API webview récente (codes d'erreur `webview_error_t`).
