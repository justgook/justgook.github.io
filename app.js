/**
 * app.js — Personal site engine
 *
 * Dependencies (globals from vendor/):
 *   marked     — markdown → html
 *   jsyaml     — YAML parsing (via js-yaml)
 *   hljs       — syntax highlighting
 */

/* ============================================================
   Frontmatter parser
   Splits ---\n...\n--- from the rest of the file.
   Returns { data: Object, content: string }
   ============================================================ */
function parseFrontmatter(raw) {
  const FM_RE = /^---\r?\n([\s\S]*?)\r?\n---\r?\n?([\s\S]*)$/;
  const match = raw.match(FM_RE);
  if (!match) return { data: {}, content: raw };
  let data = {};
  try {
    data = jsyaml.load(match[1]) ?? {};
  } catch (e) {
    console.warn('[app] frontmatter parse error:', e.message);
  }
  return { data, content: match[2] };
}

/* ============================================================
   Markdown renderer
   ============================================================ */
function setupMarked() {
  marked.setOptions({ gfm: true, breaks: false, pedantic: false });

  const renderer = new marked.Renderer();
  renderer.code = (text, lang) => {
    let highlighted = text;
    if (lang && hljs.getLanguage(lang)) {
      try { highlighted = hljs.highlight(text, { language: lang, ignoreIllegals: true }).value; } catch (_) { }
    } else {
      try { highlighted = hljs.highlightAuto(text).value; } catch (_) { }
    }
    return `<pre><code class="hljs language-${lang ?? ''}">${highlighted}</code></pre>`;
  };
  marked.use({ renderer });
}

function renderMarkdown(md) { return marked.parse(md); }

/* ============================================================
   Fetch helpers
   ============================================================ */
async function fetchText(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${url}`);
  return res.text();
}

async function fetchJSON(url) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`HTTP ${res.status}: ${url}`);
  return res.json();
}

/* ============================================================
   Site config — loaded once from content/config.md
   ============================================================ */
let siteConfig = {
  title: 'Kazys Kalabibishkis',
  tagline: '',
  nav: [],
  social: [],
};

async function loadConfig() {
  try {
    const raw = await fetchText('content/config.md');
    const { data } = parseFrontmatter(raw);
    siteConfig = { ...siteConfig, ...data };
  } catch (e) {
    console.warn('[app] config load failed, using defaults:', e.message);
  }
}

/* ============================================================
   Manifest — loaded once from content/manifest.json
   Shape:
     {
       page_size: number,
       posts:    { total, pages, items: [ { slug, file, date, title,
                    description, tags, featured, status } ] },
       projects: { total, pages, items: [ ... ] }
     }
   ============================================================ */
let manifest = {
  page_size: 10,
  posts: { total: 0, pages: 1, items: [] },
  projects: { total: 0, pages: 1, items: [] },
};

async function loadManifest() {
  try {
    const raw = await fetchJSON('content/manifest.json');
    // Normalise: support both legacy flat-array shape and new paginated shape
    manifest = {
      page_size: raw.page_size ?? 10,
      posts: Array.isArray(raw.posts)
        ? { total: raw.posts.length, pages: 1, items: raw.posts }
        : (raw.posts ?? { total: 0, pages: 1, items: [] }),
      projects: Array.isArray(raw.projects)
        ? { total: raw.projects.length, pages: 1, items: raw.projects }
        : (raw.projects ?? { total: 0, pages: 1, items: [] }),
    };
  } catch (e) {
    console.warn('[app] manifest load failed:', e.message);
  }
}

/* ============================================================
   Manifest accessors
   Items already carry title/date/description/tags/featured/status
   from the generated manifest — no per-file fetch needed for lists.
   ============================================================ */

/** Return items for a given section and 1-based page number */
function pageItems(section, page) {
  const s = manifest[section] ?? { items: [] };
  const ps = manifest.page_size;
  const start = (page - 1) * ps;
  return s.items.slice(start, start + ps);
}

/** Find a single item by slug across posts or projects */
function findEntry(section, slug) {
  return (manifest[section]?.items ?? []).find(e => e.slug === slug) ?? null;
}

/* ============================================================
   DOM helpers
   ============================================================ */
const $ = (sel) => document.querySelector(sel);

function setMain(html) { $('#site-main').innerHTML = html; }

function showLoading() {
  setMain(`<div class="loading">
    <span class="loading-dot"></span>
    <span class="loading-dot"></span>
    <span class="loading-dot"></span>
  </div>`);
}

function formatDate(str) {
  if (!str) return '';
  try {
    // YYYY-MM-DD parsed as local date to avoid UTC shift
    const [y, m, d] = String(str).split('-').map(Number);
    return new Date(y, (m || 1) - 1, d || 1)
      .toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
  } catch (_) { return String(str); }
}

function tagsHTML(tags) {
  if (!tags?.length) return '';
  return `<div class="card-tags">${tags.map(t => `<span class="tag">${t}</span>`).join('')}</div>`;
}

/* ============================================================
   Pagination controls
   ============================================================ */
function paginationHTML(section, currentPage, totalPages) {
  if (totalPages <= 1) return '';
  const parts = [];
  for (let p = 1; p <= totalPages; p++) {
    const href = `#/${section}${p > 1 ? `/page/${p}` : ''}`;
    parts.push(`<a href="${href}" class="page-btn${p === currentPage ? ' active' : ''}">${p}</a>`);
  }
  return `<nav class="pagination" aria-label="Pages">${parts.join('')}</nav>`;
}

/* ============================================================
   Header / Footer population
   ============================================================ */
function buildNav(currentRoute) {
  const navEl = $('#site-nav');
  const titleEl = $('#site-title');
  if (titleEl) titleEl.textContent = siteConfig.title;
  document.title = siteConfig.title;
  if (!navEl) return;

  const navLinks = (siteConfig.nav ?? []).map(item => {
    const route = item.route ?? '#/';
    const href = route.startsWith('#') ? route : `#${route}`;
    // Active if the current path starts with this nav route (handles sub-pages)
    const isActive = currentRoute && currentRoute.startsWith(item.route ?? route);
    return `<a href="${href}" class="${isActive ? 'active' : ''}">${item.label}</a>`;
  }).join('');

  const socialLinks = (siteConfig.social ?? []).map(s =>
    `<a href="${s.url}" target="_blank" rel="noopener noreferrer">${s.label}</a>`
  ).join('');

  navEl.innerHTML = navLinks + (socialLinks
    ? `<div class="social-links">${socialLinks}</div>` : '');
}

function buildFooter() {
  const el = $('#site-footer');
  if (!el) return;
  const year = new Date().getFullYear();
  const social = (siteConfig.social ?? []).map(s =>
    `<a href="${s.url}" target="_blank" rel="noopener noreferrer">${s.label}</a>`
  ).join('');
  el.innerHTML = `
    <span>&copy; ${year} ${siteConfig.title}</span>
    ${social ? `<div class="footer-social">${social}</div>` : ''}`;
}

/* ============================================================
   Views
   ============================================================ */

/** Render a card from a manifest item (data fields are top-level) */
function cardHTML(item, section) {
  const href = `#/${section}/${item.slug}`;
  const date = item.date ? `<span class="card-meta">${formatDate(item.date)}</span>` : '';
  const status = item.status ? `<span class="card-meta">${item.status}</span>` : '';
  return `
    <a class="card" href="${href}">
      <div class="card-title">${item.title ?? item.slug}</div>
      ${date}${status}
      <div class="card-desc">${item.description ?? ''}</div>
      ${tagsHTML(item.tags)}
    </a>`;
}

/** Home — hero from home.md + featured cards */
async function renderHome() {
  showLoading();
  const homeRaw = await fetchText('content/home.md').catch(() => '');
  const { content: heroContent } = parseFrontmatter(homeRaw);
  const heroHtml = renderMarkdown(heroContent);

  const featuredPosts = manifest.posts.items.filter(i => i.featured);
  const featuredProjects = manifest.projects.items.filter(i => i.featured);

  const postCardsHtml = featuredPosts.length
    ? featuredPosts.map(i => cardHTML(i, 'blog')).join('')
    : '<p style="color:var(--text-faint);font-size:.85rem;">No featured posts yet.</p>';

  const projectCardsHtml = featuredProjects.length
    ? featuredProjects.map(i => cardHTML(i, 'projects')).join('')
    : '<p style="color:var(--text-faint);font-size:.85rem;">No featured projects yet.</p>';

  setMain(`
    <div class="home-hero">
      <div class="prose">${heroHtml}</div>
    </div>
    <section class="home-section">
      <div class="home-section-header">
        <h2>Featured Posts</h2>
        <a href="#/blog">All posts &rarr;</a>
      </div>
      <div class="card-grid">${postCardsHtml}</div>
    </section>
    <section class="home-section">
      <div class="home-section-header">
        <h2>Featured Projects</h2>
        <a href="#/projects">All projects &rarr;</a>
      </div>
      <div class="card-grid">${projectCardsHtml}</div>
    </section>
  `);
}

/** Blog index — paginated list */
async function renderBlog(page = 1) {
  showLoading();
  const { total, pages } = manifest.posts;
  const items = pageItems('posts', page);

  const listItems = items.length
    ? items.map(i => `
        <a class="post-list-item" href="#/blog/${i.slug}">
          <span class="post-list-date">${formatDate(i.date)}</span>
          <span class="post-list-title">${i.title ?? i.slug}</span>
          <span class="post-list-desc">${i.description ?? ''}</span>
        </a>`).join('')
    : '<p style="color:var(--text-faint)">No posts yet.</p>';

  setMain(`
    <h1 class="page-title">Blog</h1>
    <p class="page-subtitle">${total} post${total !== 1 ? 's' : ''}</p>
    <div class="post-list">${listItems}</div>
    ${paginationHTML('blog', page, pages)}
  `);
}

/** Projects index — paginated cards */
async function renderProjects(page = 1) {
  showLoading();
  const { total, pages } = manifest.projects;
  const items = pageItems('projects', page);

  const cardsHtml = items.length
    ? items.map(i => cardHTML(i, 'projects')).join('')
    : '<p style="color:var(--text-faint)">No projects yet.</p>';

  setMain(`
    <h1 class="page-title">Projects</h1>
    <p class="page-subtitle">${total} project${total !== 1 ? 's' : ''}</p>
    <div class="project-grid">${cardsHtml}</div>
    ${paginationHTML('projects', page, pages)}
  `);
}

/** Single post — full file fetch (needs body) */
async function renderPost(slug) {
  showLoading();
  const entry = findEntry('posts', slug);
  if (!entry) { renderNotFound(`blog/${slug}`); return; }

  let raw;
  try { raw = await fetchText(entry.file); }
  catch (_) { renderNotFound(entry.file); return; }

  const { data, content } = parseFrontmatter(raw);
  const bodyHtml = renderMarkdown(content);
  const metaParts = [];
  if (data.date) metaParts.push(`<span>${formatDate(data.date)}</span>`);
  if (data.tags?.length) metaParts.push(tagsHTML(data.tags));

  setMain(`
    <article>
      <div class="prose-header">
        <h1>${data.title ?? slug}</h1>
        ${metaParts.length ? `<div class="prose-meta">${metaParts.join('<span class="sep">&middot;</span>')}</div>` : ''}
        <p style="margin-top:.75rem"><a href="#/blog">&larr; All posts</a></p>
      </div>
      <div class="prose">${bodyHtml}</div>
    </article>
  `);
}

/** Single project — full file fetch (needs body) */
async function renderProject(slug) {
  showLoading();
  const entry = findEntry('projects', slug);
  if (!entry) { renderNotFound(`projects/${slug}`); return; }

  let raw;
  try { raw = await fetchText(entry.file); }
  catch (_) { renderNotFound(entry.file); return; }

  const { data, content } = parseFrontmatter(raw);
  const bodyHtml = renderMarkdown(content);

  const links = [];
  if (data.repo) links.push(`<a class="btn" href="${data.repo}" target="_blank" rel="noopener">Repo &nearr;</a>`);
  if (data.demo) links.push(`<a class="btn" href="${data.demo}" target="_blank" rel="noopener">Demo &nearr;</a>`);

  const metaParts = [];
  if (data.status) metaParts.push(`<span>${data.status}</span>`);
  if (data.tags?.length) metaParts.push(tagsHTML(data.tags));

  setMain(`
    <article>
      <div class="prose-header">
        <h1>${data.title ?? slug}</h1>
        ${metaParts.length ? `<div class="prose-meta">${metaParts.join('<span class="sep">&middot;</span>')}</div>` : ''}
        ${links.length ? `<div class="prose-links">${links.join('')}</div>` : ''}
        <p style="margin-top:.75rem"><a href="#/projects">&larr; All projects</a></p>
      </div>
      <div class="prose">${bodyHtml}</div>
    </article>
  `);
}

/** Generic page from content/<slug>.md */
async function renderPage(slug) {
  showLoading();
  let raw;
  try { raw = await fetchText(`content/${slug}.md`); }
  catch (_) { renderNotFound(slug); return; }

  const { data, content } = parseFrontmatter(raw);
  const bodyHtml = renderMarkdown(content);
  setMain(`
    <article>
      ${data.title ? `<div class="prose-header"><h1>${data.title}</h1></div>` : ''}
      <div class="prose">${bodyHtml}</div>
    </article>
  `);
}

function renderNotFound(path) {
  setMain(`
    <div class="error-view">
      <h2>Page not found</h2>
      <code>${path}</code>
      <p style="margin-top:1.5rem"><a href="#/">Go home</a></p>
    </div>
  `);
}

/* ============================================================
   Router
   Routes:
     #/                     → home
     #/blog                 → blog page 1
     #/blog/page/2          → blog page 2
     #/blog/<slug>          → single post
     #/projects             → projects page 1
     #/projects/page/2      → projects page 2
     #/projects/<slug>      → single project
     #/resume               → resume page
     #/contact              → contact page
   ============================================================ */
async function route() {
  const hash = location.hash || '#/';
  const path = hash.replace(/^#\/?/, '');
  const parts = path ? path.split('/') : [];
  const [section, sub, pageStr] = parts;

  buildNav(`/${section ?? ''}`);

  switch (section) {
    case '':
    case undefined:
      await renderHome();
      break;

    case 'blog':
      if (!sub) await renderBlog(1);
      else if (sub === 'page' && pageStr) await renderBlog(Math.max(1, parseInt(pageStr, 10) || 1));
      else await renderPost(sub);
      break;

    case 'projects':
      if (!sub) await renderProjects(1);
      else if (sub === 'page' && pageStr) await renderProjects(Math.max(1, parseInt(pageStr, 10) || 1));
      else await renderProject(sub);
      break;

    case 'resume':
    case 'contact':
      await renderPage(section);
      break;

    default:
      try { await renderPage(section); }
      catch (_) { renderNotFound(section); }
  }

  window.scrollTo(0, 0);
}

/* ============================================================
   Mobile nav toggle
   ============================================================ */
function setupNavToggle() {
  const btn = $('#nav-toggle');
  const nav = $('#site-nav');
  if (!btn || !nav) return;
  btn.addEventListener('click', () => {
    const open = nav.classList.toggle('open');
    btn.setAttribute('aria-expanded', String(open));
  });
  nav.addEventListener('click', e => {
    if (e.target.tagName === 'A') {
      nav.classList.remove('open');
      btn.setAttribute('aria-expanded', 'false');
    }
  });
}

/* ============================================================
   Boot
   ============================================================ */
async function init() {
  setupMarked();
  await Promise.all([loadConfig(), loadManifest()]);
  buildFooter();
  setupNavToggle();
  await route();
  window.addEventListener('hashchange', route);
}

init().catch(err => {
  console.error('[app] fatal init error:', err);
  setMain(`<div class="error-view"><h2>Failed to load site</h2><code>${err.message}</code></div>`);
});
