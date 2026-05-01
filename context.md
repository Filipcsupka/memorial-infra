# Memorial — Current Context

> Last updated: 2026-05-01

## Repos

| Repo | Purpose |
|------|---------|
| `memorial-web` | Next.js frontend, checkout/upload/gallery/admin UI |
| `memorial-api` | Express API, gallery/order/admin logic, placeholder payment flow |
| `memorial-infra` | Local development infra and validation workflows |

## Current direction

- this is still work in progress
- production deployment is handled in a separate GitOps repo
- this repo should not own k3s manifests or deployment automation
- payment provider is not finalized
- Stripe code is placeholder only and should not drive roadmap decisions

## Local stack owned here

- PostgreSQL
- MinIO
- Mailhog
- helper scripts for local startup/reset

## What GitHub Actions do now

### memorial-web

- install dependencies
- lint
- typecheck
- production build
- Vercel deploy workflow

### memorial-api

- install dependencies
- lint
- basic test
- production build
- publish container image to GHCR

### memorial-infra

- validate Docker Compose
- validate shell scripts

## Payment status

- there is no final live paywall integrated
- checkout and renewal currently use a placeholder continuation path when no provider is configured
- docs and implementation should assume a future Slovak payment provider, not Stripe

## Notes

- keep infra docs focused on local dev support
- keep deploy ownership in the GitOps repo
- avoid expanding placeholder Stripe logic beyond what is needed for local flow and CI
