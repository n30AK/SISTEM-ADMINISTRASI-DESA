# Deployment — Sistem Administrasi Desa

## Runtime
- PHP 8.1+ (container uses PHP 8.3)
- Apache with rewrite support
- PDO MySQL
- External OpenSID-compatible MySQL database

## Required environment
DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS

The application is intentionally read-first. It must not receive a service-role Supabase secret or direct browser credentials for RT/RW CONNECT.

## Health check
GET /health.php returns HTTP 200 when the application runtime is healthy. Database connectivity is reported as ok or not_configured without exposing database errors.

## Production gate
Do not promote the application as a fully operational village system until an actual OpenSID database is connected and the complete OpenSID schema has been validated against the adapter. The dashboard may run without it, but operational data will not be available.
