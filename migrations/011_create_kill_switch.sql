-- 011_create_kill_switch.sql
-- Kill switch for global, per-tenant, or per-service circuit breaking
-- Uses active boolean instead of soft delete (always queryable)

CREATE TABLE kill_switch (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  scope TEXT NOT NULL
    CHECK (scope IN ('global', 'tenant', 'service')),
  target TEXT,                   -- tenant_id or service name; NULL for global scope
  active BOOLEAN NOT NULL DEFAULT false,
  reason TEXT,
  activated_by UUID,
  activated_at TIMESTAMPTZ,
  deactivated_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_kill_switch_scope_target
  ON kill_switch(scope, target);
