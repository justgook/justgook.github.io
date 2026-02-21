---
title: "This site"
description: "Personal portfolio driven entirely by Markdown. No build system, no npm, no lock files."
tags: [javascript, markdown, web]
status: "active"
featured: false
repo: "https://github.com/justgook/justgook.github.io"
---

## Concept

A personal site where content management is entirely Markdown-file based. No CMS, no database, no build pipeline.

- Add a post: create `content/posts/my-post.md`, register it in `manifest.json`
- Change the nav: edit `content/config.md`
- Update a dependency: bump the version in `Makefile`, run `make update`

## Tech

| Concern | Solution |
|---------|----------|
| Markdown parsing | marked.js (CDN, vendored) |
| Frontmatter | js-yaml (CDN, vendored) |
| Syntax highlighting | highlight.js (CDN, vendored) |
| Routing | Hash-based (`#/blog/slug`) |
| Dependency management | Makefile file targets |

## Running locally

```bash
make deps   # download vendor files (once)
make serve  # python3 -m http.server 8080
```

Open `http://localhost:8080`.
