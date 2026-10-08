-- Production RLS hardening for village operational tables.
-- Access is restricted to the authenticated user's active organization + territory context.
-- Hard delete remains intentionally unavailable; the application uses soft delete/archive.

DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'assets','budgets','documents','letters','officials','programs','services'
  ] LOOP
    EXECUTE format('DROP POLICY IF EXISTS village_org_access ON village.%I', t);

    EXECUTE format(
      'CREATE POLICY village_scope_select ON village.%I
       FOR SELECT TO authenticated
       USING (
         organization_id = (SELECT organization_id FROM public.my_context() LIMIT 1)
         AND territory_id = (SELECT territory_id FROM public.my_context() LIMIT 1)
       )',
      t
    );

    EXECUTE format(
      'CREATE POLICY village_scope_insert ON village.%I
       FOR INSERT TO authenticated
       WITH CHECK (
         organization_id = (SELECT organization_id FROM public.my_context() LIMIT 1)
         AND territory_id = (SELECT territory_id FROM public.my_context() LIMIT 1)
       )',
      t
    );

    EXECUTE format(
      'CREATE POLICY village_scope_update ON village.%I
       FOR UPDATE TO authenticated
       USING (
         organization_id = (SELECT organization_id FROM public.my_context() LIMIT 1)
         AND territory_id = (SELECT territory_id FROM public.my_context() LIMIT 1)
       )
       WITH CHECK (
         organization_id = (SELECT organization_id FROM public.my_context() LIMIT 1)
         AND territory_id = (SELECT territory_id FROM public.my_context() LIMIT 1)
       )',
      t
    );
  END LOOP;

  DROP POLICY IF EXISTS village_org_access ON village.audit_log;
  DROP POLICY IF EXISTS audit_log_select ON village.audit_log;

  CREATE POLICY audit_log_select ON village.audit_log
    FOR SELECT TO authenticated
    USING (
      organization_id = (SELECT organization_id FROM public.my_context() LIMIT 1)
      AND territory_id = (SELECT territory_id FROM public.my_context() LIMIT 1)
    );
END $$;

GRANT SELECT, INSERT, UPDATE
  ON village.assets, village.budgets, village.documents, village.letters,
     village.officials, village.programs, village.services
  TO authenticated;

GRANT SELECT ON village.audit_log TO authenticated;
