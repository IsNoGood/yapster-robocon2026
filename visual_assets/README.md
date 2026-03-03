# Northcode Visual Assets

This folder contains Northcode-branded assets for presentations, web pages, and other visual materials.

**Usage:**
- 🎨 **Marp Presentations** - Demo slides with Northcode branding
- 🌐 **Yapster Web Interface** - Apply Northcode styling to the app
- 📄 **Documentation** - Branded diagrams and images

## Northcode Brand Guidelines (for AI & Humans)

### General Principles
- Always follow NorthCode's brand guidelines
- Keep slides minimal, clear, and professional. Avoid clutter

### Colors

**Primary palette:**
- Mint `#a9f5e4` (accent color)
- Black `#1c1c1c`
- White `#f5f5f5`

```css
--nc-mint: #a9f5e4      /* Northcode mint - pääväri */
--nc-black: #1c1c1c     /* Musta */
--nc-white: #f5f5f5     /* Valkoinen */
```

**Usage:**
- Use mint sparingly as an accent
- Prefer monochrome (black/white) slides with mint highlights

### Typography

**Fonts:**
- **IBM Plex Serif Regular** - Headlines
- **IBM Plex Mono Regular** - Body text, captions, tables, charts

**Rules:**
- Use regular weights only. Bold only if absolutely necessary
- Headlines must be 2–3× larger than body text
- Limit to max. 2 text sizes per slide
- Tracking: Serif -25/1000 em, Mono 0
- Keep typography clear, strong, and high contrast

### Logos

**Available logos:**
- `N___Compact_Logo_Mint_RGB.svg` - Kompakti logo mint-värisenä
- `N___Compact_Logo_Black_RGB.svg` - Kompakti logo mustana
- `N___Horiz_Logo_Mint_RGB.svg` - Horisontaalinen logo mint-värisenä
- `N___Horiz_Logo_Black_RGB.svg` - Horisontaalinen logo mustana
- `N___Stacked_Logo_Mint_RGB.svg` - Pinottu logo mint-värisenä
- `N___Stacked_Logo_Black_RGB.svg` - Pinottu logo mustana

**Logo placement:**
- Top-right for regular slides
- Centered for opening/closing slides
- Respect safe areas: equal to the height of "N" (or ½ height in compact logo)

**Allowed combinations:**
- Black logo on mint background (`#a9f5e4`)
- Mint logo on black (`#1c1c1c`)
- White logo on black
- Black logo on white
- On calm images only if contrast is strong
- Never place logo on distracting backgrounds

### Layout

- Use simple grid-based layouts (4-column system if multi-column)
- Keep margins generous and consistent
- **Alignment:**
  - Top-right logo for content slides
  - Centered logo for title/closing slides

### Charts & Tables

- Strip away unnecessary lines, boxes, or colors
- Black/white by default
- Mint only as highlight

### Slide Types

- **Opening slide**: Centered horizontal logo, mint background, large headline
- **Content slide**: Top-right stacked logo, black background, clear headline + body
- **Closing slide**: Centered horizontal logo, mint background, "Thank you" message

## Assets Structure

### Fonts
Located in `fonts/` folder:
- IBM Plex Serif Regular (`fonts/IBM_Plex_Serif/IBMPlexSerif-Regular.ttf`)
- IBM Plex Mono Regular (`fonts/IBM_Plex_Mono/IBMPlexMono-Regular.ttf`)

**Web Usage:**
```css
@font-face {
  font-family: 'IBM Plex Serif';
  src: url('/visual_assets/fonts/IBM_Plex_Serif/IBMPlexSerif-Regular.ttf') format('truetype');
}

@font-face {
  font-family: 'IBM Plex Mono';
  src: url('/visual_assets/fonts/IBM_Plex_Mono/IBMPlexMono-Regular.ttf') format('truetype');
}
```

### Images
Located in `images/` folder:
- `guard-rails.png` - Guard rails concept illustration
- `nc_logos/` - Northcode logo variations (SVG)

### Themes
- `northcode-theme.css` - Marp theme with Northcode branding
- Can be adapted for web styling

## Using Assets in Yapster Web App

Apply Northcode branding to the frontend:

```css
/* In frontend/src/App.css or index.css */
:root {
  --nc-mint: #a9f5e4;
  --nc-black: #1c1c1c;
  --nc-white: #f5f5f5;
}

body {
  font-family: 'IBM Plex Mono', monospace;
  background-color: var(--nc-black);
  color: var(--nc-white);
}

h1, h2, h3 {
  font-family: 'IBM Plex Serif', serif;
}

.accent {
  color: var(--nc-mint);
}
```

## Creating Demo Presentations

You can use these assets to create branded Marp presentations for Yapster demos.

### Marp CLI asennus

```bash
npm install -g @marp-team/marp-cli
```

### Create a presentation (example)

Create a markdown file (e.g., `yapster-demo.md`) with Marp frontmatter:

```markdown
---
marp: true
theme: northcode
paginate: true
html: true
footer: 'Northcode | AI-Assisted Development Demo'
---

<!-- _class: lead -->

## Yapster Demo

AI-Assisted Development
From Idea to Production in 15 Minutes

---

## Current State

- ✅ Production app deployed
- ✅ Health checks working
- ❌ No business features yet

---

## Demo Flow

1. Investigation (2 min)
2. Create Issue (3 min)
3. Implement Feature (7 min)
4. Deploy to Production (3 min)

---

<!-- Add your slides here -->
```

### PDF:n generointi

```bash
marp yapster-demo.md --pdf --allow-local-files -o yapster-demo.pdf
```

### HTML:n generointi (interaktiivinen)

```bash
marp yapster-demo.md --allow-local-files -o yapster-demo.html
```

### PowerPoint:n generointi

```bash
marp yapster-demo.md --pptx --allow-local-files -o yapster-demo.pptx
```

### Live preview (development)

```bash
marp --server --allow-local-files .
```

## Muistiinpanot

- `--allow-local-files` tarvitaan jotta Marp voi ladata paikalliset fontit ja kuvat
- Teema on optimoitu 16:9 esitysformaatille
- Logot ladataan SVG-muodossa parhaan laadun takaamiseksi
- Markdown-tiedostot käyttävät `theme: northcode` CSS-teemaa