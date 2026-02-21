---
title: "Hello, World"
date: 2026-02-21
description: "First post. About the site and why I built it this way."
tags: [meta, web]
featured: true
---

## Why a static site with no build system?

I've used plenty of static site generators — Hugo, Jekyll, Eleventy, Astro. They're all fine tools. But at some point I wanted something simpler: a folder of markdown files and a single HTML page that reads them.

No `node_modules`. No lock files. No transpilation step. Just `make deps` once to download a handful of vendor JS files, then `python3 -m http.server`.

## The stack

- **[marked.js](https://marked.js.org/)** — Markdown → HTML, GFM support built in
- **[js-yaml](https://github.com/nodeca/js-yaml)** — parses YAML frontmatter
- **[highlight.js](https://highlightjs.org/)** — syntax highlighting
- Vanilla JS ES modules for routing and rendering
- A `Makefile` that downloads vendor files as file targets

All dependencies are vendored — committed to the repo, pinned to specific versions, updated on demand via `make update`.

## How content works

Every post and project is a Markdown file with YAML frontmatter:

```yaml
---
title: "Post title"
date: 2026-01-15
description: "Short summary"
tags: [tag1, tag2]
featured: true
---
```

A `content/manifest.json` registers all files. The JS app fetches the manifest on load, then fetches individual files on demand as you navigate.

Navigation, site title, and social links come from `content/config.md` — also frontmatter-driven.

## What I'd add later

- A search box (client-side, no server needed)
- RSS feed generation via a small script
- Image lazy loading
- Reading time estimates

For now, this is enough.
