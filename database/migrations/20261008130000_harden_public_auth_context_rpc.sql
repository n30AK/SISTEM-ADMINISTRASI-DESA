-- Security hardening: auth context RPC must never be callable anonymously.
revoke all on function public.my_context() from public;
revoke execute on function public.my_context() from anon;
grant execute on function public.my_context() to authenticated;

notify pgrst, 'reload schema';
