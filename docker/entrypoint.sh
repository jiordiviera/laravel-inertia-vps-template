#!/bin/sh
set -eu
if [ -z "${APP_KEY:-}" ]; then
    echo 'APP_KEY is required' >&2
    exit 1
fi
if [ "${APP_ENV:-production}" != 'local' ]; then
    php artisan optimize --no-interaction
fi
exec docker-php-entrypoint "$@"
