# xiaojx's Personal Homepage

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
