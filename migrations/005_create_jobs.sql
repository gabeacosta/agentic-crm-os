-- 005_create_jobs.sql
-- Job queue table for async processing
-- Supports priority ordering and cost tracking per job

CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID NOT NULL
    REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  intent TEXT NOT NULL
    CHECK (intent IN (
      'score_lead',
      'outreach_sms',
      'outreach_email',
      'outreach_voice',
      'content_generate',
      'transcript_analyze',
      'market_analyze',
      'lead_enrich'
    )),
  status TEXT NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued', 'running', 'completed', 'failed', 'cancelled')),
  priority INT NOT NULL DEFAULT 5,
  input JSONB NOT NULL DEFAULT '{}',
  output JSONB,
  error JSONB,
  steps_used INT DEFAULT 0,
  tokens_used INT DEFAULT 0,
  cost_cents NUMERIC(10,2) DEFAULT 0,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ DEFAULT NULL
);

CREATE INDEX idx_jobs_tenant_status
  ON jobs(tenant_id, status)
  WHERE deleted_at IS NULL;

-- Queue ordering: pick highest priority first, then oldest
CREATE INDEX idx_jobs_queue_order
  ON jobs(status, priority DESC, created_at ASC)
  WHERE deleted_at IS NULL;
