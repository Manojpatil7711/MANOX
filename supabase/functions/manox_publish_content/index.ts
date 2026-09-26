import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return new Response(JSON.stringify({error:"method_not_allowed"}), {status:405,headers:{"content-type":"application/json"}});
  const auth=req.headers.get("Authorization");
  if (!auth) return new Response(JSON.stringify({error:"missing_authorization"}),{status:401,headers:{"content-type":"application/json"}});
  const url=Deno.env.get("SUPABASE_URL")!, anon=Deno.env.get("SUPABASE_ANON_KEY")!, service=Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const userClient=createClient(url,anon,{global:{headers:{Authorization:auth}}});
  const {data:{user},error:userError}=await userClient.auth.getUser();
  if(userError||!user) return new Response(JSON.stringify({error:"unauthorized"}),{status:401,headers:{"content-type":"application/json"}});
  const body=await req.json().catch(()=>null), contentId=body?.content_id;
  if(typeof contentId!=="string"||!contentId) return new Response(JSON.stringify({error:"content_id_required"}),{status:400,headers:{"content-type":"application/json"}});
  const admin=createClient(url,service,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data,error}=await admin.rpc("publish_content_secure_as_user",{p_content_id:contentId,p_actor_user_id:user.id});
  if(error) return new Response(JSON.stringify({error:error.message}),{status:400,headers:{"content-type":"application/json"}});
  return new Response(JSON.stringify({published:data===true}),{status:200,headers:{"content-type":"application/json"}});
});