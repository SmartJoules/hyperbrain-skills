---
name: prd-to-html-prototype
description: Turn a PRD (product requirements doc, feature spec, or written requirements) into a standalone, self-contained HTML/CSS prototype that follows the JouleTRACK / DeJoule design theme — the dark teal header, side navigation, light page background, white cards, Work Sans typography, and the --n-* design tokens. Use whenever someone provides a PRD, feature description, or screen requirements and wants a clickable visual prototype or mockup that looks like JouleTRACK before building the real Angular feature.
---

# PRD → HTML Prototype (JouleTRACK / DeJoule theme)

**Author:** Atif Salafi <atif8486@gmail.com>
**Purpose:** Generate standalone HTML prototypes that match the JouleTRACK look & feel from a PRD
**Version:** 1.0.0

---

## 🎯 When to Use This Skill

Use when someone:
- Provides a **PRD, feature spec, or written requirements** and wants a visual prototype/mockup
- Wants to see a screen "in the JouleTRACK style" before building the Angular feature
- Needs a quick clickable HTML mock to validate layout/flow with stakeholders

Output is a **single self-contained `.html` file** (inline CSS, CDN fonts only) that opens in any browser — NOT production Angular code. It mirrors JouleTRACK's chrome (header, nav, background, cards) so stakeholders see the real product context.

---

## 📐 Workflow

1. **Read the PRD.** Extract: screen name, primary user, the main entities/data shown, key actions, states (loading/empty/error), and any tables/charts/forms/cards.
2. **Pick a layout archetype** (see below) that fits the PRD: list/table page, dashboard with widgets, detail/drawer page, or form/wizard.
3. **Assemble the shell** — always include the JouleTRACK header + side nav + light content area (copy the template below verbatim, then fill the content region).
4. **Build the content** using the component snippets (cards, tables, buttons, toggles, badges, KPI tiles) so it matches real JouleTRACK components.
5. **Add the required states** the PRD implies: loading skeleton, empty state, error state, and partial-data handling — show them as toggleable sections or comments so reviewers see them.
6. **Save** to `prototypes/<feature-name>.html` (or where the user asks) and tell the user to open it in a browser.

> KISS: a prototype is for validating look/flow. Don't wire a real backend, don't add a build step, don't pull in a framework. Inline everything; the only external resources are Google Fonts.

---

## 🎨 JouleTRACK Design Tokens (use these EXACT values)

```css
:root {
  /* Brand */
  --n-primary-color: #072B31;        /* dark teal — header, active nav, primary text accents */
  --n-primary-color-a15: rgba(7,43,49,.15);
  --n-primary-color-a05: rgba(7,43,49,.05);
  --n-accent-color: #28939D;         /* lighter teal — secondary accent, links */
  --n-sys-orange: #FF9900;           /* primary CTA / orange button */
  --n-sys-green: #228B22;            /* success / active / on */
  --n-sys-red: #FF0F00;              /* error / alert */
  --n-in-range: #00B277;             /* good data */
  --n-too-warm: #FF2056;
  --n-too-cold: #598DFF;

  /* Surfaces & text */
  --n-screen-bg-color: #f6f6f6;      /* page background */
  --n-highlight-color: #F5F6FB;      /* hover / active-nav background */
  --n-white: #FFFFFF;
  --n-black: #1A1A1A;                /* primary text */
  --n-title-color: rgba(0,0,0,.6);   /* secondary text */
  --n-border-color: #E8E8E8;

  /* Elevation */
  --n-primary-shadow: 0 4px 15px rgba(189,189,189,.25);   /* cards */
  --n-header-shadow: 0 4px 24px rgba(189,189,189,.25);    /* header */

  /* Shape & type */
  --n-radius: 4px;        /* standard */
  --n-radius-card: 10px;  /* control/floating cards */
  --n-font: 'Work Sans','Roboto',sans-serif;
  --n-header-h: 70px;
  --n-nav-w: 260px;
}
```

**Typography:** Work Sans (weights 400/500/600/700). Body 14px / line-height 20px. Page heading 20px/500. Card title 16px/400. Secondary label 12px. Primary text `#1A1A1A`, secondary `rgba(0,0,0,.6)`.

**Spacing scale:** 4, 8, 12, 16, 20, 24 px.

**Icons:** Material Symbols Rounded (primary). Load via Google Fonts (see template).

---

## 🧱 Base Shell Template (copy verbatim, fill `<!-- CONTENT -->`)

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>JouleTRACK Prototype — {{SCREEN_NAME}}</title>
<link href="https://fonts.googleapis.com/css2?family=Work+Sans:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Rounded:opsz,wght,FILL,GRAD@20..48,100..700,0..1,-50..200" rel="stylesheet">
<style>
:root{
  --n-primary-color:#072B31;--n-accent-color:#28939D;--n-sys-orange:#FF9900;
  --n-sys-green:#228B22;--n-sys-red:#FF0F00;--n-screen-bg-color:#f6f6f6;
  --n-highlight-color:#F5F6FB;--n-white:#fff;--n-black:#1A1A1A;
  --n-title-color:rgba(0,0,0,.6);--n-border-color:#E8E8E8;
  --n-primary-shadow:0 4px 15px rgba(189,189,189,.25);
  --n-radius:4px;--n-radius-card:10px;--n-font:'Work Sans','Roboto',sans-serif;
  --n-header-h:70px;--n-nav-w:260px;
}
*{box-sizing:border-box}
body{margin:0;font-family:var(--n-font);font-size:14px;line-height:20px;color:var(--n-black);background:var(--n-screen-bg-color)}
.material-symbols-rounded{font-variation-settings:'FILL' 1,'wght' 300,'GRAD' 0,'opsz' 24;vertical-align:middle}

/* Header */
.jt-header{position:fixed;top:0;left:0;right:0;height:var(--n-header-h);z-index:3;
  display:flex;align-items:center;justify-content:space-between;padding:0 24px;
  background:var(--n-primary-color);color:var(--n-white);box-shadow:var(--n-primary-shadow)}
.jt-h-left,.jt-h-right{display:flex;align-items:center;gap:16px}
.jt-logo{font-weight:700;font-size:20px;letter-spacing:.5px}
.jt-sep{width:1px;height:28px;background:rgba(255,255,255,.4)}
.jt-site{display:flex;align-items:center;gap:12px}
.jt-site-icon{width:40px;height:40px;border-radius:50%;background:#0e3b42;border:1px solid rgba(255,255,255,.4);
  display:flex;align-items:center;justify-content:center}
.jt-site-name{font-size:14px;font-weight:500}.jt-site-id{font-size:12px;opacity:.7}
.jt-iconbtn{width:44px;height:44px;border-radius:50%;border:1px solid rgba(255,255,255,.4);
  background:transparent;color:#fff;display:flex;align-items:center;justify-content:center;cursor:pointer}
.jt-avatar{width:44px;height:44px;border-radius:50%;border:1px solid rgba(255,255,255,.4);background:#0e3b42;
  display:flex;align-items:center;justify-content:center}
.jt-badge{position:relative}
.jt-badge::after{content:'3';position:absolute;top:-2px;right:-2px;background:var(--n-sys-red);color:#fff;
  font-size:10px;border-radius:50%;width:16px;height:16px;display:flex;align-items:center;justify-content:center}

/* Shell */
.jt-shell{display:flex;padding-top:var(--n-header-h);min-height:100vh}
.jt-nav{width:var(--n-nav-w);padding:16px 12px;flex:0 0 auto}
.jt-navlink{display:flex;align-items:center;gap:12px;padding:12px;border-radius:var(--n-radius);
  color:var(--n-black);text-decoration:none;font-size:14px;cursor:pointer}
.jt-navlink .material-symbols-rounded{font-size:20px;color:var(--n-title-color)}
.jt-navlink:hover{background:var(--n-highlight-color)}
.jt-navlink.active{background:var(--n-highlight-color);color:var(--n-primary-color);font-weight:500}
.jt-navlink.active .material-symbols-rounded{color:var(--n-primary-color)}
.jt-main{flex:1;padding:20px 24px}
.jt-page-title{font-size:20px;font-weight:500;margin:0 0 16px}

/* Card */
.jt-card{background:var(--n-white);border-radius:var(--n-radius);box-shadow:var(--n-primary-shadow);padding:20px;margin-bottom:16px}
.jt-card-title{font-size:16px;font-weight:500;margin:0 0 12px}

/* KPI tile */
.jt-kpis{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:16px;margin-bottom:16px}
.jt-kpi{background:var(--n-white);border-radius:var(--n-radius);box-shadow:var(--n-primary-shadow);padding:16px}
.jt-kpi .v{font-size:24px;font-weight:600;color:var(--n-primary-color)}
.jt-kpi .l{font-size:12px;color:var(--n-title-color)}

/* Table */
.jt-table{width:100%;border-collapse:collapse;background:var(--n-white)}
.jt-table th{text-align:left;font-size:12px;color:var(--n-title-color);font-weight:600;padding:15px 12px;border-bottom:1px solid var(--n-border-color)}
.jt-table td{font-size:14px;padding:12px;border-bottom:1px solid var(--n-border-color)}
.jt-table tr:hover td{background:var(--n-highlight-color)}

/* Buttons */
.jt-btn{font-family:var(--n-font);font-size:14px;border:none;border-radius:var(--n-radius);padding:9px 16px;cursor:pointer}
.jt-btn-orange{background:var(--n-sys-orange);color:#fff}
.jt-btn-grey{background:#e8e8e8;color:#7a7a7a}
.jt-btn-outline{background:#fff;color:var(--n-sys-orange);border:1px solid var(--n-sys-orange)}

/* Badges / status */
.jt-badge-pill{font-size:12px;padding:4px 10px;border-radius:12px}
.jt-on{background:rgba(34,139,34,.12);color:var(--n-sys-green)}
.jt-off{background:rgba(255,15,0,.10);color:var(--n-sys-red)}
.jt-warn{background:rgba(255,153,0,.12);color:#b36b00}

/* Toggle (custom-toggle look) */
.jt-toggle{width:80px;height:26px;border:1px solid #bfbfbf;border-radius:20px;display:inline-flex;align-items:center;
  padding:2px;gap:6px;font-size:12px;cursor:pointer;background:#fff}
.jt-toggle .knob{width:20px;height:20px;border-radius:50%;background:var(--n-sys-green);color:#fff;
  display:flex;align-items:center;justify-content:center;font-size:14px}

/* States */
.jt-empty,.jt-error{text-align:center;color:var(--n-title-color);padding:40px 16px}
.jt-error{color:var(--n-sys-red)}
.jt-skeleton{background:linear-gradient(90deg,#eee 25%,#f5f5f5 37%,#eee 63%);background-size:400% 100%;
  animation:sk 1.4s ease infinite;border-radius:4px;height:14px;margin:8px 0}
@keyframes sk{0%{background-position:100% 50%}100%{background-position:0 50%}}
</style>
</head>
<body>
  <header class="jt-header">
    <div class="jt-h-left">
      <span class="material-symbols-rounded" style="cursor:pointer">menu</span>
      <span class="jt-logo">DeJoule</span>
      <span class="jt-sep"></span>
      <div class="jt-site">
        <div class="jt-site-icon"><span class="material-symbols-rounded">apartment</span></div>
        <div><div class="jt-site-name">{{SITE_NAME}}</div><div class="jt-site-id">ID: {{SITE_ID}}</div></div>
      </div>
    </div>
    <div class="jt-h-right">
      <button class="jt-iconbtn"><span class="material-symbols-rounded">build</span></button>
      <button class="jt-iconbtn jt-badge"><span class="material-symbols-rounded">notifications</span></button>
      <div class="jt-site" style="gap:8px">
        <div class="jt-avatar"><span class="material-symbols-rounded">person</span></div>
        <div><div class="jt-site-name">{{USER_NAME}}</div><div class="jt-site-id">{{USER_ROLE}}</div></div>
      </div>
    </div>
  </header>

  <div class="jt-shell">
    <nav class="jt-nav">
      <a class="jt-navlink active"><span class="material-symbols-rounded">dashboard</span> {{SCREEN_NAME}}</a>
      <a class="jt-navlink"><span class="material-symbols-rounded">monitoring</span> Energy</a>
      <a class="jt-navlink"><span class="material-symbols-rounded">schedule</span> Scheduler</a>
      <a class="jt-navlink"><span class="material-symbols-rounded">warning</span> Alerts</a>
      <a class="jt-navlink"><span class="material-symbols-rounded">settings</span> Settings</a>
    </nav>
    <main class="jt-main">
      <h1 class="jt-page-title">{{SCREEN_NAME}}</h1>
      <!-- CONTENT -->
    </main>
  </div>
</body>
</html>
```

---

## 🧩 Content Snippets (drop into `<!-- CONTENT -->`)

**KPI row**
```html
<div class="jt-kpis">
  <div class="jt-kpi"><div class="v">128 kW</div><div class="l">Current Load</div></div>
  <div class="jt-kpi"><div class="v">21.4°C</div><div class="l">Avg Temp</div></div>
  <div class="jt-kpi"><div class="v">92%</div><div class="l">Comfort Index</div></div>
</div>
```

**Card + table**
```html
<div class="jt-card">
  <div style="display:flex;justify-content:space-between;align-items:center">
    <div class="jt-card-title">Assets</div>
    <button class="jt-btn jt-btn-orange">+ Add</button>
  </div>
  <table class="jt-table">
    <thead><tr><th>Name</th><th>Type</th><th>Status</th><th>Mode</th></tr></thead>
    <tbody>
      <tr><td>AHU-1</td><td>Air Handler</td><td><span class="jt-badge-pill jt-on">On</span></td><td>Auto</td></tr>
      <tr><td>Chiller-2</td><td>Chiller</td><td><span class="jt-badge-pill jt-off">Off</span></td><td>Manual</td></tr>
    </tbody>
  </table>
</div>
```

**States (always include the ones the PRD implies)**
```html
<div class="jt-card"><div class="jt-skeleton" style="width:40%"></div><div class="jt-skeleton"></div><div class="jt-skeleton" style="width:80%"></div></div>
<div class="jt-card"><div class="jt-empty"><span class="material-symbols-rounded" style="font-size:40px">inbox</span><p>No data for this site yet.</p></div></div>
<div class="jt-card"><div class="jt-error"><span class="material-symbols-rounded" style="font-size:40px">error</span><p>Couldn't load data. Retry.</p></div></div>
```

**Toggle / button row**
```html
<div class="jt-toggle"><span class="knob"><span class="material-symbols-rounded" style="font-size:14px">check</span></span> On</div>
<button class="jt-btn jt-btn-outline">Cancel</button>
```

---

## ✅ Quality Checklist (before handing over the prototype)

- [ ] Uses the JouleTRACK shell: dark teal `#072B31` header (70px), side nav, `#f6f6f6` background, white cards with the standard shadow
- [ ] Work Sans font + Material Symbols Rounded icons loaded
- [ ] Colors come ONLY from the `--n-*` tokens (no invented brand colors)
- [ ] Every screen in the PRD is represented; primary action(s) visible
- [ ] Loading, empty, and error states shown (and partial-data if the PRD has multiple data sources)
- [ ] Single self-contained `.html` file — opens with no build step, no backend
- [ ] Told the user the file path and that it's a visual prototype, not production Angular

> When ready to build for real, hand off to the **jouletrack-angular** skill — the prototype becomes the visual spec, and the Angular implementation must follow OnPush/RxJS/ViewEncapsulation rules from **engineering-standards**.
