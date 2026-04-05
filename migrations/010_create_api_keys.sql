-- 010_create_api_keys.sql
-- API key management with bcrypt hashed keys
-- key_prefix stores first 8 chars for identification in logs/UI
-- key_hash stores bcrypt hash for authentication

CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL
    REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  user_id UUID NOT NULL
    REFERENCES users(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  name TEXT NOT NULL,
  key_prefix TEXT NOT NULL,      -- first 8 chars of the raw key (e.g., "gntc_abc")
  key_hash TEXT NOT NULL,        -- bcrypt hash of full key
  scopes TEXT[] NOT NULL DEFAULT '{}',
  last_used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ DEFAULT NULL
);

CREATE UNIQUE INDEX idx_api_keys_prefix
  ON api_keys(key_prefix)
  WHERE deleted_at IS NULL;
