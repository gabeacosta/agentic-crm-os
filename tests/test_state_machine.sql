-- test_state_machine.sql
-- Functional tests for fn_transition_lead(). Run via: make test
-- Uses RAISE EXCEPTION to fail loudly; a clean run prints only NOTICEs.
-- Requires migrations 001-013 already applied to the target database.

DO $$
DECLARE
  v_lead_id UUID;
  v_tenant_id UUID;
  v_result leads%ROWTYPE;
  v_caught BOOLEAN;
BEGIN
  -- Isolated fixture data so this test doesn't depend on 012_seed_data.sql
  INSERT INTO tenants (id, name, slug, plan)
  VALUES (gen_random_uuid(), 'Test Tenant', 'test-' || gen_random_uuid(), 'growth_engine')
  RETURNING id INTO v_tenant_id;

  INSERT INTO leads (id, tenant_id, phone, dedup_hash)
  VALUES (gen_random_uuid(), v_tenant_id, '+15555550199', gen_random_uuid()::text)
  RETURNING id INTO v_lead_id;

  -- 1. Fresh lead defaults to 'new'
  SELECT * INTO v_result FROM leads WHERE id = v_lead_id;
  IF v_result.status <> 'new' THEN
    RAISE EXCEPTION 'TEST FAILED: expected default status new, got %', v_result.status;
  END IF;
  RAISE NOTICE 'PASS: fresh lead defaults to new';

  -- 2. Legal transition succeeds and is reflected on the row
  v_result := fn_transition_lead(v_lead_id, 'contacted');
  IF v_result.status <> 'contacted' THEN
    RAISE EXCEPTION 'TEST FAILED: expected contacted, got %', v_result.status;
  END IF;
  RAISE NOTICE 'PASS: new -> contacted succeeds';

  -- 3. Illegal transition raises and leaves status unchanged
  v_caught := FALSE;
  BEGIN
    PERFORM fn_transition_lead(v_lead_id, 'closed_won');
  EXCEPTION WHEN OTHERS THEN
    v_caught := TRUE;
  END;
  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST FAILED: contacted -> closed_won should have raised';
  END IF;
  SELECT * INTO v_result FROM leads WHERE id = v_lead_id;
  IF v_result.status <> 'contacted' THEN
    RAISE EXCEPTION 'TEST FAILED: status changed despite rejected transition, now %', v_result.status;
  END IF;
  RAISE NOTICE 'PASS: illegal transition rejected, status unchanged';

  -- 4. Re-transitioning to the same status is rejected (no-op guard)
  v_caught := FALSE;
  BEGIN
    PERFORM fn_transition_lead(v_lead_id, 'contacted');
  EXCEPTION WHEN OTHERS THEN
    v_caught := TRUE;
  END;
  IF NOT v_caught THEN
    RAISE EXCEPTION 'TEST FAILED: transitioning to current status should raise';
  END IF;
  RAISE NOTICE 'PASS: same-status transition rejected';

  -- 5. Transition writes an events row and an audit_log row
  PERFORM fn_transition_lead(v_lead_id, 'qualified', NULL, 'test note');
  IF NOT EXISTS (
    SELECT 1 FROM events
    WHERE entity_id = v_lead_id AND event_type = 'status_transition'
      AND payload->>'to_status' = 'qualified'
  ) THEN
    RAISE EXCEPTION 'TEST FAILED: expected events row for qualified transition';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM audit_log
    WHERE entity_id = v_lead_id AND action = 'lead.status_transition'
      AND details->>'to_status' = 'qualified'
  ) THEN
    RAISE EXCEPTION 'TEST FAILED: expected audit_log row for qualified transition';
  END IF;
  RAISE NOTICE 'PASS: transition writes events + audit_log rows';

  -- Cleanup fixture (cascades not defined; delete children first)
  DELETE FROM audit_log WHERE entity_id = v_lead_id;
  DELETE FROM events WHERE entity_id = v_lead_id;
  DELETE FROM leads WHERE id = v_lead_id;
  DELETE FROM tenants WHERE id = v_tenant_id;

  RAISE NOTICE 'ALL TESTS PASSED';
END $$;
