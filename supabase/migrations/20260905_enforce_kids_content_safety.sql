create or replace function public.enforce_kids_content_safety()
returns trigger
language plpgsql
as $$
begin
  if new.audience_category = 'kids_15_plus' then
    new.visibility := 'public';
    new.allow_downloads := false;
  end if;
  return new;
end;
$$;

drop trigger if exists contents_enforce_kids_content_safety on public.contents;

create trigger contents_enforce_kids_content_safety
before insert or update of audience_category, visibility, allow_downloads on public.contents
for each row
execute function public.enforce_kids_content_safety();
