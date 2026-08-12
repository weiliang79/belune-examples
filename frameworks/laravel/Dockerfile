# syntax=docker/dockerfile:1
#
# Laravel (Inertia + React) on Belune — FrankenPHP, single image.
#
# One image serves BOTH deploy shapes (see README.md):
#   - AIO:   leave PROCESS unset -> supervisord runs web + queue + scheduler
#   - Split: set PROCESS=web|queue|scheduler -> that one process only
#
FROM dunglas/frankenphp:php8.4

# System packages: supervisor (AIO), Node (Inertia/Vite build), git+unzip (composer).
RUN apt-get update && apt-get install -y --no-install-recommends \
        supervisor git unzip ca-certificates curl gnupg \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

# PHP extensions Laravel needs.
RUN install-php-extensions pcntl pdo_mysql redis opcache bcmath intl

# Composer isn't bundled in the FrankenPHP image — copy it from the official image.
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . .

# Install deps, build the Inertia frontend, and pre-compile what does NOT depend
# on runtime env (routes + views), so nothing has to be written at runtime.
# A throwaway APP_KEY lets artisan/Wayfinder boot during the build; the real key
# comes from the runtime environment. NOTE: no `config:cache` on purpose —
# leaving config uncached is what lets env() read the values Belune injects at
# runtime (and avoids a write on the read-only root filesystem).
RUN export APP_KEY="base64:$(head -c 32 /dev/urandom | base64)" \
    && composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader \
    && npm ci \
    && npm run build \
    && php artisan route:cache \
    && php artisan view:cache

COPY docker/supervisord.conf /etc/supervisor/conf.d/laravel.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
