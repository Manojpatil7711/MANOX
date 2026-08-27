alter table public.profiles
  add column if not exists other_link text;

alter table public.profiles
  drop constraint if exists profiles_other_link_http_check;

alter table public.profiles
  add constraint profiles_other_link_http_check
  check (other_link is null or other_link ~* '^https?://[^[:space:]]+$');
