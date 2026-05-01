# Memorial — Project Brain

> Status: **Phase 1 — Local Dev WORKING end-to-end**
> Last updated: 2026-04-26
> Owner: tradeopsllc@gmail.com

---

## What This Is

NFC-powered memorial photo gallery service.

Customer buys an NFC tag online → pays via Stripe → gets a private upload link → uploads photos to their gallery → physical NFC tag (on gravestone, memorial object, etc.) is programmed with the gallery URL → anyone taps the tag with a phone → gallery opens in browser, no app needed.

---

## Repository Map

| Repo | Purpose | Stack |
|------|---------|-------|
| `memorial-infra` | Local dev stack, DB schema, deploy configs | Docker Compose, PostgreSQL, MinIO, Mailhog |
| `memorial-api` | Backend REST API | Node.js, Express, TypeScript, Drizzle ORM, Stripe, Multer |
| `memorial-web` | Frontend + storefront | Next.js (App Router), TypeScript, Tailwind CSS |

---

## System Architecture

```
[Customer Browser]
    │
    ├── GET /               → Landing page (memorial-web)
    ├── GET /checkout       → Order form → POST /api/payments/checkout
    │                                           │
    │                              [Stripe Checkout Session]
    │                                           │
    ├── GET /checkout/success                   │ webhook → /api/payments/webhook
    │                                           ↓
    │                              order.status = "paid"
    │                              order.upload_token = nanoid(64)
    │
    ├── GET /upload/[token] → Upload photos → POST /api/uploads/:token/finalize
    │                                           │
    │                              [MinIO bucket: memorial]
    │                              [gallery created, photos stored]
    │                              order.status = "ready"
    │
    └── GET /gallery/[token] → Public gallery viewer
                                  ↓
                              GET /api/galleries/:token
                              (returns gallery + photo URLs from MinIO)

[Admin Browser]
    └── GET /admin          → Dashboard → GET /api/admin/*
```

---

## Data Flow: Order → Gallery

```
1. POST /api/payments/checkout
   → creates order (status: pending)
   → creates Stripe session (metadata: orderId)
   → returns { url: stripe_checkout_url }

2. Stripe webhook: checkout.session.completed
   → order.status = "paid"
   → order.upload_token = nanoid(64)
   → creates payments record

3. Customer visits /upload/[token]
   → POST /api/uploads/:token/finalize (multipart, photos[])
   → validates token, checks order.status === "paid"
   → creates gallery (public_token = nanoid(32))
   → stores photos in MinIO: galleries/{gallery_id}/{filename}
   → inserts photo records (storage_key, mime_type, dimensions, sort_order)
   → order.status = "ready"
   → returns { galleryToken }

4. Customer visits /gallery/[publicToken]
   → GET /api/galleries/:token
   → returns gallery + photos with signed URLs
   → GalleryViewer renders photo grid
```

---

## Database Schema

```sql
users          — admin accounts
orders         — customer purchases (email, package, status, stripe_session_id, upload_token, duration_months)
galleries      — gallery records (public_token, title, status, pin_hash, expires_at)
photos         — file metadata (storage_key, mime_type, width, height, sort_order)
payments       — Stripe payment records
activity_log   — audit trail
```

Key indexes: `orders.upload_token`, `galleries.public_token`, `photos(gallery_id, sort_order)`, `galleries.expires_at` (partial, WHERE NOT NULL)

---

## Packages / Pricing

Duration selected at checkout. Price = package × duration.

| Duration | Basic (50 photos, 1 NFC) | Premium (200 photos, 2 NFC, PIN) |
|----------|--------------------------|----------------------------------|
| 1 year   | €29                      | €49                              |
| 3 years  | €49                      | €79                              |
| 5 years  | €69                      | €109                             |
| Lifetime | €99                      | €149                             |

- `durationMonths`: 12 / 36 / 60 / null (null = lifetime)
- `expiresAt` set on gallery at upload finalize time
- Basic max 50 photos enforced at upload; Premium max 200
- Currency: EUR throughout

---

## Tech Stack Detail

### memorial-api
- Runtime: Node.js 22, TypeScript
- Framework: Express 4
- ORM: Drizzle ORM (node-postgres)
- Validation: Zod
- Storage: MinIO SDK (`minio` npm) via `src/services/storage.ts`
- Payments: Stripe SDK v17 (+ dev-bypass endpoint for local testing)
- Auth: `x-admin-token` header on admin routes
- ID generation: nanoid

### memorial-web

- Framework: Next.js 16.2.4 (App Router) — breaking changes vs older Next.js
- Styling: Tailwind CSS
- API calls: native fetch (no client lib)
- API proxy: Next.js rewrites `/api/*` → `memorial-api:3001` ✅ wired
- Images: plain `<img>` tags (next/image optimizer broken with localhost MinIO in dev — revisit for prod)

### memorial-infra
- Local: Docker Compose
- DB: PostgreSQL 16
- Object storage: MinIO (S3-compatible, local R2 substitute)
- Email trap: Mailhog
- Schema: `db/init.sql` (applied on first postgres start)

---

## Local Dev Stack

| Service | URL | Credentials |
|---------|-----|-------------|
| PostgreSQL | `localhost:5432` | `memorial:memorial` / db: `memorial` |
| MinIO API | `http://localhost:9000` | `memorial:memorial123` |
| MinIO Console | `http://localhost:9001` | `memorial:memorial123` |
| Mailhog UI | `http://localhost:8025` | — |
| API | `http://localhost:3001` | — |
| Web | `http://localhost:3000` | — |

```bash
# Start infra
cd memorial-infra && ./scripts/dev-up.sh

# Start API
cd memorial-api && cp .env.example .env && npm run dev

# Start Web
cd memorial-web && npm run dev
```

### Environment Variables

**memorial-api `.env`**
```
DATABASE_URL=postgresql://memorial:memorial@localhost:5432/memorial
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
WEB_URL=http://localhost:3000
MINIO_ENDPOINT=localhost
MINIO_PORT=9000
MINIO_ACCESS_KEY=memorial
MINIO_SECRET_KEY=memorial123
MINIO_BUCKET=memorial
STORAGE_PUBLIC_URL=http://localhost:9000/memorial
UPLOAD_DIR=./uploads
PORT=3001
```

**memorial-web `.env.local`**
```
NEXT_PUBLIC_API_URL=http://localhost:3001
```

---

## Implementation Status

### memorial-infra ✅
- [x] Docker Compose (postgres, minio, minio-init, mailhog)
- [x] DB init.sql with full schema + healthchecks
- [x] dev-up.sh / dev-down.sh / dev-reset.sh scripts
- [x] `.env.example` in api, `.env.local.example` in web
- [x] Ruflo initialized (.ruflo.yml, MCP registered, memory DB)
- [ ] Drizzle migrations setup (currently init.sql only)
- [ ] Seed data for dev testing

### memorial-api ✅ (local complete)

- [x] Express server with helmet, cors, rate limiting
- [x] `POST /api/orders` — create order
- [x] `GET /api/orders/:id` — get order
- [x] `PATCH /api/orders/:id/status` — update status
- [x] `POST /api/payments/checkout` — Stripe session (EUR, package × duration pricing)
- [x] `POST /api/payments/webhook` — Stripe webhook handler + sends email
- [x] `POST /api/payments/dev-checkout` — bypass Stripe (dev only, NODE_ENV gate) + sends email
- [x] `GET /api/galleries/:token` — public gallery with photos + expiry check (410 if expired)
- [x] `POST /api/galleries` — create gallery
- [x] `PATCH /api/galleries/:id` — update gallery
- [x] `POST /api/uploads/:token/finalize` — upload to MinIO, enforces photo limit per package, sets expiresAt
- [x] `GET /api/uploads/:token/status` — check order status
- [x] `src/services/storage.ts` — MinIO client wrapper
- [x] `src/services/email.ts` — nodemailer (Mailhog local) — **TODO: swap to Resend for prod**
- [x] Admin routes (token-protected via x-admin-token header) — left-joins galleries for galleryToken
- [x] `src/jobs/expire-galleries.ts` — reaper script, marks expired galleries status='expired'
- [x] `POST /api/renewals/checkout` — Stripe renewal session
- [x] `POST /api/renewals/dev-renew` — dev bypass renewal
- [x] `GET /api/renewals/:token` — gallery info for renewal page (works even if expired)
- [x] `src/jobs/renewal-reminder.ts` — sends reminder email 30 days before expiry, cooloff 25 days, resets on renewal
- [x] `src/services/email.ts` — sendRenewalReminder(), sendRenewalConfirmation()

### memorial-web ✅ (local complete)

- [x] Landing page with pricing
- [x] Checkout page — package + duration selector, live price, dev bypass
- [x] Checkout success page
- [x] Upload page (`/upload/[token]`) — drag & drop, shows gallery link on done
- [x] Gallery viewer (`/gallery/[token]`) — grid + lightbox, plain img tags, expired gallery screen
- [x] Admin page — wired to API with x-admin-token header, shows orders + gallery links
- [x] Admin login page (`/admin/login`) — server action sets cookie
- [x] Renewal page (`/renew/[token]`) — duration picker, Stripe or dev bypass, same publicToken preserved
- [x] Next.js API rewrite (`/api/*` → `localhost:3001`)

### memorial-infra (deploy configs) ✅

- [x] Docker Compose (postgres, minio, minio-init, mailhog)
- [x] DB init.sql with full schema + healthchecks + ALTER TABLE migrations at bottom
- [x] dev-up.sh / dev-down.sh / dev-reset.sh scripts
- [x] `k8s/gallery-reaper-cronjob.yaml` — k8s CronJob, runs reaper daily 03:00 UTC
- [x] `k8s/renewal-reminder-cronjob.yaml` — k8s CronJob, runs reminder daily 10:00 UTC

---

## Known Gaps / TODO

| Priority | Gap | Repo | Notes |
|----------|-----|------|-------|
| HIGH | Stripe real keys + end-to-end test | api | dev-checkout bypasses for now |
| HIGH | Email: swap Mailhog → Resend | api | `src/services/email.ts` has TODO comments marking all swap points |
| MED | Domain + DNS | infra | Need `memorial.sk`, verify on Resend for real email delivery |
| MED | next/image broken with localhost MinIO | web | Using plain `<img>`; fix when CDN/R2 in place |
| MED | Drizzle migrations | api | Currently init.sql + ALTER TABLE; no migration history |
| LOW | Storage purge after grace period | api/infra | After 4mo past expiry: delete photos from MinIO to free storage. DB record kept. |
| LOW | Dev seed data | infra | Useful for testing |
| LOW | Thumbnail / image optimization | api | Phase 2 |

## Schema v2 Changes (2026-05-01)

Added to `orders`: `customer_name`, `person_name`, `born_at`, `died_at`, `tag_shipped_at`
Added to `galleries`: `person_name`, `born_at`, `died_at`; default status now `waiting_upload`
Fixed `payments.currency` default → `eur`

Gallery status flow: `waiting_upload` → `active` → `expired`
Gallery pre-created at payment (public_token known before upload → admin can program NFC tag immediately)

---

## Phase 2: Cloud Migration Target

**Infra decision: k3s on Hetzner** (owner is k8s engineer, existing cluster, €5/node flat cost, warm pods = no cold start on gallery tap).
**Web exception: Vercel** for Next.js (free tier, optimized for it).

| Local | Cloud | Notes |
|-------|-------|-------|
| PostgreSQL (Docker) | CloudNativePG on k3s or managed Neon | Prefer in-cluster for cost |
| MinIO | Cloudflare R2 | S3-compatible, zero egress cost |
| Express (local) | k3s Deployment | Container on existing Hetzner node |
| Next.js (local) | Vercel | Free tier, natural fit |
| Mailhog | Resend | `src/services/email.ts` swap — ~10 lines |
| — | Cloudflare DNS + SSL | `memorial.sk` |
| — | k8s CronJob | `k8s/gallery-reaper-cronjob.yaml` ready |

**Migration sequence:**

1. Buy `memorial.sk` → Cloudflare DNS
2. Verify domain on Resend → swap email service (10 min)
3. Provision R2 bucket → update `STORAGE_PUBLIC_URL`
4. Build API Docker image → push to registry → apply k8s Deployment + Service
5. Apply `k8s/gallery-reaper-cronjob.yaml`
6. Deploy Web → Vercel → set `NEXT_PUBLIC_API_URL` to k8s ingress
7. Stripe webhook → update to prod URL
8. Set real Stripe keys → end-to-end payment test

**Email migration (Resend) checklist** — all marked `TODO(migration→Resend)` in code:

- `npm install resend` in memorial-api
- Replace `createTransporter()` + `sendMail()` in `src/services/email.ts`
- Add env: `RESEND_API_KEY`, `EMAIL_FROM=noreply@memorial.sk`
- Remove: `SMTP_HOST`, `SMTP_PORT`, `nodemailer` dep

---

## Key Decisions

- **MinIO over S3 locally** — R2-compatible API, zero egress cost in prod
- **nanoid tokens** — upload_token (64 chars), public_token (32 chars) — unguessable, no auth needed for gallery access
- **No auth on gallery** — public token IS the auth (like a secret link)
- **Multer disk → MinIO** — current gap, must fix before end-to-end works
- **Drizzle ORM** — schema-first, type-safe, easy migration path

---

## Ruflo Agent Config

```yaml
# .ruflo.yml
project: memorial
repos:
  - memorial-infra
  - memorial-api
  - memorial-web
memory_keys:
  - memorial:arch
  - memorial:gaps
  - memorial:decisions
swarm_enabled: true
```

---

## Links

- Stripe Dashboard: https://dashboard.stripe.com
- MinIO Console (local): http://localhost:9001
- Mailhog (local): http://localhost:8025
- GitHub: (add repo URLs when created)
