# Laravel + Inertia VPS operations template

Reusable **infrastructure layer** extracted from Prooflog. Add these files to an existing Laravel + Inertia application using pnpm and PostgreSQL. This repository is intentionally not a runnable Laravel application by itself.

## Included

- FrankenPHP multi-stage image: Composer dependencies, pnpm/Vite build, non-root runtime
- Local Compose stack: app, queue worker, scheduler; external PostgreSQL
- Production Compose stack: app, queue worker, scheduler, Redis; external PostgreSQL
- GitHub Actions: PostgreSQL-backed tests, GHCR image, manual VPS deployment of an immutable commit tag

## Integrate with your application

1. Copy these files into the **root** of a Laravel + Inertia project. Keep your project's `composer.json`, `composer.lock`, `package.json`, `pnpm-lock.yaml` and `.env.example`.
2. Ensure `pnpm run build` builds the frontend, `php artisan test` works against PostgreSQL, and the app exposes Laravel's `/up` health route. Adjust the workflows if your project uses different commands.
3. Review PHP version, extensions, upload limits, queue connection, storage volume and session driver for your app. The app image must include everything used at runtime.
4. Copy `.env.docker.example` to `.env.docker`; generate `APP_KEY` with `php artisan key:generate --show`, set DB credentials, then run `docker compose up -d --build` and `docker compose exec app php artisan migrate --force`.
5. For production, follow [the VPS setup](docs/VPS.md). Keep credentials and `.env.production` out of Git.

The local PostgreSQL server must accept connections from the Docker network. For a managed database, use its hostname instead of `host.docker.internal`.

## Before reusing

This is a starting point, not an automatic copy of Prooflog's product. It includes no app source, Prooflog secrets, domain, AI features or user data. Pin GitHub Actions to audited commit SHAs for stricter supply-chain control. If your project has a monorepo or a different package manager, change the Dockerfile and workflows.

## Deployment model

A push builds `ghcr.io/OWNER/REPO:<commit SHA>` and `:latest`. The manual `deploy` workflow deploys the current commit SHA. Run it on `main` after that commit's container job has succeeded. Migrations run before the application containers are replaced, so migrations must be backward compatible. Back up PostgreSQL and test restoration separately. The pipeline detects an unhealthy app but does not automatically roll back a database migration.

## Source

Adapted from the DevOps setup in [Prooflog](https://github.com/jiordiviera/prooflog) by Jiordi Viera. Keep attribution if you redistribute this template. Choose and add a license before public release.
