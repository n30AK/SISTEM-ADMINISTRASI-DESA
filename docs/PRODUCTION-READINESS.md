# Production Readiness

## Required before deployment

1. Provision a PHP 8.3 + Apache container runtime.
2. Configure the OpenSID-compatible MySQL connection using deployment secrets.
3. Run the health endpoint and require:
   - status = ok
   - runtime present
   - opensid_database = ok
4. Run schema discovery against the real OpenSID database:
   `php bin/opensid-inspect.php`
5. Review the resulting schema before enabling write/synchronization workflows.
6. Configure the RT/RW CONNECT Supabase integration outside the browser; never expose a service-role key.
7. Confirm HTTPS, backups, logging and access controls at the hosting layer.

## Deployment gate

The application is deployable as a container, but it is not considered production-live until a real OpenSID database connection has returned `opensid_database=ok` and the schema has been inspected.

No destructive migration is required for the OpenSID data layer.
