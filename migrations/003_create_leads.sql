-- 003_create_leads.sql
-- Leads table: core entity for RE lead pipeline
-- Uses JSONB for flexible nested structures (name, property, owner, distress, source)

CREATE TABLE leads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL
    REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  phone TEXT,
  email TEXT,
  name JSONB,            -- { "full": "...", "first": "...", "last": "..." }
  property JSONB,        -- { "address": "...", "city": "...", "state": "...", "zip": "...", "type": "...", "arv": 0, "owed": 0 }
  owner JSONB,           -- { "name": "...", "mailing_address": "...", "owner_occupied": false }
  distress_signals JSONB,-- { "pre_foreclosure": false, "tax_lien": false, "code_violation": false, ... }
  source JSONB,          -- { "type": "skip_trace|driving4dollars|mls|webhook", "vendor": "...", "campaign": "..." }
  market TEXT,
  tags TEXT[] DEFAULT '{}',
  dedup_hash TEXT,
  raw_data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ DEFAULT NULL
);

CREATE UNIQUE INDEX idx_leads_tenant_dedup
  ON leads(tenant_id, dedup_hash)
  WHERE deleted_at IS NULL;

CREATE INDEX idx_leads_tenant_created
  ON leads(tenant_id, created_at DESC);
