SHELL := bash
.ONESHELL:
.SECONDEXPANSION:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

ifdef V
Q=
WGET:=wget
else
Q=@
MAKEFLAGS += --no-print-directory
WGET:=wget -q --show-progress
endif

uniq = $(if $1,$(firstword $1) $(call uniq,$(filter-out $(firstword $1),$1)))

MKDIR_P ?= mkdir -p
CP      ?= cp -f

# ---------------------------------------------------------------------------
# Vendor versions — bump here to upgrade, then: make update
# ---------------------------------------------------------------------------
MARKED_VERSION    := 12.0.0
JSYAML_VERSION    := 4.1.0
HLJS_VERSION      := 11.9.0

# ---------------------------------------------------------------------------
# Vendor output files (used as make targets — make only downloads if missing)
# ---------------------------------------------------------------------------
VENDOR_DIR  := vendor

MARKED_JS   := $(VENDOR_DIR)/marked.min.js
JSYAML_JS   := $(VENDOR_DIR)/js-yaml.min.js
HLJS_JS     := $(VENDOR_DIR)/highlight.min.js
HLJS_CSS    := $(VENDOR_DIR)/highlight-github-dark.min.css

VENDOR_FILES := $(MARKED_JS) $(JSYAML_JS) $(HLJS_JS) $(HLJS_CSS)

# ---------------------------------------------------------------------------
# CDN base URLs
# ---------------------------------------------------------------------------
MARKED_URL  := https://cdn.jsdelivr.net/npm/marked@$(MARKED_VERSION)/marked.min.js
JSYAML_URL  := https://cdn.jsdelivr.net/npm/js-yaml@$(JSYAML_VERSION)/dist/js-yaml.min.js
HLJS_URL    := https://cdnjs.cloudflare.com/ajax/libs/highlight.js/$(HLJS_VERSION)/highlight.min.js
HLJS_CSS_URL:= https://cdnjs.cloudflare.com/ajax/libs/highlight.js/$(HLJS_VERSION)/styles/github-dark.min.css

# ---------------------------------------------------------------------------
# Content / manifest
# ---------------------------------------------------------------------------
PAGE_SIZE   := 10
CONTENT_DIR := content
MANIFEST    := $(CONTENT_DIR)/manifest.json

POSTS_DIR   := $(CONTENT_DIR)/posts
PROJECTS_DIR:= $(CONTENT_DIR)/projects

# Wildcard over source files — manifest is rebuilt whenever any .md changes
POST_FILES    := $(wildcard $(POSTS_DIR)/*.md)
PROJECT_FILES := $(wildcard $(PROJECTS_DIR)/*.md)

# ---------------------------------------------------------------------------
# Phony targets
# ---------------------------------------------------------------------------
.PHONY: all deps update manifest serve clean

all: deps manifest

## manifest — regenerate content/manifest.json from posts/ and projects/
manifest: $(MANIFEST)

## deps — download missing vendor files only
deps: $(VENDOR_FILES)

## update — force re-download all vendor files (use after bumping versions)
update:
	$(Q)rm -f $(VENDOR_FILES)
	$(Q)$(MAKE) deps

## serve — local dev server on :8080
serve:
	$(Q)echo "Serving on http://localhost:8800"
	$(Q)python3 -m http.server 8800

## clean — remove vendor dir and generated manifest
clean:
	$(Q)rm -rf $(VENDOR_DIR)
	$(Q)rm -f $(MANIFEST)

# ---------------------------------------------------------------------------
# File targets — each vendor file is downloaded only when it does not exist.
# Changing the version variables above + `make update` triggers re-download.
# ---------------------------------------------------------------------------

$(VENDOR_DIR):
	$(Q)$(MKDIR_P) $@

$(MARKED_JS): | $(VENDOR_DIR)
	$(Q)echo "  DL  $@"
	$(Q)$(WGET) -O $@ $(MARKED_URL)

$(JSYAML_JS): | $(VENDOR_DIR)
	$(Q)echo "  DL  $@"
	$(Q)$(WGET) -O $@ $(JSYAML_URL)

$(HLJS_JS): | $(VENDOR_DIR)
	$(Q)echo "  DL  $@"
	$(Q)$(WGET) -O $@ $(HLJS_URL)

$(HLJS_CSS): | $(VENDOR_DIR)
	$(Q)echo "  DL  $@"
	$(Q)$(WGET) -O $@ $(HLJS_CSS_URL)

# ---------------------------------------------------------------------------
# manifest.json — generated from posts/ and projects/ .md frontmatter
#
# Depends on every .md file in both dirs; rebuilt whenever any of them
# changes (or is added/removed, because the wildcard re-evaluates).
#
# Output shape:
#   {
#     "page_size": N,
#     "posts":    [ { slug, file, date, title, description, tags, featured } … ],
#     "projects": [ { slug, file, title, description, tags, status, featured } … ]
#   }
#
# Posts are sorted newest-first by the `date:` frontmatter field.
# Projects retain filesystem order (add an `order:` field if you need explicit sorting).
# ---------------------------------------------------------------------------

# awk script: reads a single .md file, emits one JSON object line.
# Called as:  awk -v file=<path> -v slug=<slug> -f scripts/fm2json.awk <file>
# We inline it here via a Make define so no extra file is needed.
define FM2JSON_AWK
BEGIN {
    in_fm = 0; done = 0
    date=""; title=""; desc=""; tags=""; featured="false"; status=""
}
/^---$$/ {
    if (!in_fm && !done) { in_fm = 1; next }
    if (in_fm)           { in_fm = 0; done = 1; next }
}
in_fm {
    if (/^date:/)        { sub(/^date:[[:space:]]*/,""); gsub(/"/,""); date = $$0 }
    if (/^title:/)       { sub(/^title:[[:space:]]*/,""); gsub(/^"|"$$/,""); title = $$0 }
    if (/^description:/) { sub(/^description:[[:space:]]*/,""); gsub(/^"|"$$/,""); desc = $$0 }
    if (/^featured:/)    { sub(/^featured:[[:space:]]*/,""); featured = ($$0 == "true") ? "true" : "false" }
    if (/^status:/)      { sub(/^status:[[:space:]]*/,""); gsub(/^"|"$$/,""); status = $$0 }
    if (/^tags:/) {
        sub(/^tags:[[:space:]]*/,"")
        gsub(/[\[\]]/,"")
        n = split($$0, a, /,[[:space:]]*/); tags=""
        for (i=1;i<=n;i++) { gsub(/^[[:space:]]+|[[:space:]]+$$/,"",a[i]); tags = tags (i>1?",":"") "\"" a[i] "\"" }
    }
}
END {
    printf "{\"slug\":\"%s\",\"file\":\"%s\",\"date\":\"%s\",\"title\":\"%s\",\"description\":\"%s\",\"tags\":[%s],\"featured\":%s,\"status\":\"%s\"}\n", \
        slug, file, date, title, desc, tags, featured, status
}
endef
export FM2JSON_AWK

# Helper: emit sorted JSON array + pagination block from a stream of JSON lines.
# Usage: echo "<lines>" | $(call PAGINATE,$(PAGE_SIZE))
# Outputs the full JSON array value including pagination metadata.
define PAGINATE_AWK
BEGIN { n=0; ps=$(PAGE_SIZE) }
{ lines[n++] = $$0 }
END {
    pages = int((n + ps - 1) / ps); if (pages < 1) pages = 1
    printf "  \"page_size\": %d,\n  \"total\": %d,\n  \"pages\": %d", ps, n, pages
}
endef
export PAGINATE_AWK

$(MANIFEST): $(POST_FILES) $(PROJECT_FILES)
	$(Q)echo "  GEN $@"
	$(Q)
	# --- collect posts (one JSON object per line) ---------------------------
	post_lines=""
	for f in $(POST_FILES); do
	    slug=$$(basename "$$f" .md)
	    line=$$(awk -v file="$$f" -v slug="$$slug" "$$FM2JSON_AWK" "$$f")
	    post_lines="$$post_lines$$line"$$'\n'
	done

	# sort posts newest-first: prepend the date field, sort -r, strip prefix
	sorted_posts=""
	if [ -n "$$post_lines" ]; then
	    sorted_posts=$$(printf '%s' "$$post_lines" | \
	        grep -v '^$$' | \
	        awk '{ d=$$0; sub(/.*"date":"/, "", d); sub(/".*/, "", d); print d "\t" $$0 }' | \
	        sort -r | \
	        cut -f2-)
	fi

	# --- collect projects (filesystem order) --------------------------------
	project_lines=""
	for f in $(PROJECT_FILES); do
	    slug=$$(basename "$$f" .md)
	    line=$$(awk -v file="$$f" -v slug="$$slug" "$$FM2JSON_AWK" "$$f")
	    project_lines="$$project_lines$$line"$$'\n'
	done
	project_lines=$$(printf '%s' "$$project_lines" | grep -v '^$$')

	# --- compute pagination counts ------------------------------------------
	post_count=$$(printf '%s' "$$sorted_posts" | grep -c . || true)
	proj_count=$$(printf '%s' "$$project_lines" | grep -c . || true)
	post_pages=$$(( (post_count + $(PAGE_SIZE) - 1) / $(PAGE_SIZE) ))
	proj_pages=$$(( (proj_count + $(PAGE_SIZE) - 1) / $(PAGE_SIZE) ))
	[ "$$post_pages" -lt 1 ] && post_pages=1
	[ "$$proj_pages" -lt 1 ] && proj_pages=1

	# --- emit JSON ----------------------------------------------------------
	{
	    echo '{'
	    echo "  \"page_size\": $(PAGE_SIZE),"
	    echo "  \"posts\": {"
	    echo "    \"total\": $$post_count,"
	    echo "    \"pages\": $$post_pages,"
	    echo "    \"items\": ["
	    first=1
	    while IFS= read -r line; do
	        [ -z "$$line" ] && continue
	        [ "$$first" -eq 1 ] && first=0 || printf ',\n'
	        printf '      %s' "$$line"
	    done <<< "$$sorted_posts"
	    [ "$$post_count" -gt 0 ] && echo
	    echo "    ]"
	    echo "  },"
	    echo "  \"projects\": {"
	    echo "    \"total\": $$proj_count,"
	    echo "    \"pages\": $$proj_pages,"
	    echo "    \"items\": ["
	    first=1
	    while IFS= read -r line; do
	        [ -z "$$line" ] && continue
	        [ "$$first" -eq 1 ] && first=0 || printf ',\n'
	        printf '      %s' "$$line"
	    done <<< "$$project_lines"
	    [ "$$proj_count" -gt 0 ] && echo
	    echo "    ]"
	    echo "  }"
	    echo '}'
	} > $@

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
.PHONY: help
help:
	$(Q)grep -E '^## ' Makefile | sed 's/^## //'
