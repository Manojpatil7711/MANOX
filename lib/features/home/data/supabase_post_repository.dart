import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../services/supabase_service.dart';

class ManoxPost {
  final String id;
  final String creatorName;
  final String handle;
  final String text;
  final int likes;
  final int comments;
  final String? imageUrl;
  final String? avatarUrl;
  final String contentType;
  final bool likedByMe;
  final bool savedByMe;
  final String? ownerUserId;
  const ManoxPost({required this.id,required this.creatorName,required this.handle,required this.text,required this.likes,required this.comments,required this.likedByMe,required this.savedByMe,this.imageUrl,this.avatarUrl,this.contentType='post',this.ownerUserId});
}
class ManoxComment { final String id; final String userName; final String body; final DateTime createdAt; const ManoxComment({required this.id,required this.userName,required this.body,required this.createdAt}); }
class ManoxSavedItem { final String contentId; final String folderName; final DateTime createdAt; const ManoxSavedItem({required this.contentId,required this.folderName,required this.createdAt}); }

class SupabasePostRepository {
  SupabaseClient get _client { final client=SupabaseService.client; if(client==null) throw StateError('MANOX backend is not configured.'); return client; }
  String get _userId { final id=_client.auth.currentUser?.id; if(id==null) throw StateError('Please sign in first.'); return id; }
  Future<bool> isOwner(String contentId) async { final row=await _client.from('contents').select('owner_user_id').eq('id',contentId).maybeSingle(); return row != null && row['owner_user_id']==_userId; }
  Future<bool> isSaved(String contentId) async { final row=await _client.from('saved_contents').select('content_id').eq('profile_id',_userId).eq('content_id',contentId).maybeSingle(); return row != null; }
  Future<void> saveContent(String contentId,{String folderName='Watch later'}) async { final folder=folderName.trim(); if(!{'Watch later','Important','Helpful'}.contains(folder)) throw ArgumentError('Invalid save folder.'); await _client.from('saved_contents').upsert({'profile_id':_userId,'content_id':contentId,'folder_name':folder},onConflict:'profile_id,content_id'); }
  Future<void> unsaveContent(String contentId) async { await _client.from('saved_contents').delete().eq('profile_id',_userId).eq('content_id',contentId); }
  Future<void> moveSavedContent(String contentId,String folderName) async { if(!{'Watch later','Important','Helpful'}.contains(folderName)) throw ArgumentError('Invalid save folder.'); await _client.from('saved_contents').update({'folder_name':folderName}).eq('profile_id',_userId).eq('content_id',contentId); }
  Future<List<ManoxSavedItem>> fetchSavedItems({String? folderName}) async { var q=_client.from('saved_contents').select('content_id,folder_name,created_at').eq('profile_id',_userId); if(folderName!=null) q=q.eq('folder_name',folderName); final rows=await q.order('created_at',ascending:false); return (rows as List).map((r)=>ManoxSavedItem(contentId:r['content_id'] as String,folderName:r['folder_name'] as String,createdAt:DateTime.parse(r['created_at'] as String))).toList(); }
  Future<List<String>> fetchSaveFolders() async => ['Watch later','Important','Helpful'];
  Future<List<ManoxPost>> _mapRows(List rows) async { final currentUser=_userId; final saved=await fetchSavedItems(); final savedIds=saved.map((e)=>e.contentId).toSet(); return rows.map((row){ final likes=List<Map<String,dynamic>>.from(row['content_likes']??const[]); final comments=List<Map<String,dynamic>>.from(row['content_comments']??const[]); final profile=row['profiles'] as Map<String,dynamic>?; final mediaUrls=List<dynamic>.from(row['media_urls']??const[]); final rawUsername=(profile?['username'] as String?)??'creator'; return ManoxPost(id:row['id'] as String,creatorName:(profile?['display_name'] as String?)??'MANOX Creator',handle:'@${rawUsername.replaceFirst(RegExp(r'^@+'), '')}',text:(row['description'] as String?)??'',likes:likes.length,comments:comments.length,likedByMe:likes.any((like)=>like['user_id']==currentUser),savedByMe:savedIds.contains(row['id']),contentType:(row['content_type'] as String?)??'post',imageUrl:mediaUrls.isNotEmpty?mediaUrls.first as String:row['media_url'] as String?,avatarUrl:profile?['avatar_url'] as String?,ownerUserId:row['owner_user_id'] as String?); }).toList(); }
  String get _contentSelect => 'id, owner_user_id, description, media_url, media_urls, content_type, created_at, profiles!contents_owner_user_id_fkey(username, display_name, avatar_url), content_likes(user_id), content_comments(id)';
  Future<List<ManoxPost>> fetchFeed() async { final rows=await _client.from('contents').select(_contentSelect).eq('status','published').eq('visibility','public').order('published_at',ascending:false,nullsFirst:false).order('created_at',ascending:false).limit(50); return _mapRows(rows as List); }
  Future<List<ManoxPost>> fetchBeats() async { final rows=await _client.from('contents').select(_contentSelect).eq('status','published').eq('visibility','public').eq('content_type','video').order('published_at',ascending:false,nullsFirst:false).order('created_at',ascending:false).limit(50); return _mapRows(rows as List); }
  Future<List<ManoxPost>> fetchMyPosts() async => fetchPostsByOwner(_userId);
  Future<List<ManoxPost>> fetchPostsByOwner(String ownerUserId) async { final rows=await _client.from('contents').select(_contentSelect).eq('owner_user_id',ownerUserId).eq('status','published').eq('visibility','public').order('created_at',ascending:false); return _mapRows(rows as List); }
  Future<String?> uploadImage(Uint8List bytes,String extension,String? mimeType) async => _uploadMedia(bytes,extension,mimeType);
  Future<String?> uploadVideo(Uint8List bytes,String extension,String? mimeType) async { final ext=extension.toLowerCase().replaceAll('.',''); const allowed={'mp4','mov','m4v','webm','3gp'}; if(!allowed.contains(ext)) throw ArgumentError('Unsupported video format. Use MP4, MOV, M4V, WEBM or 3GP.'); return _uploadMedia(bytes,ext,mimeType ?? 'video/$ext'); }
  Future<String?> _uploadMedia(Uint8List bytes,String extension,String? mimeType) async { if(bytes.isEmpty) throw StateError('Selected media is empty.'); final path='$_userId/${DateTime.now().microsecondsSinceEpoch}.$extension'; await _client.storage.from('manox-media').uploadBinary(path,bytes,fileOptions:FileOptions(contentType:mimeType,upsert:false,cacheControl:'3600')); return path; }
  Future<ManoxPost> createPost({required String text,String? imagePath,String mediaType='post'}) async { final type=mediaType.trim().isEmpty?'post':mediaType.trim(); final row=await _client.from('contents').insert({'owner_user_id':_userId,'content_type':type,'description':text,'media_url':imagePath,'media_urls':imagePath==null?<String>[]:<String>[imagePath],'status':'published','visibility':'public','published_at':DateTime.now().toIso8601String()}).select('id').single(); final id=row['id'] as String; final post=await _client.from('contents').select(_contentSelect).eq('id',id).single(); final profile=post['profiles'] as Map<String,dynamic>?; final urls=post['media_urls'] as List?; final username=(profile?['username'] as String?)??'you'; return ManoxPost(id:id,creatorName:(profile?['display_name'] as String?)??'You',handle:'@${username.replaceFirst(RegExp(r'^@+'), '')}',text:(post['description'] as String?)??'',likes:0,comments:0,likedByMe:false,savedByMe:false,contentType:(post['content_type'] as String?)??type,imageUrl:urls?.isNotEmpty==true?urls!.first as String:post['media_url'] as String?,avatarUrl:profile?['avatar_url'] as String?,ownerUserId:post['owner_user_id'] as String?); }
  Future<void> updatePost(String contentId,String text) async { await _client.from('contents').update({'description':text.trim(),'updated_at':DateTime.now().toIso8601String()}).eq('id',contentId).eq('owner_user_id',_userId); }
  Future<void> deletePost(String contentId) async { await _client.from('contents').delete().eq('id',contentId).eq('owner_user_id',_userId); }
  Future<bool> toggleLike(String contentId,bool currentlyLiked) async { if(currentlyLiked){await _client.from('content_likes').delete().eq('content_id',contentId).eq('user_id',_userId);return false;} await _client.from('content_likes').insert({'content_id':contentId,'user_id':_userId});return true; }
  Future<List<ManoxComment>> fetchComments(String contentId) async { final rows=await _client.from('content_comments').select('id, body, created_at, profiles!content_comments_user_id_fkey(display_name)').eq('content_id',contentId).eq('status','visible').order('created_at'); return(rows as List).map((row){final profile=row['profiles'] as Map<String,dynamic>?;return ManoxComment(id:row['id'] as String,userName:(profile?['display_name'] as String?)??'MANOX User',body:row['body'] as String,createdAt:DateTime.parse(row['created_at'] as String));}).toList(); }
  Future<void> addComment(String contentId,String body) async { final trimmed=body.trim();if(trimmed.isEmpty)return;await _client.from('content_comments').insert({'content_id':contentId,'user_id':_userId,'body':trimmed,'status':'visible','created_at':DateTime.now().toIso8601String(),'updated_at':DateTime.now().toIso8601String()}); }
  Future<void> recordShare(String contentId,{String target='system'}) async => _client.from('content_shares').insert({'content_id':contentId,'profile_id':_userId,'share_target':target});
  Future<String> createShareUrl(String contentId) async => 'https://manox.app/content/$contentId';
  Future<String?> signedMediaUrl(String path) async { if(path.startsWith('http://')||path.startsWith('https://'))return path; return _client.storage.from('manox-media').createSignedUrl(path,60*60*24*30); }
}
