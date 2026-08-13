#!/bin/sh
set -e

# Which process should this container run?
#   unset / "all"          -> supervisord runs web + queue + scheduler (AIO)
#   web | queue | scheduler -> that single process (one-process-per-container)
PROCESS="${PROCESS:-all}"

# The root filesystem is read-only, but Laravel compiles Blade views at runtime.
# `view:cache` (baked at build) covers ordinary templates, yet inline/string
# components still compile on first render and write into the compiled-views
# directory — which lives on the read-only rootfs. Redirect that directory to the
# writable /tmp and seed it from the baked cache so the first request stays warm.
# Applies to every role: queue/scheduler also render views (e.g. mailables).
export VIEW_COMPILED_PATH=/tmp/laravel-views
mkdir -p "$VIEW_COMPILED_PATH"
cp -a /app/storage/framework/views/. "$VIEW_COMPILED_PATH/" 2>/dev/null || true

# Seed the scheduler heartbeat so the role-aware healthcheck has a fresh file
# before schedule:work's first tick; the scheduled task refreshes it each minute.
if [ "$PROCESS" = "all" ] || [ "$PROCESS" = "scheduler" ]; then
    touch /tmp/scheduler-heartbeat 2>/dev/null || true
fi

# Run migrations once, from the web/AIO role only, so queue/scheduler containers
# don't race it. Non-fatal: a running app is better than a crash loop if the DB
# is briefly unreachable.
if [ "$PROCESS" = "all" ] || [ "$PROCESS" = "web" ]; then
    php artisan migrate --force || echo "entrypoint: migrate failed, continuing"
fi

case "$PROCESS" in
    web)       exec frankenphp php-server --listen :8080 --root public ;;
    queue)     exec php artisan queue:work --tries=3 --max-time=3600 ;;
    scheduler) exec php artisan schedule:work ;;
    all)       exec supervisord -c /etc/supervisor/conf.d/laravel.conf -n ;;
    *)         echo "entrypoint: unknown PROCESS '$PROCESS' (use web|queue|scheduler, or leave unset)" >&2; exit 1 ;;
esac
