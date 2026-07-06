-- 012_seed_data.sql
-- Example seed data for development and testing
-- Replace values with your own tenant, user, and lead data

-- Example Tenant
INSERT INTO tenants (id, name, slug, plan, status, settings, max_leads_per_month, max_voice_minutes_per_month, max_team_members)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Acme Realty',
  'acme',
  'growth_engine',
  'active',
  '{
    "llm_chain": [
      {"provider": "openai", "model": "gpt-4o-mini", "priority": 1},
      {"provider": "anthropic", "model": "claude-haiku-4-5", "priority": 2}
    ],
    "markets": ["phoenix", "las_vegas"],
    "voice_platform": "bland",
    "auto_score_on_ingest": true,
    "auto_outreach_hot": false
  }',
  5000,
  1000,
  10
);

-- Example Admin User
-- NOTE: Generate a real bcrypt hash for production. Never store plain passwords.
-- Example hash below is bcrypt of 'changeme' with cost 12
INSERT INTO users (id, tenant_id, email, password_hash, name, role)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000001',
  'admin@example.com',
  '$2b$12$REPLACE_WITH_REAL_BCRYPT_HASH_HERE_______________________',
  'Admin User',
  'admin'
);

-- Example Lead
INSERT INTO leads (id, tenant_id, phone, email, name, property, owner, distress_signals, source, market, tags, dedup_hash)
VALUES (
  '00000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000001',
  '+15555550100',
  'seller@example.com',
  '{"full": "John Smith", "first": "John", "last": "Smith"}',
  '{
    "address": "123 Main St",
    "city": "Phoenix",
    "state": "AZ",
    "zip": "85001",
    "type": "single_family",
    "beds": 3,
    "baths": 2,
    "sqft": 1600,
    "year_built": 1990,
    "arv": 380000,
    "owed": 220000
  }',
  '{
    "name": "John Smith",
    "mailing_address": "456 Oak Ave, Scottsdale, AZ 85251",
    "owner_occupied": true
  }',
  '{
    "pre_foreclosure": false,
    "tax_lien": true,
    "code_violation": false,
    "vacant": false,
    "probate": false,
    "divorce": false,
    "high_equity": false
  }',
  '{"type": "skip_trace", "vendor": "example_vendor", "campaign": "q1_2026"}',
  'phoenix',
  ARRAY['tax_lien'],
  'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
);

-- Example iRELOP Score (67 = WARM)
-- Motivation(40pts) + Opportunity(35pts) + Profile(25pts)
INSERT INTO irelop_scores (id, lead_id, tenant_id, total_score, tier, breakdown, recommended_action, scored_at)
VALUES (
  '00000000-0000-0000-0000-000000000004',
  '00000000-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000001',
  67,
  'WARM',
  '{
    "motivation": {"score": 28, "max": 40, "signals": ["tax_lien", "owner_occupied"]},
    "opportunity": {"score": 24, "max": 35, "signals": ["below_arv_potential"]},
    "profile": {"score": 15, "max": 25, "signals": ["single_family", "3bed_2bath"]}
  }',
  '{"channel": "sms", "priority": 2, "template": "warm_lead_initial_sms", "follow_up_voice": true}',
  NOW()
);

-- Global Kill Switch (inactive by default)
INSERT INTO kill_switch (id, scope, target, active, reason, created_at)
VALUES (
  '00000000-0000-0000-0000-000000000010',
  'global',
  NULL,
  false,
  'Global kill switch — activate in emergency to halt all processing',
  NOW()
);
