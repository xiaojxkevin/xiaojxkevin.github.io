# Jinxi Xiao's Personal Homepage

My academic personal homepage, built with Jekyll and the [Minimal Light](https://github.com/yaoyao-liu/minimal-light) theme. Deployed via GitHub Pages.

## Quick Start

### Local Development with Docker

Make sure [Docker](https://docs.docker.com/get-docker/) is installed, then run:

```bash
docker compose up --build
```

The site will be available at <http://localhost:4000> with live reload enabled.

### Deployment

Push to `main` branch — GitHub Pages will build and deploy automatically.

## Readings Section (`/readings/`)

The site includes a browsable mirror of the [policy_readings](https://github.com/xiaojxkevin/policy_readings) Obsidian vault (paper notes on embodied AI / robot policy), available at <https://xiaojxkevin.github.io/readings/>.

- The vault is vendored in as a **git submodule** at `_readings_src/` (no changes are made to the source repo).
- `scripts/sync_readings.rb` converts the Obsidian vault (embeds `![[img]]`, internal links, frontmatter) into a Jekyll collection under `_readings/`, copies referenced images into `assets/readings/`, and generates overview + category index pages.
- Generated files (`_readings/`, `assets/readings/`, `_data/readings_index.yml`) are git-ignored and regenerated on every build (local Docker and CI).

### Local preview after changes

`docker compose up` (see [Local Development with Docker](#local-development-with-docker)) auto-runs the conversion script, so `_readings/` is regenerated on every edit — no manual step needed. After verifying locally, push to deploy as described in [Deployment](#deployment).

### Updating the `policy_readings` submodule

When the source vault is updated upstream, sync the submodule and re-pin the pointer:

```bash
git submodule update --remote _readings_src   # or: cd _readings_src && git pull
docker compose up                             # verify locally
git add _readings_src                         # IMPORTANT: commit the new submodule commit
git commit -m "update policy_readings submodule"
git push origin main
```

The main repo only stores a commit pointer to the submodule (not its files), so this `git add _readings_src` step is required or CI will keep building the old vault content. CI fetches submodules automatically (`submodules: recursive`).

## Project Structure

```
├── _config.yml          # Site configuration (title, links, etc.)
├── index.md             # Homepage content (Markdown + HTML)
├── _data/
│   ├── publications.yml # Publication entries
│   └── projects.yml     # Project entries
├── _includes/
│   ├── publications.md  # Publications section template
│   ├── projects.md      # Projects section template
│   └── services.md      # Services section template
├── _layouts/
│   └── homepage.html    # Main HTML layout
├── _sass/               # Stylesheets (SCSS)
├── assets/              # Images, CSS, JS, and files
├── Dockerfile           # Docker image definition
└── docker-compose.yml   # Docker Compose config
```

## Customizing

- **Site info & links**: Edit `_config.yml`
- **Page content**: Edit `index.md`
- **Publications**: Edit `_data/publications.yml`
- **Projects**: Edit `_data/projects.yml`
- **Layout**: Edit `_layouts/homepage.html`
- **Styles**: Edit `_sass/minimal-light.scss`

## Acknowledgements

Based on the [Minimal Light](https://github.com/yaoyao-liu/minimal-light) theme by [Yaoyao Liu](https://github.com/yaoyao-liu).
