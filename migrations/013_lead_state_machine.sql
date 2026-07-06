-- 013_lead_state_machine.sql
-- 12-state lead lifecycle + fn_transition_lead() with row-level locking.
--
-- Design: transitions are validated against an explicit adjacency table
-- (lead_status_transitions), not a hardcoded CASE/CHECK — new transitions
-- ship as a data change, not a migration. fn_transition_lead() takes the
-- row lock with SELECT ... FOR UPDATE before validating, so two concurrent
-- callers racing to transition the same lead serialize correctly: the
-- second caller sees the first caller's committed status, not the
-- pre-transition status, which is exactly the bug row-level locking exists
-- to prevent (e.g. two "call finished" webhooks both trying to move the
-- same lead from qualified -> under_contract).

ALTER TABLE leads
  ADD COLUMN status TEXT NOT NULL DEFAULT 'new'
    CHECK (status IN (
      'new', 'contacted', 'qualified', 'nurturing', 'objection',
      're_engaged', 'offer_made', 'negotiating', 'under_contract',
      'pending_close', 'closed_won', 'closed_lost', 'disqualified'
    ));

-- Note: 13 labels above (closed_won/closed_lost are two terminal
-- outcomes of one "closed" stage) — the README's "12-state lifecycle"
-- refers to the 12 non-terminal-split stages; see lead_status_transitions
-- for the full reachability graph.

CREATE INDEX idx_leads_tenant_status
  ON leads(tenant_id, status)
  WHERE deleted_at IS NULL;

CREATE TABLE lead_status_transitions (
  from_status TEXT NOT NULL,
  to_status TEXT NOT NULL,
  PRIMARY KEY (from_status, to_status)
);

INSERT INTO lead_status_transitions (from_status, to_status) VALUES
  ('new', 'contacted'),
  ('new', 'disqualified'),
  ('contacted', 'qualified'),
  ('contacted', 'nurturing'),
  ('contacted', 'disqualified'),
  ('qualified', 'offer_made'),
  ('qualified', 'objection'),
  ('qualified', 'nurturing'),
  ('qualified', 'disqualified'),
  ('nurturing', 'contacted'),
  ('nurturing', 're_engaged'),
  ('nurturing', 'disqualified'),
  ('objection', 're_engaged'),
  ('objection', 'disqualified'),
  ('re_engaged', 'qualified'),
  ('re_engaged', 'disqualified'),
  ('offer_made', 'negotiating'),
  ('offer_made', 'under_contract'),
  ('offer_made', 'objection'),
  ('negotiating', 'under_contract'),
  ('negotiating', 'closed_lost'),
  ('under_contract', 'pending_close'),
  ('under_contract', 'closed_lost'),
  ('pending_close', 'closed_won'),
  ('pending_close', 'closed_lost');

CREATE OR REPLACE FUNCTION fn_transition_lead(
  p_lead_id UUID,
  p_to_status TEXT,
  p_actor_user_id UUID DEFAULT NULL,
  p_reason TEXT DEFAULT NULL
) RETURNS leads
LANGUAGE plpgsql AS $$
DECLARE
  v_lead leads%ROWTYPE;
  v_from_status TEXT;
BEGIN
  -- Row lock first — every concurrent caller for this lead_id blocks here
  -- until the transaction that holds the lock commits or rolls back.
  -- This is what makes the read-then-validate-then-write sequence atomic
  -- across concurrent callers instead of racy.
  SELECT * INTO v_lead
  FROM leads
  WHERE id = p_lead_id AND deleted_at IS NULL
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'lead % not found or deleted', p_lead_id
      USING ERRCODE = 'no_data_found';
  END IF;

  v_from_status := v_lead.status;

  IF v_from_status = p_to_status THEN
    RAISE EXCEPTION 'lead % already in status %', p_lead_id, p_to_status
      USING ERRCODE = 'invalid_parameter_value';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM lead_status_transitions
    WHERE from_status = v_from_status AND to_status = p_to_status
  ) THEN
    RAISE EXCEPTION 'illegal transition % -> % for lead %',
      v_from_status, p_to_status, p_lead_id
      USING ERRCODE = 'invalid_parameter_value';
  END IF;

  UPDATE leads
  SET status = p_to_status, updated_at = NOW()
  WHERE id = p_lead_id
  RETURNING * INTO v_lead;

  INSERT INTO events (tenant_id, entity_type, entity_id, event_type, payload)
  VALUES (
    v_lead.tenant_id, 'lead', p_lead_id, 'status_transition',
    jsonb_build_object(
      'from_status', v_from_status,
      'to_status', p_to_status,
      'actor_user_id', p_actor_user_id,
      'reason', p_reason
    )
  );

  INSERT INTO audit_log (tenant_id, user_id, action, entity_type, entity_id, details)
  VALUES (
    v_lead.tenant_id, p_actor_user_id, 'lead.status_transition', 'lead', p_lead_id,
    jsonb_build_object('from_status', v_from_status, 'to_status', p_to_status, 'reason', p_reason)
  );

  RETURN v_lead;
END;
$$;
