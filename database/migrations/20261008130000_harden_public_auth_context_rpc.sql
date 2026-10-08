-- Security hardening: auth context RPC must never be callable anonymously.
revoke all on function public.my_context() from public;
grant execute on function public.my_context() to authenticated;

notify pgrst, 'reload schema';
