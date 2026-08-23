# Search feature

Purpose
- Provide search across users, content, and tags.

Planned responsibilities
- Search UI, result ranking, autocomplete, filtering.

Expected screens/components
- SearchScreen
- ResultList / Filters / Autocomplete

Expected repository/service dependencies
- Search backend or repository wrappers (may call Supabase full-text or external search)
- ProfileRepository / PostRepository

Security considerations
- Ensure search results respect RLS and visibility; filter out private/unlisted content unless user is authorized.
