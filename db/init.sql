CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email       VARCHAR(255) NOT NULL UNIQUE,
  role        VARCHAR(50)  NOT NULL DEFAULT 'admin',
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS orders (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_email    VARCHAR(255) NOT NULL,
  package_type      VARCHAR(50)  NOT NULL,
  status            VARCHAR(50)  NOT NULL DEFAULT 'pending',
  stripe_session_id VARCHAR(255),
  upload_token      VARCHAR(128) UNIQUE,
  created_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS galleries (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  public_token VARCHAR(128) NOT NULL UNIQUE,
  order_id     UUID        NOT NULL REFERENCES orders(id),
  title        VARCHAR(255) NOT NULL,
  status       VARCHAR(50)  NOT NULL DEFAULT 'active',
  pin_hash     VARCHAR(255),
  expires_at   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS photos (
  id          UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  gallery_id  UUID    NOT NULL REFERENCES galleries(id),
  storage_key VARCHAR(512) NOT NULL,
  mime_type   VARCHAR(100),
  width       INTEGER,
  height      INTEGER,
  size_bytes  INTEGER,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS payments (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id    UUID        NOT NULL REFERENCES orders(id),
  provider_id VARCHAR(255) NOT NULL,
  provider    VARCHAR(50)  NOT NULL DEFAULT 'stripe',
  status      VARCHAR(50)  NOT NULL,
  amount      NUMERIC(10,2) NOT NULL,
  currency    VARCHAR(10)  NOT NULL DEFAULT 'usd',
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS activity_log (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type VARCHAR(50)  NOT NULL,
  entity_id   UUID        NOT NULL,
  action      VARCHAR(100) NOT NULL,
  metadata    TEXT,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_status         ON orders(status);
CREATE INDEX idx_orders_upload_token   ON orders(upload_token);
CREATE INDEX idx_galleries_public_token ON galleries(public_token);
CREATE INDEX idx_galleries_order_id    ON galleries(order_id);
CREATE INDEX idx_photos_gallery_id     ON photos(gallery_id, sort_order);
CREATE INDEX idx_activity_entity       ON activity_log(entity_type, entity_id);
