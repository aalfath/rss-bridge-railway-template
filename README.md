[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/rss-bridge-1?utm_medium=integration&utm_source=button&utm_campaign=rss-bridge)

# RSS-Bridge on Railway

One-click [Railway](https://railway.com) template for [RSS-Bridge](https://github.com/RSS-Bridge/rss-bridge), which generates RSS and Atom feeds for websites that don't publish one (YouTube, Telegram, Reddit, Bandcamp, Mastodon and 400+ more, plus generic CSS-selector and XPath bridges).

## What it deploys

| Service | Source | What it does |
|---|---|---|
| `RSS-Bridge` | this repo (`Dockerfile`) | nginx + PHP-FPM serving RSS-Bridge on Railway's `PORT`, with a public domain |

- **Version:** RSS-Bridge `2026-09-30`, official image `rssbridge/rss-bridge:2026-09-30@sha256:fbb324d75613b90dad7394c385cee361a31f38e04f1ee9089a4758795b1104c3`.
- **Volume:** `/data` holds the feed cache (`/data/cache`) and optional custom files (`/data/config`), so both survive redeploys and restarts.
- **Health check:** `/healthz` runs RSS-Bridge's own health action through PHP-FPM.
- **Restart:** if nginx or PHP-FPM stops, the container exits non-zero, so Railway's `ON_FAILURE` restart policy brings it back.
- **Size:** runs in about 50 MB of RAM idle; fine on a 0.5 GB / 1 vCPU service. nginx uses 2 workers and PHP-FPM at most 3 children.

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `RSSBRIDGE_authentication_token` | generated, 32 characters | Access token. Every page and feed URL needs `token=...`; the front page asks for it once and then builds feed URLs that include it. |
| `PORT` | `8080` | Port nginx listens on inside the container. |

Any other RSS-Bridge setting can be added as a variable named `RSSBRIDGE_<section>_<key>` (for example `RSSBRIDGE_system_timezone=Europe/Berlin`, `RSSBRIDGE_system_enabled_bridges=Youtube,Telegram,Reddit`). See upstream's [`config.default.ini.php`](https://github.com/RSS-Bridge/rss-bridge/blob/2026-09-30/config.default.ini.php).

## After deploy

1. Copy `RSSBRIDGE_authentication_token` from the service's **Variables** tab.
2. Open the public URL, paste the token, pick a bridge and fill in its form.
3. Copy the generated feed URL (it includes the token) into your feed reader.

To run a public instance, delete `RSSBRIDGE_authentication_token`. Public RSS-Bridge instances fetch any URL a visitor gives them, so only do that if you want to offer it to everyone.

Custom bridges, formats, `config.ini.php` or `whitelist.txt` can be placed in `/data/config` on the volume; they are copied into the app at each start.

## Updates

The service builds from this repo's `main` branch. When we bump the pinned RSS-Bridge image, Railway shows deployers an "update available" notice; read [`CHANGELOG.md`](CHANGELOG.md) first, then apply it from the Railway dashboard. The cache and custom files on `/data` are kept.

## Licence

RSS-Bridge is released under [the Unlicense](https://github.com/RSS-Bridge/rss-bridge/blob/master/UNLICENSE). The files in this repo are released the same way.
