# memorial-infra

Infrastructure support repo for the memorial project.

## Local validation

```bash
docker compose -f docker/docker-compose.yml config
bash -n scripts/dev-up.sh scripts/dev-down.sh scripts/dev-reset.sh
```

## GitHub Actions

`.github/workflows/validate.yml` checks:

- Docker Compose config
- shell script syntax

Deployment is handled in the separate GitOps repo, so this repo only carries validation workflow setup.

## Connect the repo to GitHub

After creating `memorial-infra` on GitHub:

```bash
git remote add origin git@github.com:<your-user>/memorial-infra.git
git branch -M main
git push -u origin main
```
