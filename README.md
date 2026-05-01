# memorial-infra

Infrastructure support repo for the memorial project.

This repo is not the deployment source of truth. Production rollout is handled by a separate GitOps repo.

## Local validation

```bash
docker compose -f docker/docker-compose.yml config
bash -n scripts/dev-up.sh scripts/dev-down.sh scripts/dev-reset.sh
```

## GitHub Actions

`.github/workflows/validate.yml` checks:

- Docker Compose config
- shell script syntax

This repo does not push k8s manifests or production deploy jobs from GitHub Actions.

Deployment is handled in the separate GitOps repo, so this repo only carries validation workflow setup.

## Connect the repo to GitHub

Connected GitHub repo:

```bash
https://github.com/Filipcsupka/memorial-infra
```
