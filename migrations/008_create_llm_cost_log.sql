-- 008_create_llm_cost_log.sql
-- Immutable LLM cost tracking for every inference call
-- No deleted_at: cost records are append-only
-- tenant_id nullable for system-level calls (not tenant-scoped)
-- job_id nullable for calls outside job context

CREATE TABLE llm_cost_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tenant_id UUID,
  job_id UUID,
  model TEXT NOT NULL,
  provider TEXT NOT NULL,
  tokens_input INT NOT NULL DEFAULT 0,
  tokens_output INT NOT NULL DEFAULT 0,
  cost_cents NUMERIC(10,4) NOT NULL DEFAULT 0,
  latency_ms INT,
  intent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_llm_cost_log_tenant_created
  ON llm_cost_log(tenant_id, created_at DESC);

-- For Prometheus scraping: scan recent records efficiently
CREATE INDEX idx_llm_cost_log_created
  ON llm_cost_log(created_at);
