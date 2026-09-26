CREATE OR REPLACE FUNCTION public.protect_safety_verification_fields()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF current_user <> 'service_role' THEN
    IF NEW.safety_role IS DISTINCT FROM OLD.safety_role OR NEW.safety_role_verified IS DISTINCT FROM OLD.safety_role_verified THEN
      RAISE EXCEPTION 'safety verification fields are managed by trusted services';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
REVOKE EXECUTE ON FUNCTION public.protect_safety_verification_fields() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.protect_safety_verification_fields() TO service_role;
DROP TRIGGER IF EXISTS protect_safety_verification_fields_trg ON public.profiles;
CREATE TRIGGER protect_safety_verification_fields_trg
BEFORE UPDATE ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.protect_safety_verification_fields();
