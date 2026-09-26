# VPS setup

1. Install Docker Engine with the Compose plugin and create a deploy user with access to Docker. Restrict SSH to key authentication.
2. Create a directory such as `/opt/apps/myapp`. Set the GitHub environment variable `APP_DIR` to that absolute path. Put `.env.production` there using `.env.production.example` as a checklist. Generate `APP_KEY` with `php artisan key:generate --show` locally.
3. Provide an external PostgreSQL database and routine backups. Test a restoration before relying on this deployment. Redis is included in the production Compose stack; its volume persists across restarts.
4. Set GitHub `production` environment secrets: `SERVER_HOST`, `SERVER_USER`, `SSH_PRIVATE_KEY`, `GHCR_USERNAME`, `GHCR_TOKEN` (`read:packages` if the GHCR package is private). Protect the environment with required reviewers if desired.
5. Set the GitHub environment variable `APP_PORT` if port 18080 is occupied. The workflow writes it into `.env.deploy`. Point your host reverse proxy to `127.0.0.1:18080` and enable TLS there.
6. Push to `main`, wait for the `container` workflow to publish that commit's SHA tag, then dispatch `deploy` on that same commit. The workflow uploads `compose.production.yaml`, pulls the image, runs migrations, starts services, and checks `/up`.

Never copy `.env.production` into the repository or container image. The Compose file's runtime `env_file` reads it on the VPS.

## Recovery

Save the previous image tag before each deploy. If the application fails after a release, set `IMAGE_TAG` in `.env.deploy` to the previous tag and run `docker compose --env-file .env.deploy -f compose.production.yaml up -d`. This reverts containers only. A database migration may need a separate recovery plan; prefer additive, backward-compatible schema changes.
