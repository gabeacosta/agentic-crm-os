-- 004_create_irelop_scores.sql
-- iRELOP: 100-point lead scoring system
-- Motivation(40) + Opportunity(35) + Profile(25)
-- HOT >= 80, WARM >= 60, COOL >= 40, PASS < 40

CREATE TABLE irelop_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id UUID NOT NULL
    REFERENCES leads(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  tenant_id UUID NOT NULL
    REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  total_score INT NOT NULL
    CHECK (total_score >= 0 AND total_score <= 100),
  tier TEXT NOT NULL
    CHECK (tier IN ('HOT', 'WARM', 'COOL', 'PASS')),
  breakdown JSONB NOT NULL,        -- { "motivation": { "score": 0, "signals": [...] }, "opportunity": {...}, "profile": {...} }
  recommended_action JSONB,        -- { "channel": "voice|sms|email|archive", "priority": 1, "template": "..." }
  scoring_version TEXT NOT NULL DEFAULT '1.0.0',
  scored_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ DEFAULT NULL
);

CREATE INDEX idx_irelop_scores_tenant_tier
  ON irelop_scores(tenant_id, tier)
  WHERE deleted_at IS NULL;

CREATE INDEX idx_irelop_scores_lead_scored
  ON irelop_scores(lead_id, scored_at DESC)
  WHERE deleted_at IS NULL;
