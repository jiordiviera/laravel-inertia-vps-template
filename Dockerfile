# syntax=docker/dockerfile:1
ARG PHP_VERSION=8.5
FROM dunglas/frankenphp:1-php${PHP_VERSION}-bookworm AS base
WORKDIR /app
RUN install-php-extensions bcmath gd intl opcache pcntl pdo_pgsql redis zip

FROM base AS build
ARG PNPM_VERSION=12.4.2
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY --from=node:22-bookworm-slim /usr/local/bin/node /usr/local/bin/node
COPY --from=node:22-bookworm-slim /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && apt-get update && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/* \
    && npm install --global pnpm@${PNPM_VERSION}
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY . .
# Wayfinder and similar Vite plugins may call Artisan during the frontend build.
RUN cp .env.example .env \
    && composer dump-autoload --optimize --no-interaction \
    && pnpm run build \
    && rm -f .env \
    && rm -rf node_modules

FROM base AS runtime
ENV SERVER_NAME=:8080 DB_CONNECTION=pgsql
COPY --from=build --chown=www-data:www-data /app /app
COPY --chmod=755 docker/entrypoint.sh /usr/local/bin/app-entrypoint
RUN mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache /data /config
USER www-data
EXPOSE 8080
HEALTHCHECK NONE
ENTRYPOINT ["app-entrypoint"]
CMD ["--config", "/etc/frankenphp/Caddyfile", "--adapter", "caddyfile"]
