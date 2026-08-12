#!/bin/sh
set -e
case "$PROCESS" in
  web)       exec frankenphp php-server --listen :8080 --root public ;;
  queue)     exec php artisan queue:work --tries=3 --max-time=3600 ;;
  scheduler) exec php artisan schedule:work ;;
  reverb)    exec php artisan reverb:start --host 0.0.0.0 --port 8081 ;;
  *)         exec supervisord -c /etc/supervisor/conf.d/laravel.conf -n ;;  # AIO
esac