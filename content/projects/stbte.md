---
title: "stbte — headless tilemap editor"
description: "Headless WASM port of Sean Barrett's stb_tilemap_editor.h. 73% smaller, pure JS frontend."
tags: [zig, wasm, c, tools]
status: "active"
featured: true
repo: "https://github.com/justgook/stbte"
---

## Overview

`stbte` is a headless WebAssembly port of [Sean Barrett's](https://github.com/nothings) `stb_tilemap_editor.h`.

The original library is a single-header C implementation of a full tilemap editor — including its own IMGUI, rendering, and SDL integration. This port strips all of that out, leaving only the core data model and editing logic (~1120 lines, down from 4173).

A JavaScript frontend does all rendering, input handling, and UI — communicating with the WASM module via a clean API over `SharedArrayBuffer`.

## Architecture

```
C / WASM (Zig cross-compile)        JavaScript frontend
────────────────────────────        ──────────────────────────
stb_tilemap_editor.h (stripped)     index.html + vanilla JS
main.c (64 exports)             ←→  SharedArrayBuffer
72KB .wasm binary                   Canvas 2D rendering
```

## API design

The API is unified around `stbte_apply(tm, x0, y0, x1, y1)` which dispatches by current tool:

| Tool | Behaviour |
|------|-----------|
| Select | Updates selection rect |
| Brush | Paints current tile to area |
| Erase | Clears tiles in area |
| Eyedropper | Samples tile at point |
| Fill | Flood-fills from point |

## What was removed

- All drawing functions and IMGUI widgets
- Mouse/keyboard event dispatch
- SDL integration
- Font data, color tables, panel layout
- ~30 UI-only struct fields

## Build

```bash
zig build-exe src/main.c \
  -target wasm32-freestanding \
  -O ReleaseFast \
  -o build/stbte.wasm
```

Output: **72KB** with 64 exports. All tests pass.
