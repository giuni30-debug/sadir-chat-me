create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  display_name text,
  avatar_url text,
  created_at timestamptz default now()
);
create table if not exists public.conversations (id uuid primary key default gen_random_uuid(), created_at timestamptz default now());
create table if not exists public.conversation_members (conversation_id uuid references public.conversations(id) on delete cascade, user_id uuid references public.profiles(id) on delete cascade, joined_at timestamptz default now(), primary key(conversation_id,user_id));
create table if not exists public.messages (
 id uuid primary key default gen_random_uuid(), conversation_id uuid references public.conversations(id) on delete cascade not null,
 sender_id uuid references public.profiles(id) on delete cascade not null, body text, kind text not null default 'text', media_url text,
 created_at timestamptz default now()
);
create table if not exists public.device_tokens (token text primary key, user_id uuid references public.profiles(id) on delete cascade not null, platform text not null default 'android', updated_at timestamptz default now());
create table if not exists public.calls (id uuid primary key default gen_random_uuid(), conversation_id uuid references public.conversations(id) on delete cascade not null, caller_id uuid references public.profiles(id) not null, callee_id uuid references public.profiles(id) not null, kind text default 'audio', status text default 'ringing', created_at timestamptz default now(), answered_at timestamptz, ended_at timestamptz);

alter table public.profiles enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.device_tokens enable row level security;
alter table public.calls enable row level security;

create policy "profile authenticated read" on public.profiles for select to authenticated using (true);
create policy "profile self update" on public.profiles for update to authenticated using (auth.uid()=id);
create policy "members read own" on public.conversation_members for select to authenticated using (user_id=auth.uid() or exists(select 1 from public.conversation_members m where m.conversation_id=conversation_members.conversation_id and m.user_id=auth.uid()));
create policy "messages member read" on public.messages for select to authenticated using (exists(select 1 from public.conversation_members m where m.conversation_id=messages.conversation_id and m.user_id=auth.uid()));
create policy "messages member send" on public.messages for insert to authenticated with check (sender_id=auth.uid() and exists(select 1 from public.conversation_members m where m.conversation_id=messages.conversation_id and m.user_id=auth.uid()));
create policy "tokens self" on public.device_tokens for all to authenticated using(user_id=auth.uid()) with check(user_id=auth.uid());
create policy "calls participants" on public.calls for select to authenticated using(caller_id=auth.uid() or callee_id=auth.uid());
create policy "calls create" on public.calls for insert to authenticated with check(caller_id=auth.uid());

alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.calls;
