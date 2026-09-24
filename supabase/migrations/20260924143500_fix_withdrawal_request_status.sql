-- Fix withdrawal request creation to use a valid state.
-- The withdrawal_requests status constraint does not allow 'submitted'.
-- Keep requests in pending_security until the downstream security/queue step advances them.

create or replace function public.request_creator_withdrawal(
  p_amount_minor bigint,
  p_method_id uuid,
  p_idempotency_key text
) returns public.withdrawal_requests
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_creator uuid;
  v_wallet public.creator_wallets;
  v_req public.withdrawal_requests;
begin
  v_creator := public.current_profile_id();
  if v_creator is null then raise exception 'unauthorized'; end if;
  if p_amount_minor <= 0 then raise exception 'invalid_amount'; end if;
  if length(trim(coalesce(p_idempotency_key,''))) < 16 then
    raise exception 'invalid_idempotency_key';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where creator_id = v_creator
    and idempotency_key = p_idempotency_key
  limit 1;
  if v_req.id is not null then return v_req; end if;

  select * into v_wallet
  from public.creator_wallets
  where creator_id = v_creator
  for update;

  if v_wallet.creator_id is null then raise exception 'wallet_not_found'; end if;
  if p_amount_minor > v_wallet.available_balance_minor then
    raise exception 'insufficient_balance';
  end if;

  if not exists (
    select 1
    from public.withdrawal_methods
    where id = p_method_id
      and creator_id = v_creator
      and verified = true
  ) then
    raise exception 'invalid_withdrawal_method';
  end if;

  update public.creator_wallets
  set available_balance_minor = available_balance_minor - p_amount_minor,
      updated_at = now()
  where creator_id = v_creator;

  insert into public.withdrawal_requests(
    creator_id, method_id, amount_minor, currency_code,
    status, idempotency_key, requested_at
  )
  values (
    v_creator, p_method_id, p_amount_minor, v_wallet.currency_code,
    'pending_security', p_idempotency_key, now()
  )
  returning * into v_req;

  return v_req;
exception when unique_violation then
  select * into v_req
  from public.withdrawal_requests
  where creator_id = v_creator
    and idempotency_key = p_idempotency_key
  limit 1;
  if v_req.id is not null then return v_req; end if;
  raise;
end;
$function$;

create or replace function public.request_creator_withdrawal_internal(
  p_creator_id uuid,
  p_amount_minor bigint,
  p_method_id uuid,
  p_idempotency_key text
) returns public.withdrawal_requests
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_wallet public.creator_wallets;
  v_req public.withdrawal_requests;
begin
  if p_creator_id is null then raise exception 'unauthorized'; end if;
  if p_amount_minor <= 0 then raise exception 'invalid_amount'; end if;
  if length(trim(coalesce(p_idempotency_key,''))) < 16 then
    raise exception 'invalid_idempotency_key';
  end if;

  select * into v_req
  from public.withdrawal_requests
  where creator_id = p_creator_id
    and idempotency_key = p_idempotency_key
  limit 1;
  if v_req.id is not null then return v_req; end if;

  select * into v_wallet
  from public.creator_wallets
  where creator_id = p_creator_id
  for update;

  if v_wallet.creator_id is null then raise exception 'wallet_not_found'; end if;
  if p_amount_minor > v_wallet.available_balance_minor then
    raise exception 'insufficient_balance';
  end if;

  if not exists (
    select 1
    from public.withdrawal_methods
    where id = p_method_id
      and creator_id = p_creator_id
      and verified = true
  ) then
    raise exception 'invalid_withdrawal_method';
  end if;

  update public.creator_wallets
  set available_balance_minor = available_balance_minor - p_amount_minor,
      updated_at = now()
  where creator_id = p_creator_id;

  insert into public.withdrawal_requests(
    creator_id, method_id, amount_minor, currency_code,
    status, idempotency_key, requested_at
  )
  values (
    p_creator_id, p_method_id, p_amount_minor, v_wallet.currency_code,
    'pending_security', p_idempotency_key, now()
  )
  returning * into v_req;

  return v_req;
exception when unique_violation then
  select * into v_req
  from public.withdrawal_requests
  where creator_id = p_creator_id
    and idempotency_key = p_idempotency_key
  limit 1;
  if v_req.id is not null then return v_req; end if;
  raise;
end;
$function$;

revoke execute on function public.request_creator_withdrawal(bigint, uuid, text) from public, anon, authenticated;
revoke execute on function public.request_creator_withdrawal_internal(uuid, bigint, uuid, text) from public, anon, authenticated;
grant execute on function public.request_creator_withdrawal(bigint, uuid, text) to service_role;
grant execute on function public.request_creator_withdrawal_internal(uuid, bigint, uuid, text) to service_role;
