# STILL Database Migrations

## Migration Structure

All migrations follow a consistent naming pattern:
```
YYYYMMDD_NNNNNN_description.sql
```

Where:
- `YYYYMMDD` - Date (20250101 for all current migrations)
- `NNNNNN` - Sequential number (000001, 000002, etc.)
- `description` - Brief description in snake_case

## Migration Order and Dependencies

| Order | Migration | Purpose | Dependencies |
|-------|-----------|---------|--------------|
| 1 | `20250101_000001_create_profiles.sql` | Base user profiles table | auth.users |
| 2 | `20250101_000002_create_posts_and_social_tables.sql` | Posts, likes, follows | profiles |
| 3 | `20250101_000003_add_media_dimensions.sql` | Media width/height | posts |
| 4 | `20250101_000004_add_updated_at_to_posts.sql` | Updated timestamp | posts |
| 5 | `20250101_000005_create_messaging_tables.sql` | Messaging system | profiles |
| 6 | `20250101_000006_fix_get_user_conversations_function.sql` | Messaging fixes | conversations, messages |
| 7 | `20250101_000007_add_group_chat_functionality.sql` | Group chat support | conversations, messages |
| 8 | `20250101_000008_create_notifications_table.sql` | Notifications | profiles, posts |
| 9 | `20250101_000009_add_notifications_unique_constraint.sql` | Notification constraints | notifications |
| 10 | `20250101_000010_security_improvements.sql` | Security & RLS updates | multiple tables |
| 11 | `20250101_000011_add_status_to_follows.sql` | Follow requests | follows |
| 12 | `20250101_000012_update_posts_rls.sql` | Posts RLS policies | posts |
| 13 | `20250101_000013_add_public_key_to_profiles.sql` | E2E encryption | profiles |

## Key Tables

### Core Tables
- `profiles` - User profile information
- `posts` - User posts (photos/videos)
- `follows` - Follow relationships
- `likes` - Post likes

### Messaging
- `conversations` - Chat conversations
- `conversation_participants` - Chat members
- `messages` - Chat messages

### Supporting
- `notifications` - User notifications
- `security_audit_log` - Security events
- `rate_limits` - API rate limiting

## Running Migrations

To apply migrations to your Supabase project:

```bash
# Apply all pending migrations
supabase db push

# Reset database and reapply all migrations
supabase db reset

# Check migration status
supabase migration list
```

## Security Notes

All tables have Row Level Security (RLS) enabled with appropriate policies. Never disable RLS or weaken security constraints.