# Belune Examples

Deployable, minimal examples for running common frameworks on
[Belune](https://belune.dev). Each example is a self-contained app under
`frameworks/<framework>/<variant>/` and deploys as its own Belune application.

## Deploying an example

Because every example lives in a subdirectory, each app uses Belune's
**Root Directory** setting to build from its folder:

1. **New Application** → **Git Repository**, and point it at this repo.
2. Set **Root Directory** to the example's path (e.g. `frameworks/vite/dockerfile`).
3. Pick the **Build method** and set any **Environment** variables from the table below.
4. Deploy, then add a domain.

> Root Directory requires a Belune build that includes the monorepo/subdirectory
> feature. Without it, point an app at a single-example copy at the repo root instead.

## Examples

| Example | Root Directory | Build | Key settings |
| --- | --- | --- | --- |
| **Next.js** (Node server) | `frameworks/nextjs/default` | Railpack | `PORT=8080`; `output: 'standalone'` for a slimmer image |
| **Next.js** (static export) | `frameworks/nextjs/export` | Railpack (SPA) or Dockerfile | `output: 'export'` — served as static files, no Node server |
| **Vite** (Railpack) | `frameworks/vite/railpack` | Railpack | `RAILPACK_SPA_OUTPUT_DIR=dist`; domain **Container Port 80** |
| **Vite** (Caddy Dockerfile) | `frameworks/vite/dockerfile` | Dockerfile | serves on `8080`, no port override |
| **Laravel** (FrankenPHP) | `frameworks/laravel` | Dockerfile | Runtime **Capabilities: Standard**; managed MySQL — see [its README](frameworks/laravel/README.md) |

Framework-specific notes and the reasoning behind each setting live in the
[Belune docs](https://belune.dev/docs) (Frameworks section) and, for Laravel, in
[`frameworks/laravel/README.md`](frameworks/laravel/README.md).

## Layout

```
frameworks/
  nextjs/
    default/     # Node server (next start)
    export/      # static export (output: 'export')
  vite/
    railpack/    # Vite SPA served by Railpack
    dockerfile/  # Vite SPA served by a Caddy Dockerfile
  laravel/       # Laravel + Inertia + FrankenPHP
```
