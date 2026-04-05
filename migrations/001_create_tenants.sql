-- 001_create_tenants.sql
-- Core tenants table for multi-tenant isolation
-- Every data table references tenants.id with RESTRICT

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  slug TEXT NOT NULL,
  plan TEXT NOT NULL DEFAULT 'growth_engine'
    CHECK (plan IN ('growth_engine', 'lead_recovery', 'dealiq_internal')),
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'suspended', 'cancelled')),
  settings JSONB NOT NULL DEFAULT '{}',
  max_leads_per_month INT NOT NULL DEFAULT 500,
  max_voice_minutes_per_month INT NOT NULL DEFAULT 100,
  max_team_members INT NOT NULL DEFAULT 5,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ DEFAULT NULL
);

CREATE UNIQUE INDEX idx_tenants_slug
  ON tenants(slug)
  WHERE deleted_at IS NULL;
