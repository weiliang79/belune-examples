# Laravel on Belune

Laravel 13 + Inertia (React) + Fortify, served by **FrankenPHP**. A single
`Dockerfile` builds one image that can run either as an all-in-one container or
as one process per container.

## Deploy on Belune

- **Source:** this repo · **Root Directory:** `frameworks/laravel`
- **Build method:** Dockerfile
- **Runtime → Capabilities:** **Standard** — FrankenPHP embeds Caddy, whose binary
  ships a file capability; under the default *Minimal* set the container fails with
  `exec … operation not permitted`. Read-only root filesystem can stay **on**.
- **Add a managed MySQL** database in the same project.

### Two deploy shapes

| Shape | Apps | Config |
| --- | --- | --- |
| **AIO** (one container) | 1 app | leave `PROCESS` unset → `supervisord` runs web + queue + scheduler |
| **Split** (process per container) | 3 apps, same repo + Root Directory | set `PROCESS=web` / `queue` / `scheduler`; only the **web** app needs a domain |

In the Split shape every app builds its own image (Belune builds per app) — that's
expected until per-app process types land. The **web** process listens on `8080`
(Belune's default route port), so no Container Port override is needed.

### Environment variables

Set these on the app's **Environment** tab (secrets — `APP_KEY`, `DB_PASSWORD` —
you enter yourself). Generate the key locally with `php artisan key:generate --show`.

```ini
APP_KEY=base64:...              # required
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain

DB_CONNECTION=mysql
DB_HOST=...  DB_PORT=3306  DB_DATABASE=...  DB_USERNAME=...  DB_PASSWORD=...

# Keep state off the read-only filesystem: back these with the database (or Redis).
SESSION_DRIVER=database
CACHE_STORE=database
QUEUE_CONNECTION=database

# Log to the container's stdout, not storage/logs (which is read-only).
LOG_CHANNEL=stderr
```

## Why it works under a read-only root filesystem

- `route:cache` and `view:cache` run at **build** time, so compiled routes/Blade
  views are baked into the image — nothing is compiled (written) at runtime.
- `config:cache` is intentionally **skipped**, so `env()` reads the runtime values
  Belune injects instead of values frozen at build.
- Sessions, cache and the queue are backed by the **database** (or Redis), and logs
  go to **stderr** — so no process writes to `storage/` or `bootstrap/cache/`.
- Migrations run at container start (from the web/AIO role) against MySQL.

If you add features that must write to disk (e.g. `storage/app` uploads), mount a
[volume](https://belune.dev/docs/mounts) at that path.
