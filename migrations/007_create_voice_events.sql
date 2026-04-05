-- 007_create_voice_events.sql
-- Voice call events tracking for Retell/Bland/Vapi integrations
-- Links to leads for call history and score impact tracking

CREATE TABLE voice_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  lead_id UUID NOT NULL
    REFERENCES leads(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  tenant_id UUID NOT NULL
    REFERENCES tenants(id) ON DELETE RESTRICT ON UPDATE RESTRICT,
  platform TEXT
    CHECK (platform IN ('retell', 'bland', 'vapi')),
  platform_call_id TEXT,
  event_type TEXT NOT NULL
    CHECK (event_type IN (
      'call_started',
      'call_ended',
      'call_transferred',
      'voicemail_left',
      'no_answer',
      'error'
    )),
  direction TEXT
    CHECK (direction IN ('inbound', 'outbound')),
  duration_seconds INT,
  disposition JSONB,     -- { "outcome": "interested|not_interested|callback|wrong_number", "notes": "..." }
  transcript JSONB,      -- { "segments": [{ "speaker": "agent|lead", "text": "...", "timestamp": 0 }] }
  score_impact JSONB,    -- { "delta": 5, "reason": "expressed urgency", "new_tier": "HOT" }
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ DEFAULT NULL
);

CREATE INDEX idx_voice_events_tenant_lead
  ON voice_events(tenant_id, lead_id, created_at DESC)
  WHERE deleted_at IS NULL;
