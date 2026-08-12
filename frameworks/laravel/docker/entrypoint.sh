#!/bin/sh
set -e

# Which process should this container run?
#   unset / "all"          -> supervisord runs web + queue + scheduler (AIO)
#   web | queue | scheduler -> that single process (one-process-per-container)
PROCESS="${PROCESS:-all}"

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
