-- 002_create_users.sql
-- Users table with tenant isolation and role-based access

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL
    REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  email TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'member'
    CHECK (role IN ('admin', 'member', 'viewer')),
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ DEFAULT NULL
);

CREATE UNIQUE INDEX idx_users_tenant_email
  ON users(tenant_id, email)
  WHERE deleted_at IS NULL;
