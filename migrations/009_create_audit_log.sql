-- 009_create_audit_log.sql
-- Immutable audit trail for all user and system actions
-- No deleted_at: audit records are never removed

CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID,
  user_id UUID,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  details JSONB DEFAULT '{}',
  ip_address INET,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_log_tenant_created
  ON audit_log(tenant_id, created_at DESC);

CREATE INDEX idx_audit_log_action_created
  ON audit_log(action, created_at DESC);
