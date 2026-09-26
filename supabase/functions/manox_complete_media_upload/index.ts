import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{"content-type":"application/json"}});
Deno.serve(async(req:Request)=>{
 if(req.method!=="POST")return json({error:"method_not_allowed"},405);
 const auth=req.headers.get("authorization"); if(!auth)return json({error:"unauthorized"},401);
 const userClient=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_ANON_KEY")!,{global:{headers:{Authorization:auth}}});
 const {data:{user},error:ue}=await userClient.auth.getUser(); if(ue||!user)return json({error:"unauthorized"},401);
 const body=await req.json().catch(()=>({})); const assetId=String(body.asset_id??""); if(!assetId)return json({error:"asset_id_required"},400);
 const admin=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
 const {data:asset,error:ae}=await admin.from("media_assets").select("id,content_id,asset_type,storage_bucket,storage_path,status,owner_user_id").eq("id",assetId).single();
 if(ae||!asset)return json({error:"asset_not_found"},404);
 if(asset.owner_user_id!==user.id||!asset.storage_path.startsWith(user.id+"/"))return json({error:"forbidden"},403);
 if(asset.status==="processing"||asset.status==="ready")return json({ok:true,status:asset.status,idempotent:true});
 if(asset.status!=="pending")return json({error:"invalid_asset_state"},409);
 const fileName=asset.storage_path.split("/").pop()!; const {data:list,error:le}=await admin.storage.from(asset.storage_bucket).list(user.id,{limit:100,search:fileName});
 if(le)return json({error:"storage_check_failed"},502); if(!(list??[]).some((x:any)=>x.name===fileName))return json({error:"upload_not_found"},409);
 const jobs=asset.asset_type==="video"?["transcode","thumbnail","moderation_scan","copyright_scan","package"]:["moderation_scan","copyright_scan"];
 const {data:existing}=await admin.from("media_processing_jobs").select("job_type,status").eq("content_id",asset.content_id).in("job_type",jobs); const existingTypes=new Set((existing??[]).map((j:any)=>j.job_type)); const missing=jobs.filter(j=>!existingTypes.has(j));
 if(missing.length){const {error:je}=await admin.from("media_processing_jobs").insert(missing.map(job_type=>({content_id:asset.content_id,job_type,status:"queued",attempts:0})));if(je)return json({error:"processing_queue_failed"},500);}
 const {error:up}=await admin.from("media_assets").update({status:"processing",updated_at:new Date().toISOString()}).eq("id",asset.id).eq("status","pending"); if(up)return json({error:"asset_update_failed"},500);
 return json({ok:true,status:"processing",jobs:missing});
});